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

  // Expose static cache for debugging access
  static final Map<String, Event> _staticEventCache = {};
  Map<String, Event> get staticEventCache => _staticEventCache;

  GroupFeedProvider(this._listProvider) {
    _initTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    
    // Set the reference in ListProvider so it can coordinate with us
    ListProvider.groupFeedProvider = this;
    
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
    // The caller should have already verified this is a group note with valid tags
    
    // Skip if already in main notes box
    if (notesBox.contains(e.id)) {
      return;
    }
    
    // Try to add to new notes box
    if (newNotesBox.add(e)) {
      // Update initialization time if needed
      if (e.createdAt > _initTime) {
        _initTime = e.createdAt;
      }
      
      // Automatically merge our own posts
      if (e.pubkey == nostr?.publicKey) {
        mergeNewEvent();
      } else {
        notifyListeners();
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
  
  // Track when the last query was made to prevent duplicate queries
  DateTime? _lastQueryTime;
  
  // Time in milliseconds to throttle query requests
  static const int _queryThrottleMs = 5000; // 5 seconds
  
  void doQuery(int? until) {
    // Log initialization with more details
    log("🔍 doQuery called with until=${until ?? 'null'}", name: "GroupFeedProvider");
    
    // Don't allow rapid duplicate queries
    final now = DateTime.now();
    if (_lastQueryTime != null) {
      final diffMs = now.difference(_lastQueryTime!).inMilliseconds;
      if (diffMs < _queryThrottleMs) {
        log("⏱️ Query throttled - last query was $diffMs ms ago (< $_queryThrottleMs ms)",
            name: "GroupFeedProvider");
        return;
      }
    }
    _lastQueryTime = now;
    
    final groupIds = _listProvider.groupIdentifiers;
    
    // Detailed debugging log to help diagnose global feed issues
    if (groupIds.isNotEmpty) {
      log("📋 Querying for ${groupIds.length} groups:", name: "GroupFeedProvider");
      for (int i = 0; i < groupIds.length; i++) {
        final group = groupIds[i];
        log("  Group ${i+1}: ${group.groupId} at ${group.host}", name: "GroupFeedProvider");
      }
    } else {
      log("❌ No groups found to query", name: "GroupFeedProvider");
      if (isLoading) {
        isLoading = false;
        notifyListeners();
      }
      return;
    }
    
    // IMPORTANT: Log static cache size for debugging
    log("💾 Static cache has ${_staticEventCache.length} events", name: "GroupFeedProvider");
    
    // Restore cached events if we have any, but verify they are still valid
    if (notesBox.isEmpty() && _staticEventCache.isNotEmpty) {
      log("📦 Restoring ${_staticEventCache.length} events from cache", name: "GroupFeedProvider");
      
      // Make a copy of the keys to avoid iteration issues
      final cachedIds = _staticEventCache.keys.toList();
      int validCount = 0;
      int invalidCount = 0;
      
      for (var id in cachedIds) {
        final event = _staticEventCache[id];
        if (event != null) {
          // More detailed logging to diagnose validation issues
          final isValid = hasValidGroupTag(event);
          log("  Cache event ${event.id.substring(0, 8)}: ${isValid ? 'VALID' : 'INVALID'}", 
              name: "GroupFeedProvider");
          
          if (isValid) {
            // Log more details about valid events
            final eventGroups = event.tags
                .where((tag) => tag is List && tag.isNotEmpty && tag.length > 1 && tag[0] == "h")
                .map((tag) => tag[1] as String)
                .toList();
                
            log("  ✅ Valid event ${event.id.substring(0, 8)}, kind=${event.kind}, groups=[${eventGroups.join(', ')}]",
                name: "GroupFeedProvider");
            
            // Check if successfully added to notesBox
            if (notesBox.add(event)) {
              validCount++;
            } else {
              log("  ⚠️ Event ${event.id.substring(0, 8)} not added to notesBox (duplicate?)",
                  name: "GroupFeedProvider");
            }
          } else {
            // Remove invalid events from cache
            _staticEventCache.remove(id);
            invalidCount++;
          }
        }
      }
      
      log("📊 Cache restoration complete: $validCount valid events, $invalidCount invalid/removed", 
          name: "GroupFeedProvider");
      
      notesBox.sort();
      
      // CRITICAL: Always notify listeners to update UI
      notifyListeners();
      
      // Mark as loaded since we restored from cache
      if (isLoading) {
        isLoading = false;
        notifyListeners();
      }
    } else if (notesBox.isEmpty()) {
      log("🆕 No cached events available, starting fresh query", name: "GroupFeedProvider");
    } else {
      log("📊 Already have ${notesBox.length()} events in notesBox, still querying for more", 
          name: "GroupFeedProvider");
    }

    // Create filters for each group with detailed logging
    log("🔍 Creating filters for ${groupIds.length} groups", name: "GroupFeedProvider");
    final filters = groupIds.map((groupId) {
      final filter = Filter(
        until: until ?? _initTime,
        kinds: [EventKind.groupNote, EventKind.groupNoteReply],
        // Limit to 50 events per group for faster loading
        limit: 50,
      );
      final jsonMap = filter.toJson();
      jsonMap["#h"] = [groupId.groupId];
      
      log("  Filter for group ${groupId.groupId}: kinds=[${filter.kinds?.join(',')}], limit=${filter.limit}, tag h=${groupId.groupId}",
          name: "GroupFeedProvider");
          
      return jsonMap;
    }).toList();

    // Try multiple relays for better reliability
    final relaysToTry = <String>{
      RelayProvider.defaultGroupsRelayAddress,  // Always include default relay
      'wss://nos.lol',                          // Include major Nostr relays
      'wss://relay.damus.io',
    };
    
    // Add unique hosts from group identifiers
    for (final groupId in groupIds) {
      relaysToTry.add(groupId.host);
    }
    
    log("🌐 Will query ${relaysToTry.length} relays for events: ${relaysToTry.join(', ')}", 
        name: "GroupFeedProvider");
    
    // Query all relays in our list
    int relayQueryCount = 0;
    for (final relay in relaysToTry) {
      try {
        relayQueryCount++;
        log("🌐 Querying relay $relay (${relayQueryCount}/${relaysToTry.length}) for ${filters.length} groups", 
            name: "GroupFeedProvider");
        nostr!.query(
          filters,
          onEvent,
          tempRelays: [relay],
          relayTypes: RelayType.onlyTemp,
          sendAfterAuth: true,
        );
      } catch (e) {
        log("❌ Error querying relay $relay: $e", name: "GroupFeedProvider");
      }
    }
    
    // Set a fallback timeout to ensure loading indicator goes away
    // even if no events are received
    log("⏱️ Setting 5-second fallback timeout for loading indicator", name: "GroupFeedProvider");
    Future.delayed(const Duration(seconds: 5), () {
      if (isLoading) {
        log("⏱️ Fallback timeout reached, forcing loading=false", name: "GroupFeedProvider");
        isLoading = false;
        notifyListeners();
      }
    });
  }

  // Checks if an event has a valid h-tag that matches one of our group IDs
  bool hasValidGroupTag(Event e) {
    // Get the current list of user's groups from the list provider
    final userGroups = _listProvider.groupIdentifiers;
    
    // If user has no groups, automatically return false
    if (userGroups.isEmpty) {
      log("User has no groups, automatically excluding all events", 
          name: "GroupFeedProvider");
      return false;
    }
    
    // Comprehensive logging for debugging
    log("Checking event ${e.id.substring(0, 8)} with kind ${e.kind} from ${e.pubkey.substring(0, 8)}", 
        name: "GroupFeedProvider");
    
    // Extract all h-tags from the event - these identify which group the event belongs to
    final eventGroupTags = e.tags
        .where((tag) => tag is List && tag.isNotEmpty && tag.length > 1 && tag[0] == "h")
        .map((tag) => tag[1] as String)
        .toList();
    
    // If event has no group tags, it can't belong to any group
    if (eventGroupTags.isEmpty) {
      log("Event ${e.id.substring(0, 8)} has no h-tags, excluding from feed", 
          name: "GroupFeedProvider");
      return false;
    }
    
    // Log all the event's tags for debugging
    for (var tag in e.tags) {
      if (tag is List && tag.isNotEmpty) {
        log("Event ${e.id.substring(0, 8)} has tag: ${tag.join(':')}",
            name: "GroupFeedProvider");
      }
    }
    
    // Create a map of user group IDs for faster lookup
    final userGroupIds = {for (var group in userGroups) group.groupId: true};
    
    // Log all user groups for comparison
    log("User belongs to ${userGroups.length} groups: ${userGroups.map((g) => '${g.groupId}@${g.host}').join(', ')}",
        name: "GroupFeedProvider");
    
    // Check if any event group tag matches any of the user's groups
    for (var groupTag in eventGroupTags) {
      if (userGroupIds.containsKey(groupTag)) {
        // This is a debug log to confirm which group the event belongs to
        log("✅ MATCH FOUND: Group tag $groupTag for event ${e.id.substring(0, 8)}", 
            name: "GroupFeedProvider");
        return true;
      }
    }
    
    // No match found - log detailed comparison for debugging
    if (eventGroupTags.isNotEmpty) {
      final eventGroupStr = eventGroupTags.join(', ');
      final userGroupStr = userGroups.map((g) => g.groupId).join(', ');
      log("❌ NO MATCH: Event ${e.id.substring(0, 8)} has tags [$eventGroupStr] but user has [$userGroupStr]", 
          name: "GroupFeedProvider");
    }
    
    return false;
  }

  void onEvent(Event event) {
    later(event, (list) {
      bool noteAdded = false;
      int processedCount = 0;
      int rejectedCount = 0;
      int validCount = 0;
      
      log("Processing batch of ${list.length} events", name: "GroupFeedProvider");

      for (var e in list) {
        processedCount++;
        
        // First check if it's a group note type
        if (!isGroupNote(e)) {
          log("Event ${e.id.substring(0, 8)} rejected: Not a group note (kind=${e.kind})", 
              name: "GroupFeedProvider");
          rejectedCount++;
          continue;
        }
        
        // Then check if it belongs to one of our groups
        if (!hasValidGroupTag(e)) {
          // hasValidGroupTag already logs detailed information
          rejectedCount++;
          continue;
        }
        
        // Event passed all checks, mark as valid
        validCount++;
        
        // Check if we already have this event
        if (notesBox.contains(e.id)) {
          log("Event ${e.id.substring(0, 8)} already in feed, skipping", 
              name: "GroupFeedProvider");
          continue;
        }
        
        // Add to the main notes box
        if (notesBox.add(e)) {
          noteAdded = true;
          log("✅ Added event ${e.id.substring(0, 8)} to feed", 
              name: "GroupFeedProvider");
          
          // Update static cache for persistence
          _staticEventCache[e.id] = e;
        } else {
          log("Failed to add event ${e.id.substring(0, 8)} to feed (already exists or error)", 
              name: "GroupFeedProvider");
        }
      }

      // Log batch processing summary
      log("Batch processing complete: ${processedCount} processed, ${validCount} valid, ${rejectedCount} rejected, ${noteAdded ? 'added to feed' : 'no new notes added'}", 
          name: "GroupFeedProvider");
          
      // Always sort if we added notes
      if (noteAdded) {
        notesBox.sort();
      }
      
      // Update loading state and notify listeners if needed
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
    log("🔄 Manual refresh initiated", name: "GroupFeedProvider");
    
    // Log current status of groups with more details
    final groupIds = _listProvider.groupIdentifiers;
    if (groupIds.isNotEmpty) {
      log("🔄 Refreshing with ${groupIds.length} groups:", name: "GroupFeedProvider");
      for (int i = 0; i < groupIds.length; i++) {
        final group = groupIds[i];
        log("  Group ${i+1}: ${group.groupId} at ${group.host}", name: "GroupFeedProvider");
      }
    } else {
      log("❌ No groups available to refresh - feed will be empty", name: "GroupFeedProvider");
    }
    
    // Log current state before clearing
    log("📊 Current feed state before refresh: ${notesBox.length()} notes in main box, ${newNotesBox.length()} notes in new box", 
        name: "GroupFeedProvider");
    
    // Set loading state first
    isLoading = true;
    notifyListeners();
    
    // Clear data with explanation
    log("🧹 Clearing all data (including cache) for fresh start", name: "GroupFeedProvider");
    clearData(preserveCache: false);
    
    // Reset initialization time to now
    final oldInitTime = _initTime;
    _initTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    log("⏱️ Reset initialization time from $oldInitTime to $_initTime", name: "GroupFeedProvider");
    
    // First unsubscribe to ensure clean state
    log("📡 Unsubscribing from all previous relays", name: "GroupFeedProvider");
    _unsubscribe();
    
    // Then resubscribe for new events
    log("📡 Setting up new subscriptions", name: "GroupFeedProvider");
    _subscribe();
    
    // Finally do the query for existing events
    log("🔍 Starting new query for historical events", name: "GroupFeedProvider");
    
    // IMPORTANT: Force a higher limit for the initial query to get more events
    log("🔍 FORCE QUERY WITH HIGHER LIMIT: Querying for ${groupIds.length} groups with limit=100", 
        name: "GroupFeedProvider");
        
    // Create filters with higher limits for better results
    final forcedFilters = groupIds.map((groupId) {
      final filter = Filter(
        until: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        kinds: [EventKind.groupNote, EventKind.groupNoteReply],
        // Use higher limit to ensure we get some results
        limit: 100,
      );
      final jsonMap = filter.toJson();
      jsonMap["#h"] = [groupId.groupId];
      return jsonMap;
    }).toList();
    
    // Try more relays for better results
    final relaysToTry = <String>{
      RelayProvider.defaultGroupsRelayAddress,
      'wss://nos.lol',
      'wss://relay.damus.io',
      'wss://relay.nostr.band',
      'wss://purplepag.es',
    };
    
    // Add unique hosts from group identifiers
    for (final groupId in groupIds) {
      relaysToTry.add(groupId.host);
    }
    
    log("🌐 FORCED QUERY: Will query ${relaysToTry.length} relays with limit=100", 
        name: "GroupFeedProvider");
    
    // Query all relays in our list
    for (final relay in relaysToTry) {
      try {
        log("🌐 FORCED QUERY: Querying relay $relay for all groups", 
            name: "GroupFeedProvider");
        nostr!.query(
          forcedFilters,
          onEvent,
          tempRelays: [relay],
          relayTypes: RelayType.onlyTemp,
          sendAfterAuth: true,
        );
      } catch (e) {
        log("❌ Error in forced query to relay $relay: $e", name: "GroupFeedProvider");
      }
    }
    
    // Also run standard query for backward compatibility
    doQuery(null);
    
    // Ensure we exit loading state after a timeout
    log("⏱️ Setting 5-second fallback timeout for loading indicator", name: "GroupFeedProvider");
    Future.delayed(const Duration(seconds: 5), () {
      if (isLoading) {
        log("⏱️ Fallback timeout reached in refresh, forcing loading=false", name: "GroupFeedProvider");
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
      log("No groups found, skipping subscription", name: "GroupFeedProvider");
      return;
    }

    log("Setting up subscriptions for ${groupIds.length} groups", name: "GroupFeedProvider");
    final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    
    // Create a filter for each group
    final filters = groupIds.map((groupId) {
      return {
        "kinds": [EventKind.groupNote, EventKind.groupNoteReply],
        "#h": [groupId.groupId],
        "since": currentTime
      };
    }).toList();

    // Try multiple relays for better reliability
    final relaysToTry = <String>{
      RelayProvider.defaultGroupsRelayAddress,  // Always include default relay
      'wss://nos.lol',                          // Include major Nostr relays
      'wss://relay.damus.io',
    };
    
    // Also add unique hosts from group identifiers
    for (final groupId in groupIds) {
      relaysToTry.add(groupId.host);
    }
    
    // Subscribe to the default relay for all groups
    try {
      log("Subscribing to default relay for all groups", name: "GroupFeedProvider");
      nostr!.subscribe(
        filters,
        _handleSubscriptionEvent,
        id: "${subscribeId}_default",
        relayTypes: [RelayType.temp],
        tempRelays: [RelayProvider.defaultGroupsRelayAddress],
        sendAfterAuth: true,
      );
    } catch (e) {
      log("Error in subscription to default relay: $e", name: "GroupFeedProvider");
    }
    
    // Subscribe to other major relays with all filters
    int relayIndex = 0;
    for (final relay in relaysToTry) {
      // Skip default relay as we already subscribed to it
      if (relay == RelayProvider.defaultGroupsRelayAddress) continue;
      
      relayIndex++;
      try {
        log("Subscribing to relay $relay for all groups", name: "GroupFeedProvider");
        nostr!.subscribe(
          filters,
          _handleSubscriptionEvent,
          id: "${subscribeId}_relay_$relayIndex",
          relayTypes: [RelayType.temp],
          tempRelays: [relay],
          sendAfterAuth: true,
        );
      } catch (e) {
        log("Error in subscription to relay $relay: $e", name: "GroupFeedProvider");
      }
    }
  }

  void _handleSubscriptionEvent(Event event) {
    later(event, (list) {
      int validEvents = 0;
      int rejectedEvents = 0;
      
      log("Subscription received ${list.length} new events", name: "GroupFeedProvider");
      
      for (final e in list) {
        // Check if it's a group note
        if (!isGroupNote(e)) {
          log("Subscription - Event ${e.id.substring(0, 8)} rejected: Not a group note (kind=${e.kind})", 
              name: "GroupFeedProvider");
          rejectedEvents++;
          continue;
        }
        
        // Check if it belongs to one of our groups
        if (!hasValidGroupTag(e)) {
          // hasValidGroupTag already logs detailed information
          rejectedEvents++;
          continue;
        }
        
        // Valid event, use onNewEvent to handle it
        log("Subscription - Valid event ${e.id.substring(0, 8)} passed to onNewEvent", 
            name: "GroupFeedProvider");
        onNewEvent(e);
        validEvents++;
      }
      
      // Log summary
      if (list.length > 0) {
        log("Subscription batch complete: ${list.length} received, ${validEvents} valid, ${rejectedEvents} rejected", 
            name: "GroupFeedProvider");
      }
    }, null);
  }

  void _unsubscribe() {
    try {
      log("Unsubscribing from all relays", name: "GroupFeedProvider");
      
      // Unsubscribe from default relay subscription
      try {
        nostr!.unsubscribe("${subscribeId}_default");
      } catch (e) {
        // Ignore errors for individual unsubscribes
      }
      
      // Unsubscribe from relay subscriptions by index
      for (int i = 1; i <= 20; i++) {  // Use a generous upper bound
        try {
          nostr!.unsubscribe("${subscribeId}_relay_$i");
        } catch (e) {
          // Ignore errors for individual unsubscribes
        }
      }
      
      _isSubscribed = false;
    } catch (e) {
      log("Error during unsubscribe: $e", name: "GroupFeedProvider");
    }
  }
}