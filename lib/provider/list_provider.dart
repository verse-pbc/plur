import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/util/string_code_generator.dart';

import '../consts/router_path.dart';
import '../data/custom_emoji.dart';
import '../generated/l10n.dart';
import '../data/join_group_parameters.dart';
import '../util/router_util.dart';
import '../provider/relay_provider.dart';

/// Standard list provider.
/// These list usually publish by user himself and the provider will hold the newest one.
class ListProvider extends ChangeNotifier {
  // holder, hold the events.
  // key - "kind:pubkey", value - event
  final Map<String, Event> _holder = {};

  void load(
    String pubkey,
    List<int> kinds, {
    Nostr? targetNostr,
    bool initQuery = false,
  }) {
    targetNostr ??= nostr;

    List<Map<String, dynamic>> filters = [];
    for (var kind in kinds) {
      Filter filter = Filter();
      filter.kinds = [kind];
      filter.authors = [pubkey];
      filter.limit = 1;

      filters.add(filter.toJson());
    }

    if (initQuery) {
      targetNostr!.addInitQuery(filters, onEvent);
    } else {
      targetNostr!.query(filters, onEvent);
    }
  }

  void onEvent(Event event) {
    var key = "${event.kind}:${event.pubkey}";

    var oldEvent = _holder[key];
    if (oldEvent == null) {
      _holder[key] = event;
      _handleExtraAndNotify(event);
    } else {
      if (event.createdAt > oldEvent.createdAt) {
        _holder[key] = event;
        _handleExtraAndNotify(event);
      }
    }
  }

  void _handleExtraAndNotify(Event event) async {
    if (event.kind == EventKind.EMOJIS_LIST) {
      // This is a emoji list, try to handle some listSet
      for (var tag in event.tags) {
        if (tag is List && tag.length > 1) {
          var k = tag[0];
          var v = tag[1];
          if (k == "a") {
            listSetProvider.getByAId(v);
          }
        }
      }
    } else if (event.kind == EventKind.BOOKMARKS_LIST) {
      // due to bookmarks info will use many times, so it should parse when it was receive.
      var bm = await parseBookmarks();
      if (bm != null) {
        _bookmarks = bm;
      }
    } else if (event.kind == EventKind.GROUP_LIST) {
      _groupIdentifiers.clear();

      for (var tag in event.tags) {
        if (tag is List && tag.length > 2) {
          var k = tag[0];
          var groupId = tag[1];
          var host = tag[2];
          if (k == "group") {
            var gi = GroupIdentifier(host, groupId);
            _groupIdentifiers.add(gi);
          }
        }
      }
      _queryAllGroupsOnDefaultRelay();
    }
    notifyListeners();
  }

  Event? getEmojiEvent() {
    return _holder[emojiKey];
  }

  String get emojiKey {
    return "${EventKind.EMOJIS_LIST}:${nostr!.publicKey}";
  }

  List<MapEntry<String, List<CustomEmoji>>> emojis(
      S localization, Event? emojiEvent) {
    List<MapEntry<String, List<CustomEmoji>>> result = [];

    List<CustomEmoji> list = [];

    if (emojiEvent != null) {
      for (var tag in emojiEvent.tags) {
        if (tag is List && tag.isNotEmpty) {
          var tagKey = tag[0];
          if (tagKey == "emoji" && tag.length > 2) {
            // emoji config config inside.
            var k = tag[1];
            var v = tag[2];
            list.add(CustomEmoji(name: k, filepath: v));
          } else if (tagKey == "a" && tag.length > 1) {
            // emoji config by other listSet
            var aIdStr = tag[1];
            var listSetEvent = listSetProvider.getByAId(aIdStr);
            if (listSetEvent != null) {
              // find the listSet
              var aId = AId.fromString(aIdStr);
              String title = "unknow";
              if (aId != null) {
                title = aId.title;
              }

              List<CustomEmoji> subList = [];
              for (var tag in listSetEvent.tags) {
                if (tag is List && tag.length > 2) {
                  var tagKey = tag[0];
                  var k = tag[1];
                  var v = tag[2];
                  if (tagKey == "emoji") {
                    subList.add(CustomEmoji(name: k, filepath: v));
                  }
                }
              }

              result.add(MapEntry(title, subList));
            }
          }
        }
      }
    }
    result.insert(0, MapEntry(localization.Custom, list));

    return result;
  }

