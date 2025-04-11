import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/provider/list_provider.dart';
import 'package:nostrmo/util/time_util.dart';
import 'package:nostrmo/provider/relay_provider.dart';

/// Provider that handles fetching and managing events from multiple joined communities
class GroupFeedProvider extends ChangeNotifier {
  final EventMemBox notesBox = EventMemBox();
  final EventMemBox newNotesBox = EventMemBox();
  
  final String _subscribeId = StringUtil.rndNameStr(16);
  bool _isSubscribed = false;
  
  // Used to store group identifiers to track which communities' posts to fetch
  final Set<GroupIdentifier> _groupIdentifiers = {};
  
  // For testing
  Set<GroupIdentifier> get groupIdentifiers => _groupIdentifiers;
  
  // For testing purposes
  ListProvider? _testListProvider;
  
  // Getter for list provider (allows for testing)
  ListProvider get _listProvider => _testListProvider ?? listProvider;
  
  // For testing
  void setListProvider(ListProvider provider) {
    _testListProvider = provider;
  }
  
  // Initial load
  void refresh() {
    // Clear existing data
    notesBox.clear();
    newNotesBox.clear();
    
    // Get groups from list provider
    _groupIdentifiers.clear();
    _groupIdentifiers.addAll(_listProvider.groupIdentifiers);
    
    // If we have groups, query for events
    if (_groupIdentifiers.isNotEmpty) {
      _doInitialQuery();
      _subscribe();
    }
    
    notifyListeners();
  }
  
  void _doInitialQuery() {
    if (_groupIdentifiers.isEmpty) {
      log("No groups to query events for");
      return;
    }
    
    log("Querying for events from ${_groupIdentifiers.length} groups");
    
    // Create filters to get GROUP_NOTE events from all joined communities
    final List<Map<String, dynamic>> filters = [];
    
    // Group h-tags together to reduce the number of filters
    final List<String> groupIds = _groupIdentifiers.map((gi) => gi.groupId).toList();
    
    // Create a filter for GROUP_NOTE events
    filters.add({
      "kinds": [EventKind.groupNote],
      "#h": groupIds,
      "limit": 50,
    });
    
    // Create a filter for GROUP_NOTE_REPLY events
    filters.add({
      "kinds": [EventKind.groupNoteReply],
      "#h": groupIds,
      "limit": 50,
    });
    
    nostr!.query(
      filters,
      _onQueryEvent,
      tempRelays: [RelayProvider.defaultGroupsRelayAddress],
      relayTypes: [RelayType.temp],
      sendAfterAuth: true,
    );
  }
  
  // Used for pagination
  void doQuery(int until) {
    if (_groupIdentifiers.isEmpty) {
      return;
    }
    
    // Create filters for pagination (similar to initial query but with until param)
    final List<Map<String, dynamic>> filters = [];
    final List<String> groupIds = _groupIdentifiers.map((gi) => gi.groupId).toList();
    
    filters.add({
      "kinds": [EventKind.groupNote],
      "#h": groupIds,
      "until": until,
      "limit": 50,
    });
    
    filters.add({
      "kinds": [EventKind.groupNoteReply],
      "#h": groupIds,
      "until": until,
      "limit": 50,
    });
    
    nostr!.query(
      filters,
      _onQueryEvent,
      tempRelays: [RelayProvider.defaultGroupsRelayAddress],
      relayTypes: [RelayType.temp],
      sendAfterAuth: true,
    );
  }
  
  void _onQueryEvent(Event event) {
    // Only add events that belong to our groups
    if (isGroupEvent(event)) {
      notesBox.add(event);
      notifyListeners();
    }
  }
  
  // Live subscription for new events
  void _subscribe() {
    // If already subscribed, unsubscribe first
    if (_isSubscribed) {
      _unsubscribe();
    }
    
    if (_groupIdentifiers.isEmpty) {
      return;
    }
    
    final currentTime = currentUnixTimestamp();
    final List<String> groupIds = _groupIdentifiers.map((gi) => gi.groupId).toList();
    
    final filters = [
      {
        "kinds": [EventKind.groupNote],
        "#h": groupIds,
        "since": currentTime,
      },
      {
        "kinds": [EventKind.groupNoteReply],
        "#h": groupIds,
        "since": currentTime,
      }
    ];
    
    try {
      nostr!.subscribe(
        filters,
        _handleNewEvent,
        id: _subscribeId,
        relayTypes: [RelayType.temp],
        tempRelays: [RelayProvider.defaultGroupsRelayAddress],
        sendAfterAuth: true,
      );
      _isSubscribed = true;
    } catch (e) {
      log("Error in subscription: $e");
    }
  }
  
  void _unsubscribe() {
    if (_isSubscribed) {
      try {
        nostr!.unsubscribe(_subscribeId);
        _isSubscribed = false;
      } catch (e) {
        log("Error unsubscribing: $e");
      }
    }
  }
  
  void _handleNewEvent(Event event) {
    // Add new events to the new notes box
    if (isGroupEvent(event)) {
      newNotesBox.add(event);
      notifyListeners();
    }
  }
  
  // Merge new events into the main box when user refreshes
  void mergeNewEvent() {
    var events = newNotesBox.all();
    for (var event in events) {
      notesBox.add(event);
    }
    newNotesBox.clear();
    notifyListeners();
  }
  
  // Check if event belongs to one of our groups
  bool isGroupEvent(Event event) {
    if (event.kind != EventKind.groupNote && event.kind != EventKind.groupNoteReply) {
      return false;
    }
    
    // Look for the h tag to identify the group
    for (var tag in event.tags) {
      if (tag is List && tag.length > 1 && tag[0] == 'h') {
        final groupId = tag[1];
        // Check if this is one of our groups
        return _groupIdentifiers.any((gi) => gi.groupId == groupId);
      }
    }
    
    return false;
  }
  
  // Cleanup
  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }
}