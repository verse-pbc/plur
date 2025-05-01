import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/provider/group_read_status_provider.dart';
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
  final GroupReadStatusProvider? _readStatusProvider;
  final String subscribeId = StringUtil.rndNameStr(16);
  bool _isSubscribed = false;
  
  /// Indicates whether the provider is currently loading initial events
  bool isLoading = true;

  // Expose static cache for debugging access
  static final Map<String, Event> _staticEventCache = {};
  Map<String, Event> get staticEventCache => _staticEventCache;

  /// Get the read status provider
  GroupReadStatusProvider? get readStatusProvider => _readStatusProvider;

  GroupFeedProvider(this._listProvider, [this._readStatusProvider]) {
    _initTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    
    // Register our refresh callback with ListProvider instead of using static reference
    _listProvider.registerGroupsChangedCallback(refresh);
    
    // Initialize read status provider if provided
    if (_readStatusProvider != null) {
      _readStatusProvider!.init().then((_) {
        // Update counts from cache after read status provider is initialized
        if (!notesBox.isEmpty()) {
          log("Initializing read counts from cache after provider init", name: "GroupFeedProvider");
          updateAllGroupReadCounts();
        }
      });
    }
    
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
    // Unregister our callback from ListProvider
    _listProvider.unregisterGroupsChangedCallback();
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
          final idPart = event.id.length >= 8 ? event.id.substring(0, 8) : event.id;
          log("  Cache event ${idPart}: ${isValid ? 'VALID' : 'INVALID'}", 
              name: "GroupFeedProvider");
          
          if (isValid) {
            // Log more details about valid events
            final eventGroups = event.tags
                .where((tag) => tag is List && tag.isNotEmpty && tag.length > 1 && tag[0] == "h")
                .map((tag) => tag[1] as String)
                .toList();
                
            final idPart = event.id.length >= 8 ? event.id.substring(0, 8) : event.id;
            log("  ✅ Valid event ${idPart}, kind=${event.kind}, groups=[${eventGroups.join(', ')}]",
                name: "GroupFeedProvider");
            
            // Check if successfully added to notesBox
            if (notesBox.add(event)) {
              validCount++;
            } else {
              final idPart = event.id.length >= 8 ? event.id.substring(0, 8) : event.id;
              log("  ⚠️ Event ${idPart} not added to notesBox (duplicate?)",
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
      
      // Update read counts now that we have restored posts from cache
      if (_readStatusProvider != null) {
        log("Updating read counts after cache restoration with $validCount events", 
            name: "GroupFeedProvider");
            
        // First ensure read status provider is initialized
        _readStatusProvider!.init().then((_) {
          // Then update all group counts and force a notification
          updateAllGroupReadCounts();
          notifyListeners();
          
          // Log the updated counts for debugging
          _logReadCounts();
        });
      }
      
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
    
    // Comprehensive logging for debugging - safely truncate IDs that may be shorter
    final idPart = e.id.length >= 8 ? e.id.substring(0, 8) : e.id;
    final pubkeyPart = e.pubkey.length >= 8 ? e.pubkey.substring(0, 8) : e.pubkey;
    log("Checking event ${idPart} with kind ${e.kind} from ${pubkeyPart}", 
        name: "GroupFeedProvider");
    
    // Extract all h-tags from the event - these identify which group the event belongs to
    final eventGroupTags = e.tags
        .where((tag) => tag is List && tag.isNotEmpty && tag.length > 1 && tag[0] == "h")
        .map((tag) => tag[1] as String)
        .toList();
    
    // If event has no group tags, it can't belong to any group
    if (eventGroupTags.isEmpty) {
      final idPart = e.id.length >= 8 ? e.id.substring(0, 8) : e.id;
      log("Event ${idPart} has no h-tags, excluding from feed", 
          name: "GroupFeedProvider");
      return false;
    }
    
    // Log all the event's tags for debugging
    for (var tag in e.tags) {
      if (tag is List && tag.isNotEmpty) {
        final idPart = e.id.length >= 8 ? e.id.substring(0, 8) : e.id;
        log("Event ${idPart} has tag: ${tag.join(':')}",
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
        final idPart = e.id.length >= 8 ? e.id.substring(0, 8) : e.id;
        log("✅ MATCH FOUND: Group tag $groupTag for event ${idPart}", 
            name: "GroupFeedProvider");
        return true;
      }
    }
    
    // No match found - log detailed comparison for debugging
    if (eventGroupTags.isNotEmpty) {
      final eventGroupStr = eventGroupTags.join(', ');
      final userGroupStr = userGroups.map((g) => g.groupId).join(', ');
      final idPart = e.id.length >= 8 ? e.id.substring(0, 8) : e.id;
      log("❌ NO MATCH: Event ${idPart} has tags [$eventGroupStr] but user has [$userGroupStr]", 
          name: "GroupFeedProvider");
    }
    
    return false;
  }

  /// Gets the group identifier for an event by extracting the h tag
  GroupIdentifier? getEventGroup(Event e) {
    if (!isGroupNote(e)) return null;
    
    // Extract all h-tags from the event
    for (var tag in e.tags) {
      if (tag is List && tag.isNotEmpty && tag.length > 1 && tag[0] == "h") {
        final groupId = tag[1] as String;
        
        // Find matching group with host
        for (var identifier in _listProvider.groupIdentifiers) {
          if (identifier.groupId == groupId) {
            return identifier;
          }
        }
        
        // If no exact match found, use default relay
        return GroupIdentifier(
          RelayProvider.defaultGroupsRelayAddress,
          groupId
        );
      }
    }
    
    return null;
  }
  
  /// Updates the read status for all groups based on current posts
  void updateAllGroupReadCounts() {
    if (_readStatusProvider == null) return;
    
    // Process all group identifiers
    final groupIds = _listProvider.groupIdentifiers;
    for (final groupId in groupIds) {
      _updateGroupReadCount(groupId);
    }
  }
  
  /// Updates the read status for a specific group
  void _updateGroupReadCount(GroupIdentifier groupId) {
    if (_readStatusProvider == null) return;
    
    final posts = _getPostsForGroup(groupId);
    final lastReadTime = _readStatusProvider?.getLastReadTime(groupId) ?? 0;
    
    int totalPosts = posts.length;
    int unreadPosts = 0;
    
    // Count unread posts based on timestamp
    for (final event in posts) {
      if (event.createdAt > lastReadTime) {
        unreadPosts++;
      }
    }
    
    // Update the read status
    log("Updating read status for ${groupId.groupId}: total=$totalPosts, unread=$unreadPosts", 
        name: "GroupFeedProvider");
    _readStatusProvider?.updateCounts(groupId, totalPosts, unreadPosts);
  }
  
  /// Gets all posts for a specific group
  List<Event> _getPostsForGroup(GroupIdentifier groupId) {
    final result = <Event>[];
    
    // Check all posts in the main box
    for (final event in notesBox.all()) {
      if (_eventBelongsToGroup(event, groupId)) {
        result.add(event);
      }
    }
    
    // Also check new notes box
    for (final event in newNotesBox.all()) {
      if (_eventBelongsToGroup(event, groupId)) {
        result.add(event);
      }
    }
    
    return result;
  }
  
  /// Check if an event belongs to a specific group
  bool _eventBelongsToGroup(Event event, GroupIdentifier groupId) {
    for (var tag in event.tags) {
      if (tag is List && tag.length > 1 && tag[0] == "h" && tag[1] == groupId.groupId) {
        return true;
      }
    }
    return false;
  }
  
  /// Mark a group as read
  void markGroupRead(GroupIdentifier groupId) {
    if (_readStatusProvider == null) return;
    
    // Get current read info to check if we need to update
    final readInfo = _readStatusProvider!.getReadInfo(groupId);
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    
    // Check if the group was read very recently and has no unread posts
    // don't bother updating to avoid unnecessary UI rebuilds
    final lastReadTime = readInfo.lastReadTime;
    final unreadCount = readInfo.unreadCount;
    
    if (lastReadTime > now - 60 && unreadCount <= 0) { // read within the last minute
      log("Skipping markGroupRead for ${groupId.groupId}: recently read (${now - lastReadTime}s ago) with 0 unread", 
          name: "GroupFeedProvider");
      return;
    }
    
    log("Marking group ${groupId.groupId} as read", name: "GroupFeedProvider");
    _readStatusProvider!.markGroupRead(groupId);
    
    // Recalculate to ensure counts are accurate
    _updateGroupReadCount(groupId);
    notifyListeners();
  }

  /// Mark a group as viewed (without marking all as read)
  void markGroupViewed(GroupIdentifier groupId) {
    if (_readStatusProvider == null) return;
    
    // Get current read info to check if we need to update
    final readInfo = _readStatusProvider!.getReadInfo(groupId);
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    
    // Check if the group was viewed very recently, don't bother updating
    final lastViewedAt = readInfo.lastViewedAt;
    
    if (lastViewedAt > now - 60) { // within the last minute
      log("Skipping markGroupViewed for ${groupId.groupId}: recently viewed (${now - lastViewedAt}s ago)", 
          name: "GroupFeedProvider");
      return;
    }
    
    log("Marking group ${groupId.groupId} as viewed", name: "GroupFeedProvider");
    _readStatusProvider!.markGroupViewed(groupId);
    
    // Also update the counts to ensure they're accurate
    _updateGroupReadCount(groupId);
    notifyListeners();
  }
  
  void onEvent(Event event) {
    later(event, (list) {
      bool noteAdded = false;
      int processedCount = 0;
      int rejectedCount = 0;
      int validCount = 0;
      
      // Track affected groups for updating read status
      final Set<GroupIdentifier> affectedGroups = {};
      
      log("Processing batch of ${list.length} events", name: "GroupFeedProvider");

      for (var e in list) {
        processedCount++;
        
        // First check if it's a group note type
        if (!isGroupNote(e)) {
          final idPart = e.id.length >= 8 ? e.id.substring(0, 8) : e.id;
          log("Event ${idPart} rejected: Not a group note (kind=${e.kind})", 
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
          final idPart = e.id.length >= 8 ? e.id.substring(0, 8) : e.id;
          log("Event ${idPart} already in feed, skipping", 
              name: "GroupFeedProvider");
          continue;
        }
        
        // Add to the main notes box
        if (notesBox.add(e)) {
          noteAdded = true;
          final idPart = e.id.length >= 8 ? e.id.substring(0, 8) : e.id;
          log("✅ Added event ${idPart} to feed", 
              name: "GroupFeedProvider");
          
          // Update static cache for persistence
          _staticEventCache[e.id] = e;
          
          // Track which group this event belongs to
          final eventGroup = getEventGroup(e);
          if (eventGroup != null) {
            affectedGroups.add(eventGroup);
          }
        } else {
          final idPart = e.id.length >= 8 ? e.id.substring(0, 8) : e.id;
          log("Failed to add event ${idPart} to feed (already exists or error)", 
              name: "GroupFeedProvider");
        }
      }

      // Log batch processing summary
      log("Batch processing complete: ${processedCount} processed, ${validCount} valid, ${rejectedCount} rejected, ${noteAdded ? 'added to feed' : 'no new notes added'}", 
          name: "GroupFeedProvider");
          
      // Always sort if we added notes
      if (noteAdded) {
        notesBox.sort();
        
        // Update read status for affected groups
        if (_readStatusProvider != null && affectedGroups.isNotEmpty) {
          log("Updating read status for ${affectedGroups.length} affected groups", 
              name: "GroupFeedProvider");
          for (final groupId in affectedGroups) {
            _updateGroupReadCount(groupId);
          }
        }
      }
      
      // Update loading state and notify listeners if needed
      // Update all group read counts if we added new posts
      if (noteAdded && _readStatusProvider != null) {
        log("Updating all group read counts after processing new events", 
            name: "GroupFeedProvider");
        updateAllGroupReadCounts();
      }
      
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
    
    // Update read counts immediately with any cached data
    if (_readStatusProvider != null && !notesBox.isEmpty()) {
      log("🔄 Updating group read counts from cache immediately", 
          name: "GroupFeedProvider");
      updateAllGroupReadCounts();
    }
    
    // Set a delayed task to update read counts after query completes
    if (_readStatusProvider != null) {
      log("⏱️ Setting 6-second delayed task to update all group read counts", 
          name: "GroupFeedProvider");
      Future.delayed(const Duration(seconds: 6), () {
        updateAllGroupReadCounts();
      });
    }
    
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
      
      // Track affected groups for updating read status
      final Set<GroupIdentifier> affectedGroups = {};
      
      log("Subscription received ${list.length} new events", name: "GroupFeedProvider");
      
      for (final e in list) {
        // Check if it's a group note
        if (!isGroupNote(e)) {
          final idPart = e.id.length >= 8 ? e.id.substring(0, 8) : e.id;
          log("Subscription - Event ${idPart} rejected: Not a group note (kind=${e.kind})", 
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
        final idPart = e.id.length >= 8 ? e.id.substring(0, 8) : e.id;
        log("Subscription - Valid event ${idPart} passed to onNewEvent", 
            name: "GroupFeedProvider");
        onNewEvent(e);
        validEvents++;
        
        // Track affected group for this event
        final eventGroup = getEventGroup(e);
        if (eventGroup != null) {
          affectedGroups.add(eventGroup);
        }
      }
      
      // Update read status counts for affected groups
      if (_readStatusProvider != null && affectedGroups.isNotEmpty) {
        log("Subscription - Updating read status for ${affectedGroups.length} affected groups", 
            name: "GroupFeedProvider");
        for (final groupId in affectedGroups) {
          _updateGroupReadCount(groupId);
        }
      }
      
      // Log summary
      if (list.isNotEmpty) {
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
  
  /// Log the current read counts for all groups for debugging
  void _logReadCounts() {
    if (_readStatusProvider == null) return;
    
    final groupIds = _listProvider.groupIdentifiers;
    if (groupIds.isEmpty) {
      log("No groups found to log read counts", name: "GroupFeedProvider");
      return;
    }
    
    log("===== GROUP READ COUNTS =====", name: "GroupFeedProvider");
    for (final groupId in groupIds) {
      final readInfo = _readStatusProvider!.getReadInfo(groupId);
      log("Group ${groupId.groupId}: ${readInfo.postCount} posts, ${readInfo.unreadCount} unread", 
          name: "GroupFeedProvider");
    }
    log("==============================", name: "GroupFeedProvider");
  }
  
  /// Public method to force update all group read counts
  /// This can be called from UI in emergency situations when counts are missing
  void forceUpdateAllReadCounts({bool log = true}) {
    if (_readStatusProvider == null) {
      if (log) {
        debugPrint("⚠️ Cannot force update counts: readStatusProvider is null");
      }
      return;
    }
    
    if (log) {
      debugPrint("🔄 Forcing update of all group read counts...");
    }
    
    // First ensure read status provider is initialized
    _readStatusProvider!.init().then((_) {
      // Update the counts
      updateAllGroupReadCounts();
      
      // Notify listeners to ensure UI updates
      notifyListeners();
      
      if (log) {
        // Log the updated counts
        _logReadCounts();
        debugPrint("✅ Read count update complete");
      }
    });
  }
}