  void addCustomEmoji(CustomEmoji emoji) async {
    var cancelFunc = BotToast.showLoading();

    try {
      List<dynamic> tags = [];

      var emojiEvent = getEmojiEvent();
      if (emojiEvent != null) {
        tags.addAll(emojiEvent.tags);
      }
      tags.add(["emoji", emoji.name, emoji.filepath]);
      var changedEvent =
          Event(nostr!.publicKey, EventKind.EMOJIS_LIST, tags, "");
      var result = await nostr!.sendEvent(changedEvent);

      if (result != null) {
        _holder[emojiKey] = result;
        notifyListeners();
      }
    } finally {
      cancelFunc.call();
    }
  }

  Bookmarks _bookmarks = Bookmarks();

  Bookmarks getBookmarks() {
    return _bookmarks;
  }

  String get bookmarksKey {
    return "${EventKind.BOOKMARKS_LIST}:${nostr!.publicKey}";
  }

  Event? getBookmarksEvent() {
    return _holder[bookmarksKey];
  }

  Future<Bookmarks?> parseBookmarks() async {
    var bookmarks = Bookmarks();
    var bookmarksEvent = getBookmarksEvent();
    if (bookmarksEvent == null) {
      return bookmarks;
    }

    var content = bookmarksEvent.content;
    if (StringUtil.isNotBlank(content)) {
      var plainContent =
          await nostr!.nostrSigner.decrypt(nostr!.publicKey, content);
      if (StringUtil.isBlank(plainContent)) {
        return null;
      }

      var jsonObj = jsonDecode(plainContent!);
      if (jsonObj is List) {
        List<BookmarkItem> privateItems = [];
        for (var jsonObjItem in jsonObj) {
          if (jsonObjItem is List && jsonObjItem.length > 1) {
            var key = jsonObjItem[0];
            var value = jsonObjItem[1];
            if (key is String && value is String) {
              privateItems.add(BookmarkItem(key: key, value: value));
            }
          }
        }

        bookmarks.privateItems = privateItems;
      }
    }

    List<BookmarkItem> publicItems = [];
    for (var jsonObjItem in bookmarksEvent.tags) {
      if (jsonObjItem is List && jsonObjItem.length > 1) {
        var key = jsonObjItem[0];
        var value = jsonObjItem[1];
        if (key is String && value is String) {
          publicItems.add(BookmarkItem(key: key, value: value));
        }
      }
    }
    bookmarks.publicItems = publicItems;

    return bookmarks;
  }

  void addPrivateBookmark(BookmarkItem bookmarkItem) {
    var bookmarks = getBookmarks();
    bookmarks.privateItems.add(bookmarkItem);
    saveBookmarks(bookmarks);
  }

  void addPublicBookmark(BookmarkItem bookmarkItem) {
    var bookmarks = getBookmarks();
    bookmarks.publicItems.add(bookmarkItem);
    saveBookmarks(bookmarks);
  }

  void removePrivateBookmark(String value) {
    var bookmarks = getBookmarks();
    bookmarks.privateItems.removeWhere((items) {
      return items.value == value;
    });
    saveBookmarks(bookmarks);
  }

  void removePublicBookmark(String value) {
    var bookmarks = getBookmarks();
    bookmarks.publicItems.removeWhere((items) {
      return items.value == value;
    });
    saveBookmarks(bookmarks);
  }

  void saveBookmarks(Bookmarks bookmarks) async {
    String? content = "";
    if (bookmarks.privateItems.isNotEmpty) {
      List<List> list = [];
      for (var item in bookmarks.privateItems) {
        list.add(item.toJson());
      }

      var jsonText = jsonEncode(list);
      content = await nostr!.nostrSigner.encrypt(nostr!.publicKey, jsonText);
      if (StringUtil.isBlank(content)) {
        BotToast.showText(text: "Bookmark encrypt error");
        return;
      }
    }

    List tags = [];
    for (var item in bookmarks.publicItems) {
      tags.add(item.toJson());
    }

    var event =
        Event(nostr!.publicKey, EventKind.BOOKMARKS_LIST, tags, content!);
    var resultEvent = await nostr!.sendEvent(event);
    if (resultEvent != null) {
      _holder[bookmarksKey] = resultEvent;
    }

    notifyListeners();
  }

