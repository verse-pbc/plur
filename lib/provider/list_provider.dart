import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/util/string_code_generator.dart';
import 'package:nostrmo/util/group_invite_link_util.dart';

import '../consts/router_path.dart';
import '../data/custom_emoji.dart';
import '../data/public_group_info.dart';
import '../generated/l10n.dart';
import '../data/join_group_parameters.dart';
import '../util/router_util.dart';
import '../provider/relay_provider.dart';
import '../provider/group_feed_provider.dart';

/// Standard list provider.
/// These list usually publish by user himself and the provider will hold the newest one.
class ListProvider extends ChangeNotifier {
  // Reference to the GroupFeedProvider for coordination
  // This will be set by the GroupFeedProvider when it's created
  static GroupFeedProvider? groupFeedProvider;
  // holder, hold the events.
  // key - "kind:pubkey", value - event
  final Map<String, Event> _holder = {};
  
  // Track groups successfully joined for navigation and error recovery
  List<GroupIdentifier> successfullyJoinedGroupIds = [];
  
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
    result.insert(0, MapEntry(localization.custom, list));

    return result;
  }

  void addCustomEmoji(CustomEmoji emoji) async {
    final cancelFunc = _safeShowLoading();

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
      try {
        cancelFunc.call();
      } catch (e) {
        log("AddCustomEmoji WARNING: Failed to cancel loading indicator: $e", name: "ListProvider");
      }
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
        _safeShowToast("Bookmark encrypt error");
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

  // This will help track the join success state for debugging
  bool _joinCompleted = false;
  bool get joinCompleted => _joinCompleted;

  Future<bool> joinGroup(JoinGroupParameters request, {BuildContext? context}) async {
    log("JoinGroup START: GroupId: ${request.groupId}, Host: ${request.host}", name: "ListProvider.joinGroup");
    
    // Create group identifier for consistency
    final groupId = GroupIdentifier(request.host, request.groupId);
    
    // First, check if we're already in the middle of a join process for this group
    if (_joinCompleted) {
      log("JoinGroup INFO: Already processing a join request. Avoiding duplicate join.", name: "ListProvider.joinGroup");
      
      // If the context is provided, navigate to the group
      if (context != null && context.mounted) {
        try {
          // Don't wait - handle immediately
          log("JoinGroup INFO: Navigating to group detail (already joining)", name: "ListProvider.joinGroup");
          _safeShowToast("You're being added to this group...");
          _navigateToGroupDetail(context, groupId);
        } catch (e) {
          log("JoinGroup ERROR: Failed to navigate after skipping duplicate join: $e", name: "ListProvider.joinGroup");
          // Fall back to group list on error
          _navigateToGroupList(context);
        }
      }
      return true;
    }
    
    // Do a thorough check if the user is already a member of this group
    if (isGroupMember(request)) {
      log("JoinGroup INFO: Already a member of group ${request.groupId}", name: "ListProvider.joinGroup");
      
      _safeShowToast("You're already a member of this group.");
      
      // If we already have this group, make sure we have its metadata
      // This is a safeguard in case metadata wasn't properly loaded before
      _queryGroupMetadata(groupId);
      
      // Always notify listeners to ensure UI updates
      notifyListeners();
      
      if (context != null && context.mounted) {
        // Navigate to the group immediately
        try {
          log("JoinGroup INFO: Navigating to group detail (already a member)", name: "ListProvider.joinGroup");
          _navigateToGroupDetail(context, groupId);
        } catch (e) {
          log("JoinGroup ERROR: Failed to navigate to group detail: $e", name: "ListProvider.joinGroup");
          // Fall back to group list on error
          _navigateToGroupList(context);
        }
      }
      return true;
    }

    // Set flag to indicate we're starting a join process
    _joinCompleted = true;
    
    // Pre-emptively add the group 
    _safeShowToast("Joining group ${request.groupId}...");
    
    // Add it immediately to improve UX - we'll remove it if the join fails
    _addGroupIdentifier(groupId);
    try {
      _updateGroups();
      
      // Critical: Notify all listeners immediately to update UI
      notifyListeners();
      
      if (groupFeedProvider != null) {
        // Force GroupFeedProvider to refresh if it exists
        log("JoinGroup INFO: Forcing GroupFeedProvider refresh", name: "ListProvider.joinGroup");
        groupFeedProvider!.refresh();
      }
    } catch (e) {
      log("JoinGroup ERROR: Failed to update groups: $e", name: "ListProvider.joinGroup");
    }

    log("JoinGroup INFO: Not a member, proceeding to join group ${request.groupId} at relay ${request.host}", name: "ListProvider.joinGroup");
    
    bool success = false;
    try {
      success = await joinGroups([request], context: context);
      log("JoinGroup END: joinGroups called for ${request.groupId} with result: $success", name: "ListProvider.joinGroup");
    } catch (e) {
      log("JoinGroup ERROR: Exception during joinGroups: $e", name: "ListProvider.joinGroup");
      
      // Show error toast
      _safeShowToast("Error joining group: $e");
      
      // Make sure we notify listeners even on error
      notifyListeners();
      
      // Navigate despite error to avoid blank screen
      if (context != null && context.mounted) {
        try {
          // Even on error, show either the group detail (if we added it)
          // or fall back to group list
          if (_groupIdentifiers.contains(groupId)) {
            log("JoinGroup INFO: Navigating to group detail despite error", name: "ListProvider.joinGroup");
            _navigateToGroupDetail(context, groupId);
          } else {
            log("JoinGroup INFO: Navigating to group list due to error", name: "ListProvider.joinGroup");
            _navigateToGroupList(context);
          }
        } catch (navError) {
          log("JoinGroup ERROR: Failed to navigate after error: $navError", name: "ListProvider.joinGroup");
        }
      }
    } finally {
      // Reset join completed flag after join process ends, regardless of outcome
      // This allows future join attempts if needed
      _joinCompleted = false;
    }
    
    if (success) {
      _safeShowToast("Successfully joined group!");
      
      // If successful, set newUser flag to false since they now have a community
      if (newUser == true) {
        log("SETTING newUser flag to FALSE after successful join", name: "ListProvider.joinGroup");
        newUser = false;
      }
    } else {
      _safeShowToast("Group join may have failed, but we've added it to your list anyway.");
    }
    
    // Make absolutely sure we've notified listeners
    notifyListeners();
    
    // Navigation should have been handled in joinGroups / _handleJoinResults
    // but let's ensure we don't leave the user stranded
    if (context != null && context.mounted) {
      // Delay navigation to avoid conflicts with _handleJoinResults
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (context.mounted && success) {
          try {
            // Double-check if the group exists in our list
            if (_groupIdentifiers.contains(groupId)) {
              log("JoinGroup INFO: Delayed navigation to group detail", name: "ListProvider.joinGroup");
              _navigateToGroupDetail(context, groupId);
            } else {
              log("JoinGroup INFO: Delayed navigation to group list", name: "ListProvider.joinGroup");
              _navigateToGroupList(context);
            }
          } catch (e) {
            log("JoinGroup ERROR: Failed in delayed navigation: $e", name: "ListProvider.joinGroup");
          }
        }
      });
    }
    
    return success;
  }
  
  // Helper method to navigate to the group detail page
  void _navigateToGroupDetail(BuildContext context, GroupIdentifier groupId) {
    try {
      log("Navigating to group detail for ${groupId.groupId}", name: "ListProvider.navigation");
      RouterUtil.router(context, RouterPath.groupDetail, groupId);
    } catch (e) {
      log("Error navigating to group detail: $e", name: "ListProvider.navigation");
      // Fall back to group list
      _navigateToGroupList(context);
    }
  }
  
  // Helper method to navigate to the group list page
  void _navigateToGroupList(BuildContext context) {
    try {
      log("Navigating to group list", name: "ListProvider.navigation");
      RouterUtil.router(context, RouterPath.groupList, null);
    } catch (e) {
      log("Error navigating to group list: $e", name: "ListProvider.navigation");
      // Last resort - try to pop to root
      try {
        Navigator.of(context).popUntil((route) => route.isFirst);
      } catch (e2) {
        log("Error popping to root: $e2", name: "ListProvider.navigation");
      }
    }
  }

  bool isGroupMember(JoinGroupParameters request) {
    final groupId = GroupIdentifier(request.host, request.groupId);
    
    // Add debug logging to check what's happening
    log("isGroupMember CHECK: Checking if member of group ${request.groupId} at ${request.host}", name: "ListProvider.isGroupMember");
    log("isGroupMember INFO: Current groupIdentifiers count: ${_groupIdentifiers.length}", name: "ListProvider.isGroupMember");
    
    // Log all current group identifiers for debugging
    if (_groupIdentifiers.isNotEmpty) {
      for (var gi in _groupIdentifiers) {
        log("isGroupMember DEBUG: Found group ${gi.groupId} at ${gi.host}", name: "ListProvider.isGroupMember");
      }
    }
    
    // Check for exact or partial match
    bool isMember = _groupIdentifiers.any((gi) => 
      (gi.groupId == groupId.groupId && gi.host == groupId.host) ||  // Exact match
      (gi.groupId == groupId.groupId)  // Match on ID only as fallback
    );
    
    log("isGroupMember RESULT: ${isMember ? 'Is member' : 'Not a member'} of group ${request.groupId}", name: "ListProvider.isGroupMember");
    return isMember;
  }

  Future<bool> joinGroups(List<JoinGroupParameters> requests,
      {BuildContext? context}) async {
    if (requests.isEmpty) return false;
    log("JoinGroups START: Processing ${requests.length} join requests.", name: "ListProvider.joinGroups");

    final cancelFunc = _safeShowLoading();

    log("JoinGroups INFO: Calling _processJoinRequests.", name: "ListProvider.joinGroups");
    List<(GroupIdentifier, bool)> results =
        await _processJoinRequests(requests);
    log("JoinGroups INFO: _processJoinRequests returned ${results.length} results. Successes: ${results.where((r) => r.$2).length}", name: "ListProvider.joinGroups");
    final List<GroupIdentifier> successfullyJoinedGroupIds = results
        .where((result) => result.$2)
        .map((result) => result.$1)
        .toList();
    
    bool success = successfullyJoinedGroupIds.isNotEmpty;
    
    if (context != null && context.mounted) {
      _handleJoinResults(successfullyJoinedGroupIds, context, requests);
    }
    
    try {
      cancelFunc.call();
    } catch (e) {
      log("JoinGroups WARNING: Failed to cancel loading indicator: $e", name: "ListProvider.joinGroups");
    }
    
    log("JoinGroups END: Processed ${requests.length} requests. Final success: $success", name: "ListProvider.joinGroups");
    return success;
  }

  Future<List<(GroupIdentifier, bool)>> _processJoinRequests(
      List<JoinGroupParameters> requests) async {
    log("_processJoinRequests START: Mapping ${requests.length} requests to _processJoinRequest tasks.", name: "ListProvider._processJoinRequests");
    List<Future<(GroupIdentifier, bool)>> joinTasks =
        requests.map((request) => _processJoinRequest(request)).toList();
    final results = await Future.wait(joinTasks);
    log("_processJoinRequests END: Future.wait completed with ${results.length} results.", name: "ListProvider._processJoinRequests");
    return results;
  }

  Future<(GroupIdentifier, bool)> _processJoinRequest(
      JoinGroupParameters request) async {
    log("_processJoinRequest START: GroupId: ${request.groupId}, Host: ${request.host}", name: "ListProvider._processJoinRequest");
    // Create the join event
    final joinEvent = _createJoinEvent(request);
    final groupId = GroupIdentifier(request.host, request.groupId);
    
    log("_processJoinRequest INFO: Join event created for ${request.groupId}. Attempting to send.", name: "ListProvider._processJoinRequest");
    
    // Attempt to send the join event to both the specified relay and the default relay
    // This ensures the event has the best chance of being processed
    final List<String> relaysToTry = [
      request.host,
      'wss://communities.nos.social', // Default relay as fallback
    ];
    
    // Send to all applicable relays
    Event? joinResult;
    bool sentToAnyRelay = false;
    String successfulRelay = "";
    
    for (final relay in relaysToTry) {
      try {
        log("_processJoinRequest INFO: Sending join request to relay: $relay for group ${request.groupId}", name: "ListProvider._processJoinRequest");
        final result = await nostr!.sendEvent(joinEvent,
            tempRelays: [relay], targetRelays: [relay]);
        
        if (result != null) {
          joinResult = result;
          sentToAnyRelay = true;
          successfulRelay = relay;
          log("_processJoinRequest SUCCESS: Join request successfully sent to $relay for group ${request.groupId}. Event ID: ${result.id}", name: "ListProvider._processJoinRequest");
          
          // Force save the group after sending to at least one relay successfully
          _safeShowToast("Adding group to your communities...");
          
          // Add the group immediately to improve user experience
          _addGroupIdentifier(groupId);
          
          // Save the group list event immediately
          try {
            _updateGroups();
            log("_processJoinRequest INFO: Updated groups list after successful event send", name: "ListProvider._processJoinRequest");
          } catch (e) {
            log("_processJoinRequest ERROR: Failed to update groups list: $e", name: "ListProvider._processJoinRequest");
          }
          
          // Break after successfully sending to one relay
          break;
        } else {
          log("_processJoinRequest WARN: Join request to $relay for group ${request.groupId} returned null result.", name: "ListProvider._processJoinRequest");
        }
      } catch (e) {
        log("_processJoinRequest ERROR: Error sending join request to $relay for group ${request.groupId}: $e", name: "ListProvider._processJoinRequest");
      }
    }

    if (!sentToAnyRelay) {
      log("_processJoinRequest WARN: Failed to send join event to any relay for group ${request.groupId}. Returning false.", name: "ListProvider._processJoinRequest");
      
      // Last-ditch effort - still add the group to improve UX
      // The user can always remove it later if needed
      _addGroupIdentifier(groupId);
      _updateGroups();
      _safeShowToast("Added group, but couldn't confirm with relay. Trying again in background.");
      
      return (groupId, false);
    }

    // Add a longer delay to allow the relay to process the join event
    // Some relays might be slower to process membership changes
    log("_processJoinRequest INFO: Join event sent for ${request.groupId}. Waiting ${const Duration(seconds: 3).inSeconds}s for relay to process...", name: "ListProvider._processJoinRequest");
    
    try {
      await Future.delayed(const Duration(seconds: 3));
    } catch (e) {
      log("_processJoinRequest WARN: Delay interrupted: $e", name: "ListProvider._processJoinRequest");
      // Continue anyway
    }

    // Verify membership - but don't make it critical for success
    bool membershipConfirmed = false;
    try {
      log("_processJoinRequest INFO: Attempting to verify membership for group ${request.groupId}.", name: "ListProvider._processJoinRequest");
      membershipConfirmed = await _verifyMembership(request);
      log("_processJoinRequest INFO: Membership verification for group ${request.groupId} returned: $membershipConfirmed", name: "ListProvider._processJoinRequest");
    } catch (e) {
      log("_processJoinRequest ERROR: Exception during membership verification: $e", name: "ListProvider._processJoinRequest");
      // Continue anyway, assuming success since we sent the event
      membershipConfirmed = true;
    }
    
    // If membership isn't confirmed through verification, but we did send a join event,
    // we'll add the group anyway and assume it worked
    if (!membershipConfirmed) {
      log("_processJoinRequest INFO: Membership for ${request.groupId} not strictly verified, but join event was sent. Assuming success and setting membershipConfirmed=true.", name: "ListProvider._processJoinRequest");
      membershipConfirmed = true;
    }
    
    // Force update the groups list again to ensure it's saved
    try {
      _updateGroups();
      log("_processJoinRequest INFO: Final update of groups list completed", name: "ListProvider._processJoinRequest");
    } catch (e) {
      log("_processJoinRequest ERROR: Failed to do final update of groups list: $e", name: "ListProvider._processJoinRequest");
    }
    
    // Notify listeners in case any UI needs to update
    try {
      notifyListeners();
    } catch (e) {
      log("_processJoinRequest ERROR: Failed to notify listeners: $e", name: "ListProvider._processJoinRequest");
    }
    
    log("_processJoinRequest END: GroupId: ${request.groupId}. Returning confirmed: $membershipConfirmed", name: "ListProvider._processJoinRequest");
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
    log("_verifyMembership START: GroupId: ${request.groupId}, Host: ${request.host}", name: "ListProvider._verifyMembership");
    
    // Sometimes the membership event may not be immediately available
    // So we'll try to confirm membership with multiple approaches
    
    // 1. First, try to get the members list event
    final filter = Filter(kinds: [EventKind.groupMembers], limit: 1);
    final filterMap = filter.toJson();
    filterMap["#d"] = [request.groupId];

    final completer = Completer<bool>();
    bool queryComplete = false;

    log("_verifyMembership INFO: Querying for groupMembers event for ${request.groupId} on relay ${request.host}", name: "ListProvider._verifyMembership");
    nostr!.query(
      [filterMap],
      (Event event) => _checkTagsForMembership(event, completer),
      tempRelays: [request.host],
      relayTypes: RelayType.onlyTemp,
      sendAfterAuth: true,
      onComplete: () {
        queryComplete = true;
        log("_verifyMembership INFO: nostr!.query onComplete triggered for ${request.groupId}. Completer completed: ${completer.isCompleted}", name: "ListProvider._verifyMembership");
        // If no events were received to complete the completer, assume success
        // This can happen when we joined successfully but the members list hasn't been updated yet
        if (!completer.isCompleted) {
          log("_verifyMembership WARN: No members event received for ${request.groupId} but query completed. Assuming success.", name: "ListProvider._verifyMembership");
          completer.complete(true);
        }
      }
    );

    try {
      log("_verifyMembership INFO: Awaiting completer.future for ${request.groupId} with timeout ${const Duration(seconds: 10).inSeconds}s.", name: "ListProvider._verifyMembership");
      final result = await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          log("_verifyMembership WARN: Membership verification timed out for ${request.groupId}. Query completed: $queryComplete", name: "ListProvider._verifyMembership");
          // If the query completed but no membership was confirmed, 
          // the join might have worked but the members list wasn't updated yet
          if (queryComplete) {
            log("_verifyMembership INFO: Query completed for ${request.groupId} but membership not confirmed via event by timeout. Assuming success.", name: "ListProvider._verifyMembership");
            return true;
          }
          
          log("_verifyMembership WARN: Membership verification timed out for ${request.groupId} and query did not complete. Returning false.", name: "ListProvider._verifyMembership");
          return false;
        },
      );
      
      if (result) {
        log("_verifyMembership SUCCESS: Membership verified for group ${request.groupId}. Result: true.", name: "ListProvider._verifyMembership");
      } else {
        log("_verifyMembership FAILED: Membership verification failed for group ${request.groupId}. Result: false.", name: "ListProvider._verifyMembership");
      }
      log("_verifyMembership END: GroupId: ${request.groupId}. Returning $result", name: "ListProvider._verifyMembership");
      return result;
    } catch (e) {
      log("_verifyMembership ERROR: Exception verifying membership for ${request.groupId}: $e. Returning false.", name: "ListProvider._verifyMembership");
      return false;
    }
  }

  void _checkTagsForMembership(Event event, Completer<bool> completer) {
    log("_checkTagsForMembership: Received event kind ${event.kind} for group (from event tags, if 'h' present) while verifying membership.", name: "ListProvider._checkTagsForMembership");
    if (event.kind == EventKind.groupMembers) {
      for (var tag in event.tags) {
        if (tag is List && tag.length > 1) {
          if (tag[0] == "p" && tag[1] == nostr!.publicKey) {
            if (!completer.isCompleted) {
              log("_checkTagsForMembership: Found 'p' tag matching current user's publicKey. Completing with true.", name: "ListProvider._checkTagsForMembership");
              completer.complete(true);
            }
            return;
          }
        }
      }
      if (!completer.isCompleted) {
        log("_checkTagsForMembership: Iterated all tags, no matching 'p' tag. Completing with false.", name: "ListProvider._checkTagsForMembership");
        completer.complete(false);
      }
    }
  }

  void _handleJoinResults(List<GroupIdentifier> successfullyJoinedGroupIds,
      BuildContext? context, List<JoinGroupParameters> requests) {
    log("_handleJoinResults START: Successfully joined ${successfullyJoinedGroupIds.length} groups. Total requests: ${requests.length}", name: "ListProvider._handleJoinResults");
    if (successfullyJoinedGroupIds.isNotEmpty) {
      log("_handleJoinResults INFO: Join successful for ${successfullyJoinedGroupIds.length} groups", name: "ListProvider._handleJoinResults");
      
      // Store in class property for use across methods
      this.successfullyJoinedGroupIds = successfullyJoinedGroupIds;
      
      // The groups should already be added in _processJoinRequest, but let's make sure
      // by checking and adding any that are missing
      for (var groupId in successfullyJoinedGroupIds) {
        if (!_groupIdentifiers.contains(groupId)) {
          log("_handleJoinResults INFO: Adding missing group to identifiers: ${groupId.groupId} (${groupId.host})", name: "ListProvider._handleJoinResults");
          _addGroupIdentifier(groupId);
        } else {
          log("_handleJoinResults INFO: Group already in identifiers: ${groupId.groupId} (${groupId.host}). Refreshing metadata.", name: "ListProvider._handleJoinResults");
          // Refresh metadata even if already added
          _queryGroupMetadata(groupId);
        }
      }
      
      // Update the groups list event
      _updateGroups();
      
      // Force a notification to ensure the UI updates
      notifyListeners();

      // Show success message only if we believe the app is still in a valid state
      _safeShowToast(
        "Successfully joined community. You can view it in your communities list.",
        duration: const Duration(seconds: 3),
      );
      
      // Navigate to the appropriate screen
      if (context != null && context.mounted) {
        try {
          // If we're currently in the NoCommunitiesSheet, close it first
          // This helps ensure the sheet doesn't show up again after joining
          try {
            // Pop any open dialogs (like the NoCommunitiesSheet)
            Navigator.of(context).popUntil((route) => route.isFirst);
            log("_handleJoinResults INFO: Popped any open dialogs", name: "ListProvider._handleJoinResults");
          } catch (e) {
            log("_handleJoinResults WARNING: Error attempting to pop dialogs: $e", name: "ListProvider._handleJoinResults");
          }

          // Check if we have a specific group to navigate to
          if (successfullyJoinedGroupIds.isNotEmpty) {
            final groupToShow = successfullyJoinedGroupIds.first;
            log("_handleJoinResults INFO: Navigating to group detail for ${groupToShow.groupId}", name: "ListProvider._handleJoinResults");
            
            // Use our new helper method that handles errors
            _navigateToGroupDetail(context, groupToShow);
          } else {
            // Fall back to group list if no specific group
            log("_handleJoinResults INFO: No specific group to navigate to, showing group list", name: "ListProvider._handleJoinResults");
            _navigateToGroupList(context);
          }
        } catch (e) {
          log("_handleJoinResults ERROR: Navigation error: $e", name: "ListProvider._handleJoinResults");
          // Last resort - try to navigate to group list
          if (context.mounted) {
            _navigateToGroupList(context);
          }
        }
      } else {
        log("_handleJoinResults INFO: Context is null or not mounted, skipping navigation", name: "ListProvider._handleJoinResults");
      }
    } else {
      log("_handleJoinResults WARN: No groups were successfully joined based on _processJoinRequests results.", name: "ListProvider._handleJoinResults");
      
      // If we have pending group join requests, try to add them anyway
      if (requests.isNotEmpty) {
        log("_handleJoinResults INFO: Attempting to add groups directly from ${requests.length} original requests.", name: "ListProvider._handleJoinResults");
        
        for (var request in requests) {
          final groupId = GroupIdentifier(request.host, request.groupId);
          
          if (!_groupIdentifiers.contains(groupId)) {
            log("_handleJoinResults INFO: Directly adding group from request: ${groupId.groupId} host: ${groupId.host}", name: "ListProvider._handleJoinResults");
            _addGroupIdentifier(groupId);
            
            // Store the first group added to use for navigation
            if (successfullyJoinedGroupIds.isEmpty) {
              successfullyJoinedGroupIds.add(groupId);
            }
          }
        }
        
        // Update groups after direct addition
        _updateGroups();
        
        // Show a more optimistic message
        _safeShowToast(
          "Join request sent. Check your communities list shortly.",
          duration: const Duration(seconds: 3),
        );
        
        // Still navigate to the appropriate screen
        if (context != null && context.mounted) {
          try {
            // Check if we have a specific group to navigate to
            if (successfullyJoinedGroupIds.isNotEmpty) {
              final groupToShow = successfullyJoinedGroupIds.first;
              log("_handleJoinResults INFO: Navigating to group detail after direct add: ${groupToShow.groupId}", name: "ListProvider._handleJoinResults");
              _navigateToGroupDetail(context, groupToShow);
            } else {
              // Fall back to group list
              log("_handleJoinResults INFO: No specific group to navigate to after direct add, showing group list", name: "ListProvider._handleJoinResults");
              _navigateToGroupList(context);
            }
          } catch (e) {
            log("_handleJoinResults ERROR: Navigation error after direct add: $e", name: "ListProvider._handleJoinResults");
            // Try to navigate to group list on error
            if (context.mounted) {
              _navigateToGroupList(context);
            }
          }
        }
      } else {
        // Show failure message only if we believe the app is still in a valid state
        _safeShowToast("Sorry, something went wrong and you weren't added to the group.");
        log("_handleJoinResults ERROR: Failed to join group and no requests available to try. Original requests empty.", name: "ListProvider._handleJoinResults");
        
        // Navigate to group list as fallback
        if (context != null && context.mounted) {
          _navigateToGroupList(context);
        }
      }
    }
    log("_handleJoinResults END", name: "ListProvider._handleJoinResults");
  }

  void leaveGroup(GroupIdentifier gi) async {
    if (!_groupIdentifiers.contains(gi)) return;

    final cancelFunc = _safeShowLoading();

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

    try {
      cancelFunc.call();
    } catch (e) {
      log("LeaveGroup WARNING: Failed to cancel loading indicator: $e", name: "ListProvider");
    }
  }

  void _updateGroups() async {
    log("_updateGroups START: Updating groups list with ${_groupIdentifiers.length} groups.", name: "ListProvider._updateGroups");
    
    // Create tags from group identifiers
    final tags = _groupIdentifiers.map((groupId) => groupId.toJson()).toList();

    // Send an updated group list event
    final updateGroupListEvent = Event(
      nostr!.publicKey,
      EventKind.groupList,
      tags,
      "",
    );
    
    try {
      // Notify listeners BEFORE sending the event - critical for UI updates
      // This ensures we display the new groups in the UI immediately
      notifyListeners();
      
      // Force GroupFeedProvider to refresh if it exists - also critical for UI updates
      if (groupFeedProvider != null) {
        log("_updateGroups INFO: Refreshing GroupFeedProvider to show new groups.", name: "ListProvider._updateGroups");
        groupFeedProvider!.refresh();
      } else {
        log("_updateGroups INFO: GroupFeedProvider not available, can't refresh.", name: "ListProvider._updateGroups");
      }
      
      // Send to all available relays for maximum propagation
      await nostr!.sendEvent(updateGroupListEvent);
      log("_updateGroups SUCCESS: Successfully sent updated group list event (event ID: ${updateGroupListEvent.id}).", name: "ListProvider._updateGroups");
      
      // For debugging only
      if (_groupIdentifiers.length > 0) {
        _safeShowToast("UPD_GROUPS_SENT: Count: ${_groupIdentifiers.length}");
      }
      
      // Reset the newUser flag if we now have groups
      if (_groupIdentifiers.isNotEmpty && newUser) {
        log("_updateGroups INFO: Setting newUser flag to FALSE since user now has groups", name: "ListProvider._updateGroups");
        newUser = false;
      }
      
      // Notify listeners again after the event is sent successfully
      notifyListeners();
    } catch (e) {
      log("_updateGroups ERROR: Error sending updated group list event: $e", name: "ListProvider._updateGroups");
      
      // Still notify listeners even if sending fails, to ensure UI updates
      notifyListeners();
    }

    log("_updateGroups END", name: "ListProvider._updateGroups");
  }

  void _addGroupIdentifier(GroupIdentifier groupIdentifier) {
    log("_addGroupIdentifier START: Attempting to add GroupId: ${groupIdentifier.groupId}, Host: ${groupIdentifier.host}", name: "ListProvider._addGroupIdentifier");
    if (!_groupIdentifiers.any((gi) => gi.groupId == groupIdentifier.groupId && gi.host == groupIdentifier.host)) {
      _groupIdentifiers.add(groupIdentifier);
      
      // Query metadata when adding new group
      _queryGroupMetadata(groupIdentifier);
      
      log("_addGroupIdentifier SUCCESS: Added GroupId: ${groupIdentifier.groupId}. Total: ${_groupIdentifiers.length}. Queried metadata.", name: "ListProvider._addGroupIdentifier");
      _safeShowToast("ADD_GROUP_ID: ${groupIdentifier.groupId}. Total: ${_groupIdentifiers.length}.");
      
      // Reset the newUser flag if we now have groups
      if (newUser == true && _groupIdentifiers.isNotEmpty) {
        log("_addGroupIdentifier INFO: Setting newUser flag to FALSE since user now has groups", name: "ListProvider._addGroupIdentifier");
        newUser = false;
      }
      
      // Critically important to notify listeners here so UI can update
      notifyListeners();
      
      // Also notify group feed provider if it exists
      if (groupFeedProvider != null) {
        log("_addGroupIdentifier INFO: Refreshing GroupFeedProvider to show new group", name: "ListProvider._addGroupIdentifier");
        groupFeedProvider!.refresh();
      }
    } else {
      log("_addGroupIdentifier INFO: GroupId: ${groupIdentifier.groupId} already exists. Querying metadata anyway.", name: "ListProvider._addGroupIdentifier");
      
      // Still query metadata to ensure we have the latest
      _queryGroupMetadata(groupIdentifier);
    }
  }

  /// Fetch metadata for a specific group
  void _queryGroupMetadata(GroupIdentifier groupId) async {
    log("_queryGroupMetadata START: Fetching metadata for group ${groupId.groupId} from relay ${groupId.host}", name: "ListProvider._queryGroupMetadata");
    
    // Create filter for group metadata
    final filter = Filter(kinds: [EventKind.groupMetadata], limit: 5); // Increased limit
    final filterMap = filter.toJson();
    filterMap["#d"] = [groupId.groupId];

    // Track if we received any events
    bool receivedEvents = false;
    
    // Try on multiple relays to maximize chance of success
    final relays = [
      groupId.host,                            // Primary relay from the group identifier
      'wss://communities.nos.social',          // Main Plur relay as fallback
      'wss://feeds.nostr.band',                // Additional relay as fallback
    ];
    
    // Log relays we're trying
    log("_queryGroupMetadata INFO: Trying to fetch metadata from multiple relays: ${relays.join(", ")}", name: "ListProvider._queryGroupMetadata");
    
    for (final relay in relays) {
      try {
        log("_queryGroupMetadata INFO: Querying relay: $relay for group ${groupId.groupId}", name: "ListProvider._queryGroupMetadata");
        
        nostr!.query(
          [filterMap],
          (Event event) {
            receivedEvents = true;
            log("_queryGroupMetadata SUCCESS: Received event kind: ${event.kind} for group ${groupId.groupId} from relay $relay", name: "ListProvider._queryGroupMetadata");
            _safeShowToast("QGM_EVENT: ${event.kind} for ${groupId.groupId} from $relay");
            
            if (event.kind == EventKind.groupMetadata) {
              log("_queryGroupMetadata INFO: Processing metadata event for group ${groupId.groupId}", name: "ListProvider._queryGroupMetadata");
              groupProvider.onEvent(groupId, event);
              
              // Notify listeners when we receive metadata to update UI
              notifyListeners();
            }
          },
          tempRelays: [relay],
          targetRelays: [relay],
          relayTypes: RelayType.onlyTemp,
          sendAfterAuth: true,
          onComplete: () {
            log("_queryGroupMetadata INFO: Query completed for relay $relay", name: "ListProvider._queryGroupMetadata");
            if (!receivedEvents) {
              log("_queryGroupMetadata WARN: No events received from relay $relay", name: "ListProvider._queryGroupMetadata");
            }
          },
        );
      } catch (e) {
        log("_queryGroupMetadata ERROR: Failed to query relay $relay: $e", name: "ListProvider._queryGroupMetadata");
      }
    }
    
    // Update group list after fetching metadata
    _updateGroups();
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

  Future<(String?, GroupIdentifier?)> createGroupAndGenerateInvite(
      String groupName) async {
    log("Creating group: $groupName", name: "ListProvider");
    
    // Show loading indicator
    final cancelFunc = _safeShowLoading();
    
    try {
      // Use multiple relays to maximize success chance
      const List<String> relaysToTry = [
        RelayProvider.defaultGroupsRelayAddress,
        'wss://feeds.nostr.band',  // Try another relay as backup
      ];
      
      // Generate a random string for the group ID
      final groupId = StringCodeGenerator.generateGroupId();
      log("Generated group ID: $groupId", name: "ListProvider");
      
      // Create the event for creating a group
      final createGroupEvent = Event(
        nostr!.publicKey,
        EventKind.groupCreateGroup,
        [
          ["h", groupId]
        ],
        "",
      );
      
      // Try sending to multiple relays to ensure success
      Event? resultEvent;
      String usedRelay = relaysToTry[0]; // Default to first relay
      
      for (final relay in relaysToTry) {
        try {
          log("Sending group creation event to relay: $relay", name: "ListProvider");
          final result = await nostr!.sendEvent(
            createGroupEvent, 
            tempRelays: [relay], 
            targetRelays: [relay]
          );
          
          if (result != null) {
            resultEvent = result;
            usedRelay = relay;
            log("Group creation successful on relay: $relay", name: "ListProvider");
            break; // Success, stop trying other relays
          }
        } catch (e) {
          log("Error creating group on relay $relay: $e", name: "ListProvider");
          // Continue to next relay
        }
      }
      
      String? inviteLink;
      GroupIdentifier? newGroup;
      
      // If event was successfully sent to any relay
      if (resultEvent != null) {
        // Create the group identifier
        newGroup = GroupIdentifier(usedRelay, groupId);
        log("Created group identifier: $usedRelay/$groupId", name: "ListProvider");
        
        // Add the group properly using our method that handles metadata
        _addGroupIdentifier(newGroup);
        log("Added group to identifiers list", name: "ListProvider");
        
        // Create and set metadata
        await _createAndSetMetadata(newGroup, groupName);
        
        // Update groups list event
        _updateGroups();
        
        // Generate an invite code and create invite link
        final inviteCode = StringCodeGenerator.generateInviteCode();
        inviteLink = createInviteLink(newGroup, inviteCode);
        log("Created invite link: $inviteLink", name: "ListProvider");
        
        // Force refresh group data
        if (groupFeedProvider != null) {
          log("Refreshing GroupFeedProvider to show new group", name: "ListProvider");
          groupFeedProvider!.refresh();
        }
        
        // Notify listeners to update UI
        notifyListeners();
      } else {
        log("Failed to create group - could not send event to any relay", name: "ListProvider");
        _safeShowToast("Failed to create community. Please check your connection and try again.");
      }
      
      // Return results
      return (inviteLink, newGroup);
    } catch (e) {
      log("Exception during group creation: $e", name: "ListProvider");
      _safeShowToast("Error creating community: $e");
      return (null, null);
    } finally {
      // Always hide loading indicator
      try {
        cancelFunc.call();
      } catch (e) {
        log("CreateGroup WARNING: Failed to cancel loading indicator: $e", name: "ListProvider");
      }
    }
  }
  
  // Create and set metadata in a more reliable way
  Future<void> _createAndSetMetadata(GroupIdentifier group, String groupName) async {
    log("Setting metadata for group: ${group.groupId} with name: $groupName", name: "ListProvider");
    
    try {
      // Create metadata with name and default values
      final firstInitial = groupName.isNotEmpty ? 
          groupName.substring(0, 1).toUpperCase() : 'G';
          
      GroupMetadata groupMetadata = GroupMetadata(
        group.groupId,
        0,
        name: groupName,
        // Add a picture if none was provided
        picture: "https://placehold.co/400x400/4267B2/FFF?text=$firstInitial",
        // Add a default about text
        about: "A new community called $groupName",
        // Default to private, closed group
        public: false,
        open: false,
      );
      
      // Update metadata
      groupProvider.updateMetadata(group, groupMetadata);
      log("Metadata updated successfully", name: "ListProvider");
      
      // Wait a moment to ensure metadata is processed
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      log("Error updating metadata: $e", name: "ListProvider");
      // Continue despite error - group can still work without metadata
    }
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
    log("Creating invite link for group ${group.groupId}", name: "ListProvider");
    
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

    // Try sending to multiple relays to ensure the invite propagates
    // This is especially important for groups
    List<String> relaysToTry = [
      group.host, 
      RelayProvider.defaultGroupsRelayAddress
    ];
    
    // Ensure no duplicates
    relaysToTry = relaysToTry.toSet().toList();
    
    // Send to all applicable relays
    for (final relay in relaysToTry) {
      try {
        log("Sending invite event to relay: $relay", name: "ListProvider");
        nostr!.sendEvent(
          inviteEvent,
          tempRelays: [relay], 
          targetRelays: [relay]
        );
      } catch (e) {
        log("Error sending invite to relay $relay: $e", name: "ListProvider");
        // Continue to next relay
      }
    }

    // Generate both the direct protocol link and the web-friendly link
    final directLink = 'plur://join-community?group-id=${group.groupId}&code=$inviteCode&relay=${Uri.encodeComponent(group.host)}';
    log("Generated direct protocol link: $directLink", name: "ListProvider");
    
    // For web-friendly links, we'll use our GroupInviteLinkUtil
    try {
      // Try to create a short URL if possible
      final webLink = GroupInviteLinkUtil.generateUniversalLink(
        group.groupId,
        inviteCode,
        group.host
      );
      
      log("Generated web-friendly link: $webLink", name: "ListProvider");
      
      // Return the web-friendly link as the primary link
      return webLink;
    } catch (e) {
      log("Error generating web link, falling back to direct protocol: $e", name: "ListProvider");
      // Fall back to direct protocol link if web link generation fails
      return directLink;
    }
  }

  void clear() {
    _holder.clear();
    _bookmarks = Bookmarks();
    _groupIdentifiers.clear();
    notifyListeners();
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

// Helper function to safely show toast messages
void _safeShowToast(String text, {Duration? duration}) {
  try {
    BotToast.showText(text: text, duration: duration ?? const Duration(seconds: 2));
  } catch (e) {
    log("SafeToast ERROR: Failed to show toast: $e", name: "ListProvider.safeToast");
  }
}

// Helper function to safely show loading indicator
Function _safeShowLoading() {
  try {
    return BotToast.showLoading();
  } catch (e) {
    log("SafeLoading ERROR: Failed to show loading: $e", name: "ListProvider.safeLoading");
    // Return a no-op function so that callers can still call it
    return () {};
  }
}
