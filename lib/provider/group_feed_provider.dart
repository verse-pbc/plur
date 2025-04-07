import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/provider/list_provider.dart';
import 'package:nostrmo/provider/relay_provider.dart';

/// Provider that fetches and manages posts from all groups a user belongs to.
class GroupFeedProvider extends ChangeNotifier with PendingEventsLaterFunction {
  late int _initTime;
  
  /// Holds the latest posts from all groups
  EventMemBox notesBox = EventMemBox(sortAfterAdd: false);
  
  /// Holds new posts that have been received but not yet shown in the main feed
  EventMemBox newNotesBox = EventMemBox(sortAfterAdd: false);

  final ListProvider _listProvider;
  final String subscribeId = StringUtil.rndNameStr(16);
  bool _isSubscribed = false;
  
  /// Indicates whether the provider is currently loading initial events
  bool isLoading = true;

  GroupFeedProvider(this._listProvider) {
    _initTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    
    // Set a timeout to stop showing the loading indicator after 3 seconds
    // even if no events are received
    Future.delayed(const Duration(seconds: 3), () {
      if (isLoading) {
        isLoading = false;
        notifyListeners();
      }
    });
  }

  void clear() {
    clearData();
  }

  void clearData() {
    newNotesBox.clear();
    notesBox.clear();
  }

  @override
  void dispose() {
    _unsubscribe();
    disposeLater();
    super.dispose();
  }

  void onNewEvent(Event e) {
    if (e.kind == EventKind.groupNote || e.kind == EventKind.groupNoteReply) {
      if (!notesBox.contains(e.id)) {
        if (newNotesBox.add(e)) {
          if (e.createdAt > _initTime) {
            _initTime = e.createdAt;
          }
          if (e.pubkey == nostr!.publicKey) {
            mergeNewEvent();
          } else {
            notifyListeners();
          }
        }
      }
    }
  }

  void mergeNewEvent() {
    final isEmpty = newNotesBox.isEmpty();
    if (isEmpty) {
      return;
    }
    notesBox.addBox(newNotesBox);
    newNotesBox.clear();
    notesBox.sort();
    notifyListeners();
  }

  void doQuery(int? until) {
    final groupIds = _listProvider.groupIdentifiers;
    if (groupIds.isEmpty) {
      return;
    }

    final filters = groupIds.map((groupId) {
      final filter = Filter(
        until: until ?? _initTime,
        kinds: [EventKind.groupNote, EventKind.groupNoteReply],
      );
      final jsonMap = filter.toJson();
      jsonMap["#h"] = [groupId.groupId];
      return jsonMap;
    }).toList();

    // Query the default relay for all groups
    nostr!.query(
      filters,
      onEvent,
      tempRelays: [RelayProvider.defaultGroupsRelayAddress],
      relayTypes: RelayType.onlyTemp,
      sendAfterAuth: true,
    );
    
    // Also query each group's specific relay
    for (final groupId in groupIds) {
      final specificFilter = Filter(
        until: until ?? _initTime,
        kinds: [EventKind.groupNote, EventKind.groupNoteReply],
      );
      final jsonMap = specificFilter.toJson();
      jsonMap["#h"] = [groupId.groupId];
      
      // Query the specific relay for this group
      nostr!.query(
        [jsonMap],
        onEvent,
        tempRelays: [groupId.host],
        relayTypes: RelayType.onlyTemp,
        sendAfterAuth: true,
      );
    }
  }

  void onEvent(Event event) {
    later(event, (list) {
      bool noteAdded = false;

      for (var e in list) {
        if (isGroupNote(e)) {
          if (notesBox.add(e)) {
            noteAdded = true;
          }
        }
      }

      // If we received events and we're still in loading state, set loading to false
      if (isLoading) {
        isLoading = false;
        notifyListeners();
      } else if (noteAdded) {
        notesBox.sort();
        notifyListeners();
      }
    }, null);
  }

  bool isGroupNote(Event e) {
    return e.kind == EventKind.groupNote || e.kind == EventKind.groupNoteReply;
  }

  void deleteEvent(Event e) {
    var id = e.id;
    if (isGroupNote(e)) {
      newNotesBox.delete(id);
      notesBox.delete(id);
      notesBox.sort();
      notifyListeners();
    }
  }

  void refresh() {
    clearData();
    _initTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    doQuery(null);
    _subscribe();
  }

  void subscribe() {
    if (!_isSubscribed) {
      _subscribe();
      _isSubscribed = true;
    }
  }

  void _subscribe() {
    if (StringUtil.isNotBlank(subscribeId)) {
      _unsubscribe();
    }

    final groupIds = _listProvider.groupIdentifiers;
    if (groupIds.isEmpty) {
      return;
    }

    final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    
    // Create a filter for each group
    final filters = groupIds.map((groupId) {
      return {
        "kinds": [EventKind.groupNote, EventKind.groupNoteReply],
        "#h": [groupId.groupId],
        "since": currentTime
      };
    }).toList();

    // Subscribe to the default relay for all groups
    try {
      nostr!.subscribe(
        filters,
        _handleSubscriptionEvent,
        id: "${subscribeId}_default",
        relayTypes: [RelayType.temp],
        tempRelays: [RelayProvider.defaultGroupsRelayAddress],
        sendAfterAuth: true,
      );
    } catch (e) {
      log("Error in subscription to default relay: $e");
    }
    
    // Subscribe to each group's specific relay
    for (int i = 0; i < groupIds.length; i++) {
      final groupId = groupIds[i];
      try {
        final filter = {
          "kinds": [EventKind.groupNote, EventKind.groupNoteReply],
          "#h": [groupId.groupId],
          "since": currentTime
        };
        
        nostr!.subscribe(
          [filter],
          _handleSubscriptionEvent,
          id: "${subscribeId}_${i}",
          relayTypes: [RelayType.temp],
          tempRelays: [groupId.host],
          sendAfterAuth: true,
        );
      } catch (e) {
        log("Error in subscription to group relay ${groupId.host}: $e");
      }
    }
  }

  void _handleSubscriptionEvent(Event event) {
    later(event, (list) {
      for (final e in list) {
        onNewEvent(e);
      }
    }, null);
  }

  void _unsubscribe() {
    try {
      // Unsubscribe from default relay subscription
      nostr!.unsubscribe("${subscribeId}_default");
      
      // Unsubscribe from individual group relay subscriptions
      final groupIds = _listProvider.groupIdentifiers;
      for (int i = 0; i < groupIds.length; i++) {
        try {
          nostr!.unsubscribe("${subscribeId}_${i}");
        } catch (e) {
          // Ignore errors for individual unsubscribes
        }
      }
      
      _isSubscribed = false;
    } catch (e) {
      log("Error unsubscribing: $e");
    }
  }
}