  bool checkPublicBookmark(BookmarkItem item) {
    for (var bi in _bookmarks.publicItems) {
      if (bi.value == item.value) {
        return true;
      }
    }

    return false;
  }

  bool checkPrivateBookmark(BookmarkItem item) {
    for (var bi in _bookmarks.privateItems) {
      if (bi.value == item.value) {
        return true;
      }
    }

    return false;
  }

  final Set<GroupIdentifier> _groupIdentifiers = {};

  // Getter to maintain compatibility with existing code.
  List<GroupIdentifier> get groupIdentifiers => _groupIdentifiers.toList();

  void joinGroup(JoinGroupParameters request, {BuildContext? context}) async {
    // Check if already a member first
    if (isGroupMember(request)) {
      BotToast.showText(text: "You're already a member of this group.");
      if (context != null) {
        RouterUtil.router(context, RouterPath.GROUP_DETAIL,
            GroupIdentifier(request.host, request.groupId));
      }
      return;
    }

    joinGroups([request], context: context);
  }

  bool isGroupMember(JoinGroupParameters request) {
    final groupId = GroupIdentifier(request.host, request.groupId);
    return _groupIdentifiers
        .any((gi) => gi.groupId == groupId.groupId && gi.host == groupId.host);
  }

  void joinGroups(List<JoinGroupParameters> requests,
      {BuildContext? context}) async {
    if (requests.isEmpty) return;

    final cancelFunc = BotToast.showLoading();

    List<(GroupIdentifier, bool)> results =
        await _processJoinRequests(requests);
    final successfullyJoinedGroupIds = results
        .where((result) => result.$2)
        .map((result) => result.$1)
        .toList();

    _handleJoinResults(successfullyJoinedGroupIds, context, requests);
    cancelFunc.call();
  }

  Future<List<(GroupIdentifier, bool)>> _processJoinRequests(
      List<JoinGroupParameters> requests) async {
    List<Future<(GroupIdentifier, bool)>> joinTasks =
        requests.map((request) => _processJoinRequest(request)).toList();
    return await Future.wait(joinTasks);
  }

  Future<(GroupIdentifier, bool)> _processJoinRequest(
      JoinGroupParameters request) async {
    final joinEvent = _createJoinEvent(request);
    final groupId = GroupIdentifier(request.host, request.groupId);

    final joinResult = await nostr!.sendEvent(joinEvent,
        tempRelays: [request.host], targetRelays: [request.host]);

    if (joinResult == null) {
      return (groupId, false);
    }

    // Add a delay to allow the relay to process the join event
    await Future.delayed(const Duration(seconds: 2));

    bool membershipConfirmed = await _verifyMembership(request);
    return (groupId, membershipConfirmed);
  }

  Event _createJoinEvent(JoinGroupParameters request) {
    final List<List<String>> eventTags = [
      ["h", request.groupId]
    ];

    if (request.code != null) {
      eventTags.add(["code", request.code!]);
    }

    return Event(
      nostr!.publicKey,
      EventKind.GROUP_JOIN,
      eventTags,
      "",
    );
  }

