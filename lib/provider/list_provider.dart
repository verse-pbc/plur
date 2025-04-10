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
import '../data/public_group_info.dart';
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
  
  // Bookmark methods
  // NIP-51 defines 30003 as private bookmarks list
  static const int privateBookmarkListKind = 30003;
  
  // NIP-51 defines 10003 as public bookmarks list
  static const int publicBookmarkListKind = 10003;
  
  bool privateBookmarkContains(String eventId) {
    // Get private bookmarks and check if event is included
    final privateBookmarksKey = "$privateBookmarkListKind:${nostr?.publicKey}";
    final privateBookmarks = _holder[privateBookmarksKey];
    if (privateBookmarks == null) return false;
    
    // Check if the event ID is in the tags
    for (var tag in privateBookmarks.tags) {
      if (tag is List && tag.isNotEmpty && tag[0] == "e" && tag.length > 1 && tag[1] == eventId) {
        return true;
      }
    }
    return false;
  }
  
  bool publicBookmarkContains(String eventId) {
    // Get public bookmarks and check if event is included
    final publicBookmarksKey = "$publicBookmarkListKind:${nostr?.publicKey}";
    final publicBookmarks = _holder[publicBookmarksKey];
    if (publicBookmarks == null) return false;
    
    // Check if the event ID is in the tags
    for (var tag in publicBookmarks.tags) {
      if (tag is List && tag.isNotEmpty && tag[0] == "e" && tag.length > 1 && tag[1] == eventId) {
        return true;
      }
    }
    return false;
  }

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
    if (event.kind == EventKind.emojisList) {
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
    } else if (event.kind == EventKind.bookmarksList) {
      // due to bookmarks info will use many times, so it should parse when it was receive.
      var bm = await parseBookmarks();
      if (bm != null) {
        _bookmarks = bm;
      }
    } else if (event.kind == EventKind.groupList) {
      _groupIdentifiers.clear();
      for (var tag in event.tags) {
        if (tag is List && tag.length > 2) {
          var k = tag[0];
          var groupId = tag[1];
          var host = tag[2];
          if (k == "group") {
            var gi = GroupIdentifier(host, groupId);
            _addGroupIdentifier(gi);
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
    return "${EventKind.emojisList}:${nostr!.publicKey}";
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
          Event(nostr!.publicKey, EventKind.emojisList, tags, "");
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
    return "${EventKind.bookmarksList}:${nostr!.publicKey}";
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
        Event(nostr!.publicKey, EventKind.bookmarksList, tags, content!);
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
        RouterUtil.router(context, RouterPath.groupDetail,
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
    if (context != null && context.mounted) {
      _handleJoinResults(successfullyJoinedGroupIds, context, requests);
    }
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
      EventKind.groupJoin,
      eventTags,
      "",
    );
  }

  Future<bool> _verifyMembership(JoinGroupParameters request) async {
    final filter = Filter(kinds: [EventKind.groupMembers], limit: 1);
    final filterMap = filter.toJson();
    filterMap["#d"] = [request.groupId];

    final completer = Completer<bool>();

    nostr!.query(
      [filterMap],
      (Event event) => _checkTagsForMembership(event, completer),
      tempRelays: [request.host],
      relayTypes: RelayType.onlyTemp,
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
    if (event.kind == EventKind.groupMembers) {
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

      // Show success message instead of immediate navigation
      BotToast.showText(
        text: "Successfully joined community. You can view it in your communities list.",
        duration: const Duration(seconds: 3),
      );
      
      // Navigate back to the communities list instead of directly to the group detail
      if (context != null && context.mounted) {
        // Delayed navigation to ensure communities list is updated
        Future.delayed(const Duration(milliseconds: 300), () {
          try {
            // Navigate to communities list
            RouterUtil.router(context, RouterPath.groupList, null);
          } catch (e) {
            log("Error navigating after join: $e");
          }
        });
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
      EventKind.groupLeave,
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
      EventKind.groupList,
      tags,
      "",
    );
    await nostr!.sendEvent(updateGroupListEvent);

    notifyListeners();
  }

  Future<(String?, GroupIdentifier?)> createGroupAndGenerateInvite(
      String groupName) async {
    print("createGroupAndGenerateInvite starting for group: $groupName");
    final cancelFunc = BotToast.showLoading();
    const host = RelayProvider.defaultGroupsRelayAddress;
    print("Using host: $host");

    // Generate a random string for the group ID
    final groupId = StringCodeGenerator.generateGroupId();
    print("Generated group ID: $groupId");

    // Create the event for creating a group.
    // We only support private closed group for now.
    final createGroupEvent = Event(
      nostr!.publicKey,
      EventKind.groupCreateGroup,
      [
        ["h", groupId]
      ],
      "",
    );
    print("Created group creation event: ${createGroupEvent.id}");

    print("Sending event to relay...");
    final resultEvent = await nostr!
        .sendEvent(createGroupEvent, tempRelays: [host], targetRelays: [host]);
    print("Result from group creation: ${resultEvent?.id ?? 'null'}");

    String? inviteLink;
    GroupIdentifier? newGroup;
    // Event was successfully sent
    if (resultEvent != null) {
      newGroup = GroupIdentifier(host, groupId);
      print("New group identifier created: $newGroup");

      //  Add the group to the list
      print("Before adding to _groupIdentifiers. Current count: ${_groupIdentifiers.length}");
      _groupIdentifiers.add(newGroup);
      print("After adding to _groupIdentifiers. New count: ${_groupIdentifiers.length}");
      
      print("Creating group metadata for name: $groupName");
      _editMetadata(newGroup, groupName);
      
      print("Updating groups list event");
      _updateGroups();

      // Generate an invite code
      final inviteCode = StringCodeGenerator.generateInviteCode();
      print("Generated invite code: $inviteCode");
      inviteLink = createInviteLink(newGroup, inviteCode);
      print("Created invite link: $inviteLink");
      
      // Double check that the group was added
      if (_groupIdentifiers.contains(newGroup)) {
        print("Confirmed group is in the list");
      } else {
        print("ERROR: Group was not added to the list!");
      }
      
      // Manually verify the group is in groupIdentifiers
      print("Group identifiers list content verification:");
      for (var group in _groupIdentifiers) {
        print(" - $group");
      }
    } else {
      print("ERROR: Group creation failed - resultEvent is null");
    }

    // Force a notify listeners to ensure UI updates
    notifyListeners();
    
    cancelFunc.call();
    return (inviteLink, newGroup);
  }

  void _editMetadata(GroupIdentifier group, String groupName) {
    print("_editMetadata called for group: $group with name: $groupName");
    
    // Create metadata with name and default values
    GroupMetadata groupMetadata = GroupMetadata(
      group.groupId,
      0,
      name: groupName,
      // Add a picture if none was provided
      picture: "https://placehold.co/400x400/4267B2/FFF?text=${groupName.substring(0, 1).toUpperCase()}",
      // Add a default about text
      about: "A new group called $groupName",
      // Default to private, closed group
      public: false,
      open: false,
    );
    
    print("Created metadata: ${groupMetadata.toString()}");
    print("Calling groupProvider.updateMetadata");
    
    try {
      groupProvider.updateMetadata(group, groupMetadata);
      print("Successfully called updateMetadata");
    } catch (e) {
      print("Error in updateMetadata: $e");
    }
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
      EventKind.groupCreateInvite,
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
    if (_groupIdentifiers.contains(groupId)) {
      return;
    }
    _groupIdentifiers.add(groupId);
    _queryGroupMetadata(groupId);
  }

  /// Fetch metadata for a specific group
  void _queryGroupMetadata(GroupIdentifier groupId) async {
    // Create filter for group metadata
    final filter = Filter(kinds: [EventKind.groupMetadata], limit: 1);
    final filterMap = filter.toJson();
    filterMap["#d"] = [groupId.groupId];

    nostr!.query(
      [filterMap],
      (Event event) {
        if (event.kind == EventKind.groupMetadata) {
          groupProvider.onEvent(groupId, event);
        }
      },
      tempRelays: [groupId.host],
      targetRelays: [groupId.host],
      relayTypes: RelayType.onlyTemp,
      sendAfterAuth: true,
    );
  }

  /// Fetch all groups that the user is a member or admin of
  void _queryAllGroupsOnDefaultRelay() async {
    final filters = [
      {
        // Get groups where user is a member
        "kinds": [EventKind.groupMembers],
        "#p": [nostr!.publicKey],
      },
      {
        // Get groups where user is an admin
        "kinds": [EventKind.groupAdmins],
        "#p": [nostr!.publicKey],
      }
    ];

    nostr!.query(
      filters,
      (Event event) {
        final ids = _extractGroupIdentifiersFromTags(event, tagPrefix: "d");
        ids.forEach(_addGroupIdentifier);
        notifyListeners();
      },
      tempRelays: [RelayProvider.defaultGroupsRelayAddress],
      targetRelays: [RelayProvider.defaultGroupsRelayAddress],
      relayTypes: RelayType.onlyTemp,
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
    if (event.kind == EventKind.groupMembers ||
        event.kind == EventKind.groupAdmins) {
      _extractGroupIdentifiersFromTags(event, tagPrefix: "d")
          .forEach(_addGroupIdentifier);
      notifyListeners();
    }
  }

  /// Handles metadata update events by updating the group metadata in GroupProvider
  void handleEditMetadataEvent(Event event) {
    if (event.kind == EventKind.groupEditMetadata) {
      _extractGroupIdentifiersFromTags(event, tagPrefix: "h")
          .forEach((groupId) {
            groupProvider.onEvent(groupId, event);
            _queryGroupMetadata(groupId);
          });
      notifyListeners();
    }
  }
  
  // Function to query public groups from multiple relays
  Future<List<PublicGroupInfo>> queryPublicGroups(List<String> relays) async {
    log("🔍 SIMPLIFIED APPROACH: Starting to query for ALL group metadata from relays: $relays");
    log("This approach treats all metadata events as public groups to maximize discovery");
    
    List<PublicGroupInfo> publicGroups = [];
    final completer = Completer<List<PublicGroupInfo>>();
    
    // For debugging
    int editStatusEvents = 0;
    int metadataEvents = 0;
    int memberEvents = 0;
    int noteEvents = 0;
    int publicGroundsFound = 0;
    
    // We're now adding groups directly in the metadata event handler
    
    // Let's keep it as simple as possible - just fetch ALL groups metadata
    // and filter them client-side
    final filters = [
      {
        "kinds": [EventKind.groupMetadata],
        "limit": 500,
      }
    ];
    
    int pendingRelays = relays.length;
    
    // Get the data from each relay
    for (final relay in relays) {
      nostr!.query(
        filters,
        (Event event) {
          // Keep track of event types for debugging
          if (event.kind == EventKind.groupEditStatus) {
            editStatusEvents++;
            log("Received GROUP_EDIT_STATUS event: ${event.id.substring(0, 10)}...");
            
            // Find the 'h' tag for group ID
            for (var tag in event.tags) {
              if (tag is List && tag.length > 1 && tag[0] == 'h') {
                final groupId = tag[1];
                final groupKey = '$relay:$groupId';
                
                // Check if this is a public group
                bool isPublic = false;
                for (var subTag in event.tags) {
                  if (subTag is List && subTag.isNotEmpty && subTag[0] == 'public') {
                    isPublic = true;
                    break;
                  }
                }
                
                log("GROUP_EDIT_STATUS for group $groupId - public: $isPublic");
                
                if (isPublic) {
                  // Fetch metadata for this group
                  groupProvider.query(GroupIdentifier(relay, groupId));
                }
              }
            }
          } else if (event.kind == EventKind.groupMetadata) {
            metadataEvents++;
            
            // Extract groupId from the 'd' tag
            for (var tag in event.tags) {
              if (tag is List && tag.length > 1 && tag[0] == 'd') {
                final groupId = tag[1];
                final groupKey = '$relay:$groupId';
                
                // Extract metadata from tags
                String? groupName;
                String? picture;
                String? about;
                
                for (var subTag in event.tags) {
                  if (subTag is List && subTag.length > 1) {
                    if (subTag[0] == 'name') {
                      groupName = subTag[1];
                    } else if (subTag[0] == 'picture') {
                      picture = subTag[1];
                    } else if (subTag[0] == 'about') {
                      about = subTag[1];
                    }
                  }
                }
                
                // Treat all groups as public until we have a consistent standard
                log("GROUP_METADATA for group $groupId - name: ${groupName ?? 'unnamed'}");
                
                // Add this group directly to the results
                final parts = groupKey.split(':');
                if (parts.length == 2) {
                  final host = parts[0];
                  
                  publicGroups.add(PublicGroupInfo(
                    identifier: GroupIdentifier(host, groupId),
                    name: groupName ?? 'Unnamed Group',
                    about: about,
                    picture: picture,
                    memberCount: 1, // Default member count
                    lastActive: DateTime.now(), // Default to current time
                  ));
                  publicGroundsFound++;
                  log("Added group $groupKey to results");
                }
              }
            }
          } else if (event.kind == EventKind.groupMembers) {
            memberEvents++;
            // We're ignoring member events for now in our simplified approach
          } else if (event.kind == EventKind.groupNote) {
            noteEvents++;
            // We're ignoring note events for now in our simplified approach
          }
        },
        tempRelays: [relay],
        relayTypes: RelayType.onlyTemp,
      );
      
      // Simulate query completion after a delay (since onComplete callback is not available)
      Future.delayed(const Duration(seconds: 3), () {
        pendingRelays--;
        if (pendingRelays <= 0) {
          if (!completer.isCompleted) {
            completer.complete(publicGroups);
          }
        }
      });
    }
    
    // We're not using incomplete data handling anymore since we're 
    // directly adding groups from metadata events
    
    // Set a timeout to ensure we return results even if some relays don't respond
    Future.delayed(const Duration(seconds: 10), () {
      if (!completer.isCompleted) {
        log("🔍 SEARCH COMPLETE: Completing group discovery - Stats: " "Metadata Events: $metadataEvents, " "Public Groups Found: $publicGroundsFound");
        
        if (publicGroundsFound == 0) {
          log("⚠️ NO GROUPS FOUND: This could indicate network issues or that the relays don't host any groups");
        } else {
          log("✅ SUCCESS: Found $publicGroundsFound groups from $metadataEvents metadata events");
        }
        
        completer.complete(publicGroups);
      }
    });
    
    return completer.future;
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
