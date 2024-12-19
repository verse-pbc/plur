import 'dart:convert';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:nostr_sdk/aid.dart';
import 'package:nostr_sdk/event.dart';
import 'package:nostr_sdk/event_kind.dart';
import 'package:nostr_sdk/filter.dart';
import 'package:nostr_sdk/nip29/group_identifier.dart';
import 'package:nostr_sdk/nip51/bookmarks.dart';
import 'package:nostr_sdk/nostr.dart';
import 'package:nostr_sdk/utils/string_util.dart';
import 'package:nostrmo/main.dart';

import '../consts/router_path.dart';
import '../data/custom_emoji.dart';
import '../generated/l10n.dart';
import '../data/join_group_parameters.dart';
import '../util/router_util.dart';
import '../provider/relay_provider.dart';
import 'dart:math';

/// Standard list provider.
/// These list usually publish by user himself and the provider will hold the newest one.
class ListProvider extends ChangeNotifier {
  // holder, hold the events.
  // key - “kind:pubkey”, value - event
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

  final List<GroupIdentifier> _groupIdentifiers = [];

  get groupIdentifiers => _groupIdentifiers;

  void joinGroup(JoinGroupParameters request, {BuildContext? context}) async {
    joinGroups([request], context: context);
  }

  void joinGroups(List<JoinGroupParameters> requests,
      {BuildContext? context}) async {
    if (requests.isEmpty) return;

    final cancelFunc = BotToast.showLoading();
    List<Future<(GroupIdentifier, Event?)>> sendTasks =
        requests.map((request) async {
      final List<List<String>> eventTags = [
        ["h", request.groupId]
      ];

      if (request.code != null) {
        eventTags.add(["code", request.code!]);
      }

      final joinEvent = Event(
        nostr!.publicKey,
        EventKind.GROUP_JOIN,
        eventTags,
        "",
      );

      final groupId = GroupIdentifier(request.host, request.groupId);
      return (
        groupId,
        await nostr!.sendEvent(joinEvent,
            tempRelays: [request.host], targetRelays: [request.host])
      );
    }).toList();

    List<(GroupIdentifier, Event?)> results = await Future.wait(sendTasks);
    final successfullyJoinedGroupIds = results
        .where((result) => result.$2 != null)
        .map((result) => result.$1)
        .toList();

    if (successfullyJoinedGroupIds.isNotEmpty) {
      _groupIdentifiers.addAll(successfullyJoinedGroupIds);
      _updateGroups();

      // Navigate to the first successfully joined group if context is provided
      if (context != null && successfullyJoinedGroupIds.isNotEmpty) {
        RouterUtil.router(
            context, RouterPath.GROUP_DETAIL, successfullyJoinedGroupIds[0]);
      }
    }

    cancelFunc.call();
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
    final groupId =
        _generateRandomString(12, 'abcdefghijklmnopqrstuvwxyz0123456789');

    // Create the event for creating a group.
    // We only support private closed group for now.
    final createGroupEvent = Event(
      nostr!.publicKey,
      EventKind.GROUP_CREATE_GROUP,
      [
        ["h", groupId],
        ["name", groupName]
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
      _updateGroups();

      // Generate an invite code
      final inviteCode =
          _generateRandomString(8, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789');
      _createInvite(newGroup, inviteCode);

      // Construct the invite link
      inviteLink = 'plur://join-community?group-id=$groupId.g=$inviteCode';
    }

    cancelFunc.call();
    return (inviteLink, newGroup);
  }

  void _createInvite(GroupIdentifier group, String inviteCode) {
    final inviteEvent = Event(
      nostr!.publicKey,
      EventKind.GROUP_CREATE_INVITE,
      [
        ["h", group.groupId],
        ["invite", inviteCode]
      ],
      "",
    );

    nostr!.sendEvent(inviteEvent,
        tempRelays: [group.host], targetRelays: [group.host]);
  }

  // Generate random string for invite code and group id.
  String _generateRandomString(int length, String chars) {
    final random = Random();
    return List.generate(length, (index) => chars[random.nextInt(chars.length)])
        .join();
  }

  void clear() {
    _holder.clear();
    _bookmarks = Bookmarks();
    _groupIdentifiers.clear();
  }
}