  Future<bool> _verifyMembership(JoinGroupParameters request) async {
    final filter = Filter(kinds: [EventKind.GROUP_MEMBERS], limit: 1);
    final filterMap = filter.toJson();
    filterMap["#d"] = [request.groupId];

    final completer = Completer<bool>();

    nostr!.query(
      [filterMap],
      (Event event) => _checkTagsForMembership(event, completer),
      tempRelays: [request.host],
      relayTypes: RelayType.ONLY_TEMP,
      sendAfterAuth: true,
    );

    try {
      return await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () => false,
      );
    } catch (e) {
      return false;
    }
  }

  void _checkTagsForMembership(Event event, Completer<bool> completer) {
    if (event.kind == EventKind.GROUP_MEMBERS) {
      for (var tag in event.tags) {
        if (tag is List && tag.length > 1) {
          if (tag[0] == "p" && tag[1] == nostr!.publicKey) {
            if (!completer.isCompleted) {
              completer.complete(true);
            }
            return;
          }
        }
      }
      if (!completer.isCompleted) {
        completer.complete(false);
      }
    }
  }

  void _handleJoinResults(List<GroupIdentifier> successfullyJoinedGroupIds,
      BuildContext? context, List<JoinGroupParameters> requests) {
    if (successfullyJoinedGroupIds.isNotEmpty) {
      _groupIdentifiers.addAll(successfullyJoinedGroupIds);
      _updateGroups();

      if (context != null && successfullyJoinedGroupIds.isNotEmpty) {
        RouterUtil.router(
            context, RouterPath.GROUP_DETAIL, successfullyJoinedGroupIds[0]);
      }
    } else {
      BotToast.showText(
          text:
              "Sorry, something went wrong and you weren't added to the group.");
      log("Failed to join group: $requests");
    }
  }

  void leaveGroup(GroupIdentifier gi) async {
    if (!_groupIdentifiers.contains(gi)) return;

    final cancelFunc = BotToast.showLoading();

    final event = Event(
      nostr!.publicKey,
      EventKind.GROUP_LEAVE,
      [
        ["h", gi.groupId]
      ],
      "",
    );

    await nostr!
        .sendEvent(event, tempRelays: [gi.host], targetRelays: [gi.host]);

    _groupIdentifiers.removeWhere((groupIdentifier) =>
        gi.groupId == groupIdentifier.groupId &&
        gi.host == groupIdentifier.host);

    _updateGroups();

    cancelFunc.call();
  }

  void _updateGroups() async {
    final tags = _groupIdentifiers.map((groupId) => groupId.toJson()).toList();

    final updateGroupListEvent = Event(
      nostr!.publicKey,
      EventKind.GROUP_LIST,
      tags,
      "",
    );
    await nostr!.sendEvent(updateGroupListEvent);

    notifyListeners();
  }

  Future<(String?, GroupIdentifier?)> createGroupAndGenerateInvite(
      String groupName) async {
    final cancelFunc = BotToast.showLoading();
    const host = RelayProvider.defaultGroupsRelayAddress;

    // Generate a random string for the group ID
    final groupId = StringCodeGenerator.generateGroupId();

    // Create the event for creating a group.
    // We only support private closed group for now.
    final createGroupEvent = Event(
      nostr!.publicKey,
      EventKind.GROUP_CREATE_GROUP,
      [
        ["h", groupId]
      ],
      "",
    );

    final resultEvent = await nostr!
        .sendEvent(createGroupEvent, tempRelays: [host], targetRelays: [host]);

    String? inviteLink;
    GroupIdentifier? newGroup;
    // Event was successfully sent
    if (resultEvent != null) {
      newGroup = GroupIdentifier(host, groupId);

      //  Add the group to the list
      _groupIdentifiers.add(newGroup);
      _editMetadata(newGroup, groupName);
      _updateGroups();

      // Generate an invite code
      final inviteCode = StringCodeGenerator.generateInviteCode();
      inviteLink = createInviteLink(newGroup, inviteCode);
    }

    cancelFunc.call();
    return (inviteLink, newGroup);
  }

  void _editMetadata(GroupIdentifier group, String groupName) {
    GroupMetadata groupMetadata = GroupMetadata(
      group.groupId,
      0,
      name: groupName,
    );
    groupProvider.updateMetadata(group, groupMetadata);
  }

  String createInviteLink(GroupIdentifier group, String inviteCode,
      {List<String>? roles}) {
    final tags = [
      ["h", group.groupId],
      ["code", inviteCode],
    ];

    // Add roles if provided, default to "member"
    if (roles != null && roles.isNotEmpty) {
      tags.add(["roles", ...roles]);
    } else {
      tags.add(["roles", "member"]);
    }

    final inviteEvent = Event(
      nostr!.publicKey,
      EventKind.GROUP_CREATE_INVITE,
      tags,
      "", // Empty content as per example
    );

    nostr!.sendEvent(inviteEvent,
        tempRelays: [group.host], targetRelays: [group.host]);

    // Return the formatted invite link
    return 'plur://join-community?group-id=${group.groupId}&code=$inviteCode';
  }

  void clear() {
    _holder.clear();
    _bookmarks = Bookmarks();
    _groupIdentifiers.clear();
    notifyListeners();
  }

  /// Add a group identifier to the list and fetch its metadata
  void _addGroupIdentifier(GroupIdentifier groupId) {
    if (!_groupIdentifiers.contains(groupId)) {
      _groupIdentifiers.add(groupId);
      // Fetch metadata for just this new group
      _queryGroupMetadata(groupId);
    }
  }

  /// Fetch metadata for a specific group
  void _queryGroupMetadata(GroupIdentifier groupId) async {
    // Create filter for group metadata
    final filter = Filter(kinds: [EventKind.GROUP_METADATA], limit: 1);
    final filterMap = filter.toJson();
    filterMap["#d"] = [groupId.groupId];

    nostr!.query(
      [filterMap],
      (Event event) {
        if (event.kind == EventKind.GROUP_METADATA) {
          groupProvider.onEvent(groupId, event);
        }
      },
      tempRelays: [groupId.host],
      relayTypes: RelayType.ONLY_TEMP,
      sendAfterAuth: true,
    );
  }

  /// Fetch all groups that the user is a member or admin of
  void _queryAllGroupsOnDefaultRelay() async {
    final filters = [
      {
        // Get groups where user is a member
        "kinds": [EventKind.GROUP_MEMBERS],
        "#p": [nostr!.publicKey],
      },
      {
        // Get groups where user is an admin
        "kinds": [EventKind.GROUP_ADMINS],
        "#p": [nostr!.publicKey],
      }
    ];

    nostr!.query(
      filters,
      (Event event) {
        _extractGroupIdentifiersFromTags(event, tagPrefix: "d").forEach(_addGroupIdentifier);
      },
      tempRelays: [RelayProvider.defaultGroupsRelayAddress],
      relayTypes: RelayType.ONLY_TEMP,
      sendAfterAuth: true,
    );
  }

  /// Handles group deletion events by removing the group from _groupIdentifiers
  /// and updating the UI
  void handleGroupDeleteEvent(Event event) {
    _extractGroupIdentifiersFromTags(event, tagPrefix: "h")
        .forEach(_groupIdentifiers.remove);
    _updateGroups();
    notifyListeners();
  }

  /// Handles membership/admin events by adding new groups to _groupIdentifiers
  void handleAdminMembershipEvent(Event event) {
    if (event.kind == EventKind.GROUP_MEMBERS ||
        event.kind == EventKind.GROUP_ADMINS) {
      _extractGroupIdentifiersFromTags(event, tagPrefix: "d")
          .forEach(_addGroupIdentifier);
      notifyListeners();
    }
  }

  /// Handles metadata update events by updating the group metadata in GroupProvider
  void handleEditMetadataEvent(Event event) {
    if (event.kind == EventKind.GROUP_EDIT_METADATA) {
      _extractGroupIdentifiersFromTags(event, tagPrefix: "h")
          .forEach((groupId) => groupProvider.onEvent(groupId, event));
      notifyListeners();
    }
  }
}

/// Extracts group identifiers from event tags with specified prefix ("h" or "d").
/// Optionally accepts a custom relay address, defaults to the default groups relay.
List<GroupIdentifier> _extractGroupIdentifiersFromTags(
  Event event, {
  required String tagPrefix,
  String? relayAddress,
}) {
  relayAddress ??= RelayProvider.defaultGroupsRelayAddress;

  return event.tags
      .where((tag) => tag is List && tag.length > 1 && tag[0] == tagPrefix)
      .map((tag) => GroupIdentifier(relayAddress!, tag[1]))
      .toList();
}
