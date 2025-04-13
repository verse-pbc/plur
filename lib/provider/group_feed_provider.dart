import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/provider/list_provider.dart';
import 'package:nostrmo/provider/relay_provider.dart';
import 'package:nostrmo/data/join_group_parameters.dart';

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
    // Log initialization
    // print("GroupFeedProvider.doQuery called with until=$until");
    
    // Don't allow rapid duplicate queries
    final now = DateTime.now();
    if (_lastQueryTime != null) {
      final diffMs = now.difference(_lastQueryTime!).inMilliseconds;
      if (diffMs < _queryThrottleMs) {
        // log("Query throttled, last query was $diffMs ms ago");
        return;
      }
    }
    _lastQueryTime = now;
    
    final groupIds = _listProvider.groupIdentifiers;
    
    // Debugging log to help diagnose global feed issues
    log("GroupFeedProvider: Querying for ${groupIds.length} groups: ${groupIds.map((g) => g.groupId).join(', ')}",
        name: "GroupFeedProvider");
    
    if (groupIds.isEmpty) {
      // If no groups, set loading to false to update the UI
      log("GroupFeedProvider: No groups found in listProvider.groupIdentifiers", 
          name: "GroupFeedProvider");
      if (isLoading) {
        isLoading = false;
        notifyListeners();
      }
      return;
    }
    
    // Restore cached events if we have any
    if (notesBox.isEmpty() && _staticEventCache.isNotEmpty) {
      // log("Restoring ${_staticEventCache.length} events from cache");
      for (var event in _staticEventCache.values) {
        notesBox.add(event);
      }
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
        // Limit to 50 events per group for faster loading
        limit: 50,
      );
      final jsonMap = filter.toJson();
      jsonMap["#h"] = [groupId.groupId];
      return jsonMap;
    }).toList();

    // Log query
    // print("Querying default relay with ${filters.length} filters");
    
    // Query the default relay for all groups to get initial results quickly
    try {
      nostr!.query(
        filters,
        onEvent,
        tempRelays: [RelayProvider.defaultGroupsRelayAddress],
        relayTypes: RelayType.onlyTemp,
        sendAfterAuth: true,
      );
    } catch (e) {
      // print("Error querying default relay: $e");
    }
    
    // Batch queries to group-specific relays to reduce network overhead
    // Use a delay to allow the UI to respond first with the default relay results
    Future.delayed(const Duration(milliseconds: 100), () {
      for (final groupId in groupIds) {
        // print("Querying specific relay ${groupId.host} for group ${groupId.groupId}");
        
        final specificFilter = Filter(
          until: until ?? _initTime,
          kinds: [EventKind.groupNote, EventKind.groupNoteReply],
          // Limit to 30 events per group for specific relays
          limit: 30,
        );
        final jsonMap = specificFilter.toJson();
        jsonMap["#h"] = [groupId.groupId];
        
        // Query the specific relay for this group
        try {
          nostr!.query(
            [jsonMap],
            onEvent,
            tempRelays: [groupId.host],
            relayTypes: RelayType.onlyTemp,
            sendAfterAuth: true,
          );
        } catch (e) {
          // print("Error querying relay ${groupId.host}: $e");
        }
      }
      
      // Set a fallback timeout to ensure loading indicator goes away
      // even if no events are received
      Future.delayed(const Duration(seconds: 5), () {
        if (isLoading) {
          isLoading = false;
          notifyListeners();
        }
      });
    });
  }

  void onEvent(Event event) {
    // Log event received
    if (isLoading) {
      // print("GroupFeedProvider received event while loading: ${event.id} type=${event.kind}");
    }
    
    later(event, (list) {
      bool noteAdded = false;
      int eventCount = 0;

      for (var e in list) {
        eventCount++;
        if (isGroupNote(e)) {
          // Make sure this event has an h tag matching one of our groups
          bool hasValidGroupTag = false;
          for (var tag in e.tags) {
            if (tag is List && tag.isNotEmpty && tag.length > 1 && 
                tag[0] == "h" && 
                _listProvider.groupIdentifiers.any((g) => g.groupId == tag[1])) {
              hasValidGroupTag = true;
              break;
            }
          }
          
          // Only add if it has a valid group tag matching our groups
          if (hasValidGroupTag && notesBox.add(e)) {
            noteAdded = true;
            // Update static cache for persistence
            _staticEventCache[e.id] = e;
          }
        }
      }

      // Always sort if we added notes
      if (noteAdded) {
        notesBox.sort();
      }
      
      // If we received events and we're still in loading state, set loading to false
      if (isLoading) {
        isLoading = false;
        notifyListeners();
      } else if (noteAdded) {
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
    log("GroupFeedProvider: refresh() called", name: "GroupFeedProvider");
    
    // Log current status
    final groupIds = _listProvider.groupIdentifiers;
    log("GroupFeedProvider: Refreshing with ${groupIds.length} groups: ${groupIds.map((g) => g.groupId).join(', ')}",
        name: "GroupFeedProvider");
    
    // Set loading state first
    isLoading = true;
    notifyListeners();
    
    // Clear data, but preserve cache for faster reloading
    clearData(preserveCache: false);
    
    // Reset initialization time to now
    _initTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    
    // First unsubscribe to ensure clean state
    _unsubscribe();
    
    // Then resubscribe for new events
    _subscribe();
    
    // Finally do the query for existing events
    doQuery(null);
    
    // Ensure we exit loading state after a timeout
    Future.delayed(const Duration(seconds: 5), () {
      if (isLoading) {
        isLoading = false;
        notifyListeners();
      }
    });
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
      // log("Error in subscription to default relay: $e");
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
          id: "${subscribeId}_$i",
          relayTypes: [RelayType.temp],
          tempRelays: [groupId.host],
          sendAfterAuth: true,
        );
      } catch (e) {
        // log("Error in subscription to group relay ${groupId.host}: $e");
      }
    }
  }

  void _handleSubscriptionEvent(Event event) {
    // print("Subscription received event: ${event.id} kind=${event.kind}");
    
    later(event, (list) {
      // print("Processing ${list.length} events from subscription");
      for (final e in list) {
        // Check if the event has a valid group tag matching our groups
        bool hasValidGroupTag = false;
        if (isGroupNote(e)) {
          for (var tag in e.tags) {
            if (tag is List && tag.isNotEmpty && tag.length > 1 && 
                tag[0] == "h" && 
                _listProvider.groupIdentifiers.any((g) => g.groupId == tag[1])) {
              hasValidGroupTag = true;
              break;
            }
          }
        }
        
        // Only process events with valid group tags
        if (hasValidGroupTag) {
          onNewEvent(e);
        }
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
          nostr!.unsubscribe("${subscribeId}_$i");
        } catch (e) {
          // Ignore errors for individual unsubscribes
        }
      }
      
      _isSubscribed = false;
    } catch (e) {
      // log("Error unsubscribing: $e");
    }
  }
}