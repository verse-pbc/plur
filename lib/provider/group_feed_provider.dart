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
    clearData(preserveCache: true);
  }

  void clearData({bool preserveCache = false}) {
    newNotesBox.clear();
    notesBox.clear();
    
    // Only clear the static cache if explicitly requested
    if (!preserveCache) {
      _staticEventCache.clear();
    }
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

  // Add static cache of events to persist even when provider is recreated
  static final Map<String, Event> _staticEventCache = {};
  
  // Track when the last query was made to prevent duplicate queries
  DateTime? _lastQueryTime;
  
  // Time in milliseconds to throttle query requests
  static const int _queryThrottleMs = 5000; // 5 seconds
  
  void doQuery(int? until) {
    // Don't allow rapid duplicate queries
    final now = DateTime.now();
    if (_lastQueryTime != null) {
      final diffMs = now.difference(_lastQueryTime!).inMilliseconds;
      if (diffMs < _queryThrottleMs) {
        log("Query throttled, last query was $diffMs ms ago");
        return;
      }
    }
    _lastQueryTime = now;
    
    final groupIds = _listProvider.groupIdentifiers;
    if (groupIds.isEmpty) {
      return;
    }
    
    // Restore cached events if we have any
    if (notesBox.isEmpty() && _staticEventCache.isNotEmpty) {
      log("Restoring ${_staticEventCache.length} events from cache");
      _staticEventCache.values.forEach((event) {
        notesBox.add(event);
      });
      notesBox.sort();
      
      // Mark as loaded since we restored from cache
      if (isLoading) {
        isLoading = false;
        notifyListeners();
      }
    }

    // Create filters for each group
    final filters = groupIds.map((groupId) {
      final filter = Filter(
        until: until ?? _initTime,
        kinds: [EventKind.groupNote, EventKind.groupNoteReply],
      );
      final jsonMap = filter.toJson();
      jsonMap["#h"] = [groupId.groupId];
      return jsonMap;
    }).toList();

    // Query the default relay for all groups to get initial results quickly
    nostr!.query(
      filters,
      onEvent,
      tempRelays: [RelayProvider.defaultGroupsRelayAddress],
      relayTypes: RelayType.onlyTemp,
      sendAfterAuth: true,
    );
    
    // Batch queries to group-specific relays to reduce network overhead
    // Use a delay to allow the UI to respond first with the default relay results
    Future.delayed(const Duration(milliseconds: 100), () {
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
    });
  }

  void onEvent(Event event) {
    later(event, (list) {
      bool noteAdded = false;

      for (var e in list) {
        if (isGroupNote(e)) {
          // Add to both the active box and the static cache
          if (notesBox.add(e)) {
            noteAdded = true;
            // Update static cache for persistence
            _staticEventCache[e.id] = e;
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
      // Remove from all storage locations
      newNotesBox.delete(id);
      notesBox.delete(id);
      _staticEventCache.remove(id);
      
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