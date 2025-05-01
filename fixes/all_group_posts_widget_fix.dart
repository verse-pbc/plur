import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/component/event/group_event_list_widget.dart';
import 'package:nostrmo/component/keep_alive_cust_state.dart';
import 'package:nostrmo/component/new_notes_updated_widget.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/consts/base_consts.dart';
import 'package:nostrmo/provider/group_feed_provider.dart';
import 'package:nostrmo/provider/index_provider.dart';
import 'package:nostrmo/provider/list_provider.dart';
import 'package:nostrmo/provider/settings_provider.dart';
import 'package:nostrmo/router/group/no_notes_widget.dart';
import 'package:nostrmo/util/theme_util.dart';
import 'package:provider/provider.dart';

class AllGroupPostsWidget extends StatefulWidget {
  const AllGroupPostsWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return _AllGroupPostsWidgetState();
  }
}

class _AllGroupPostsWidgetState extends KeepAliveCustState<AllGroupPostsWidget> {
  final ScrollController scrollController = ScrollController();

  GroupFeedProvider? groupFeedProvider;
  ListProvider? listProvider;
  
  // Add cached widgets for improved performance
  static Widget? _cachedContentWidget;
  static List<String>? _cachedEventIds;
  static bool _isInitialized = false;
  
  // Keep track of visible events to avoid unnecessary rebuilds
  final Set<String> _visibleEventIds = {};
  
  // Record the last group count we processed to detect changes
  static int _lastGroupCount = 0;
  
  @override
  bool get wantKeepAlive => true;
  
  @override
  void initState() {
    super.initState();
    
    // Preload content 
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Preload on init
      _preloadContent();
    });
  }
  
  void _preloadContent() {
    log("Preloading content for global feed", name: "AllGroupPostsWidget");
    
    // If we don't have a provider yet, try getting it
    if (groupFeedProvider == null || listProvider == null) {
      try {
        groupFeedProvider = Provider.of<GroupFeedProvider>(context, listen: false);
        listProvider = Provider.of<ListProvider>(context, listen: false);
        log("Retrieved providers from context", name: "AllGroupPostsWidget");
      } catch (e) {
        // Provider not ready yet, will try again later
        log("Error getting providers: $e", name: "AllGroupPostsWidget");
        return;
      }
    }
    
    // Check if group count has changed, which should force a refresh
    if (listProvider != null) {
      final currentGroupCount = listProvider!.groupIdentifiers.length;
      if (currentGroupCount != _lastGroupCount) {
        log("Group count changed from $_lastGroupCount to $currentGroupCount, forcing refresh",
            name: "AllGroupPostsWidget");
        _lastGroupCount = currentGroupCount;
        
        // Clear the cached content when groups change to ensure we rebuild
        _cachedContentWidget = null;
        _cachedEventIds = null;
      }
    }
    
    // Always initialize to ensure we have data
    if (groupFeedProvider != null) {
      if (!_isInitialized) {
        _isInitialized = true;
        log("Initializing GroupFeedProvider", name: "AllGroupPostsWidget");
      }
      
      // Always ensure we have posts
      if (groupFeedProvider!.notesBox.isEmpty()) {
        log("No posts found in feed, initiating query", name: "AllGroupPostsWidget");
        // Make sure we're subscribed and query for data
        groupFeedProvider!.subscribe();
        groupFeedProvider!.doQuery(null);
      } else {
        log("Found ${groupFeedProvider!.notesBox.length()} existing posts in feed", 
            name: "AllGroupPostsWidget");
        
        // Even if we have events, check if groups changed
        if (listProvider != null && _hasGroupsChanged()) {
          log("Groups have changed while we have events, forcing refresh", 
              name: "AllGroupPostsWidget");
          // Force a refresh to ensure we have events from all current groups
          _forceRefresh();
        }
      }
    }
  }
  
  bool _hasGroupsChanged() {
    if (listProvider == null) return false;
    
    final currentGroups = listProvider!.groupIdentifiers;
    return currentGroups.length != _lastGroupCount;
  }
  
  void _forceRefresh() {
    if (groupFeedProvider == null) return;
    
    // Update group count
    if (listProvider != null) {
      _lastGroupCount = listProvider!.groupIdentifiers.length;
    }
    
    // Clear cache and refresh
    _cachedContentWidget = null;
    _cachedEventIds = null;
    
    // Refresh data from provider
    groupFeedProvider!.refresh();
  }
  
  /// Force restore events from static cache to notesBox
  void _forceRestoreFromCache() {
    if (groupFeedProvider == null || listProvider == null) return;
    
    final provider = groupFeedProvider!;
    
    // Only proceed if notesBox is empty but cache has events
    if (provider.notesBox.isEmpty() && provider.staticEventCache.isNotEmpty) {
      log("🔄 FORCE RESTORE FROM CACHE: Attempting to restore ${provider.staticEventCache.length} events", 
          name: "AllGroupPostsWidget");
      
      int validCount = 0;
      int invalidCount = 0;
      
      // Make a copy of the keys to avoid concurrent modification issues
      final cachedIds = provider.staticEventCache.keys.toList();
      
      // Process each event in the cache
      for (var id in cachedIds) {
        final event = provider.staticEventCache[id];
        if (event != null) {
          // Check if event belongs to one of our groups
          if (provider.hasValidGroupTag(event)) {
            // Add to notesBox if valid
            if (provider.notesBox.add(event)) {
              validCount++;
            }
          } else {
            // Don't remove invalid events from cache here - that should happen in the provider
            invalidCount++;
          }
        }
      }
      
      // Sort the notesBox after adding events
      if (validCount > 0) {
        provider.notesBox.sort();
        
        // IMPORTANT: Notify listeners to update the UI
        provider.notifyListeners();
        
        log("💾 CACHE RESTORATION COMPLETE: Added $validCount events, removed $invalidCount invalid events", 
            name: "AllGroupPostsWidget");
      } else {
        log("⚠️ CACHE RESTORATION FAILED: Found no valid events in cache", 
            name: "AllGroupPostsWidget");
      }
    }
  }

  @override
  Widget doBuild(BuildContext context) {
    // We're using KeepAliveCustState which handles the keep-alive mixin
    
    // Log that this widget is being built/displayed
    debugPrint("🔍 SCREEN DISPLAYED: AllGroupPostsWidget (Your Communities feed)");
    
    var settingsProvider = Provider.of<SettingsProvider>(context);
    
    // Safely access providers
    var feedProvider = Provider.of<GroupFeedProvider>(context);
    var listProvider = Provider.of<ListProvider>(context);
    
    // Store references for later use
    groupFeedProvider = feedProvider;
    this.listProvider = listProvider;
    
    final themeData = Theme.of(context);
    
    // Get current group count
    final currentGroupCount = listProvider.groupIdentifiers.length;
    
    // Check if group count changed, which should force a feed refresh
    if (currentGroupCount != _lastGroupCount) {
      log("Group count changed from $_lastGroupCount to $currentGroupCount while building",
          name: "AllGroupPostsWidget");
      _lastGroupCount = currentGroupCount;
      
      // Schedule a refresh for after this build completes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          log("Triggering post-build refresh due to group count change", 
              name: "AllGroupPostsWidget");
          _forceRefresh();
        }
      });
    }
    
    // Log debug info to help diagnose feed issues
    _logDebugInfo();
    
    var eventBox = feedProvider.notesBox;
    var events = eventBox.all();
    
    // Log detailed event information
    log("📊 EVENTS STATUS: Found ${events.length} events in the notesBox", name: "AllGroupPostsWidget");
    log("📊 GROUP STATUS: User belongs to ${listProvider.groupIdentifiers.length} groups", name: "AllGroupPostsWidget");
    log("📊 LOADING STATUS: groupFeedProvider.isLoading = ${feedProvider.isLoading}", name: "AllGroupPostsWidget");
    
    // Force a query to ensure we have events
    if (events.isEmpty && !feedProvider.isLoading) {
      log("🔄 FORCING QUERY: No events found in notesBox and not loading", name: "AllGroupPostsWidget");
      
      // Check if we can restore from cache first
      final cacheSize = feedProvider.staticEventCache.length;
      if (cacheSize > 0) {
        log("💾 ATTEMPTING CACHE RESTORATION: Found $cacheSize events in static cache", 
            name: "AllGroupPostsWidget");
        
        // Try to restore from cache right now (don't wait for post-frame)
        _forceRestoreFromCache();
        
        // Get updated event list after restoration
        events = eventBox.all();
        
        log("💾 CACHE RESTORATION RESULT: Now have ${events.length} events in notesBox", 
            name: "AllGroupPostsWidget");
      }
      
      // If still empty after cache restoration, schedule a query
      if (events.isEmpty) {
        // Schedule query for after this build completes
        WidgetsBinding.instance.addPostFrameCallback((_) {
          feedProvider.doQuery(null);
        });
      }
    }
    
    // Verify that events belong to our groups
    if (events.isNotEmpty && currentGroupCount > 0) {
      // Sanity check to ensure events match our groups
      final userGroupIds = {for (var group in listProvider.groupIdentifiers) group.groupId: true};
      
      // Log validation results
      _validateEvents(events, userGroupIds);
    }
    
    // Check if events have changed since last render
    final currentEventIds = events.map((e) => e.id).toList();
    final hasEventsChanged = _cachedEventIds == null || 
                             _cachedEventIds!.length != currentEventIds.length ||
                             !_cachedEventIds!.every(currentEventIds.contains);
    
    // If events haven't changed and we have a cached widget, return it
    if (!hasEventsChanged && _cachedContentWidget != null) {
      return Container(
        color: themeData.customColors.feedBgColor,
        child: _cachedContentWidget!,
      );
    }
    
    // Update cached event IDs
    _cachedEventIds = currentEventIds;

    Widget content;
    // Check if there are posts or if we're still loading 
    if (events.isEmpty) {
      // Show loading indicator instead of empty state initially
      if (feedProvider.isLoading) {
        content = const Center(
          child: CircularProgressIndicator(),
        );
      } else {
        // Only show empty state when we've confirmed there are no events
        log("⚠️ SHOWING NO NOTES WIDGET: No events found and not loading", name: "AllGroupPostsWidget");
        
        // Create a custom empty state message with refresh button
        content = Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Posts from all of your communities!",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: themeData.textTheme.bodyLarge?.color,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  "This page will show you all posts across every community you're a part of. Join more communities and you'll see active posts here.",
                  style: TextStyle(
                    fontSize: 16,
                    color: themeData.textTheme.bodyMedium?.color,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // Use Column instead of Row to avoid overflow
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: themeData.colorScheme.onPrimary,
                        backgroundColor: themeData.colorScheme.primary,
                        minimumSize: const Size(200, 40), // Fixed width
                      ),
                      onPressed: () {
                        log("👆 USER CLICKED: Force refresh feed button", name: "AllGroupPostsWidget");
                        _forceRefresh();
                      },
                      child: const Text("Refresh Feed"),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: themeData.colorScheme.onPrimary,
                        backgroundColor: themeData.colorScheme.primary,
                        minimumSize: const Size(200, 40), // Fixed width
                      ),
                      onPressed: () {
                        // Just use a simpler navigation approach
                        log("👆 USER CLICKED: See My Communities button", name: "AllGroupPostsWidget");
                        
                        // Directly update the tab selection in a way that doesn't depend on context
                        IndexProvider.setGlobalViewModeToGrid();
                      },
                      child: const Text("See My Communities"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }
    } else {
      // We have events to show
      var main = RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView.builder(
          padding: EdgeInsets.zero,
          controller: scrollController,
          // Add caching for better performance
          cacheExtent: 500, // Cache more items to reduce rebuilds
          itemBuilder: (context, index) {
            var event = events[index];
            // Track visible events
            _visibleEventIds.add(event.id);
            return RepaintBoundary(
              child: GroupEventListWidget(
                event: event,
                showVideo: settingsProvider.videoPreviewInList != OpenStatus.close,
                key: ValueKey(event.id), // Add key for better recycling
              ),
            );
          },
          itemCount: events.length,
        ),
      );

      var newNotesLength = feedProvider.newNotesBox.length();
      if (newNotesLength <= 0) {
        content = main;
      } else {
        List<Widget> stackList = [main];
        stackList.add(Positioned(
          top: Base.basePadding,
          child: NewNotesUpdatedWidget(
            num: newNotesLength,
            onTap: () {
              feedProvider.mergeNewEvent();
              scrollController.jumpTo(0);
            },
          ),
        ));
        content = Stack(
          alignment: Alignment.center,
          children: stackList,
        );
      }
    }
    
    // Cache the content widget for future use
    _cachedContentWidget = content;

    return Container(
      color: themeData.customColors.feedBgColor,
      child: content,
    );
  }
  
  void _validateEvents(List<Event> events, Map<String, bool> userGroupIds) {
    int validEvents = 0;
    int invalidEvents = 0;
    Map<String, int> groupCounts = {}; // Track which groups have events
    
    log("🔍 Validating ${events.length} events in the feed against ${userGroupIds.length} user groups", 
        name: "AllGroupPostsWidget");
        
    // Log the user's groups for reference
    if (userGroupIds.isNotEmpty) {
      final groupsList = userGroupIds.keys.toList();
      log("👤 User belongs to these groups: ${groupsList.join(', ')}", 
          name: "AllGroupPostsWidget");
    }
    
    for (var event in events) {
      bool isValid = false;
      // Track which group(s) this event belongs to
      List<String> eventGroups = [];
      
      // Extract all h-tags
      for (var tag in event.tags) {
        if (tag is List && tag.isNotEmpty && tag.length > 1 && tag[0] == "h") {
          final groupId = tag[1];
          eventGroups.add(groupId);
          
          // Check if this group ID is in the user's groups
          if (userGroupIds.containsKey(groupId)) {
            isValid = true;
            // Increment counter for this group
            groupCounts[groupId] = (groupCounts[groupId] ?? 0) + 1;
          }
        }
      }
      
      if (isValid) {
        validEvents++;
      } else {
        invalidEvents++;
        // Log the mismatch in detail
        if (eventGroups.isNotEmpty) {
          log("❌ Event ${event.id.substring(0, 8)} belongs to groups [${eventGroups.join(', ')}] but user is not in these groups", 
              name: "AllGroupPostsWidget");
        } else {
          log("❌ Event ${event.id.substring(0, 8)} has no group tags", 
              name: "AllGroupPostsWidget");
        }
      }
    }
    
    // Log summary
    log("📊 Validation complete: $validEvents valid events, $invalidEvents invalid events", 
        name: "AllGroupPostsWidget");
        
    // Log events per group
    if (groupCounts.isNotEmpty) {
      log("📊 Events per group:", name: "AllGroupPostsWidget");
      groupCounts.forEach((groupId, count) {
        log("  Group $groupId: $count events", name: "AllGroupPostsWidget");
      });
    }
    
    // Check for missing groups (user groups with no events)
    if (userGroupIds.isNotEmpty) {
      final missingGroups = userGroupIds.keys.where((groupId) => !groupCounts.containsKey(groupId)).toList();
      if (missingGroups.isNotEmpty) {
        log("⚠️ WARNING: ${missingGroups.length} groups have no events in the feed: ${missingGroups.join(', ')}", 
            name: "AllGroupPostsWidget");
      }
    }
    
    // If more than half the events are invalid, force a refresh
    if (invalidEvents > validEvents && events.isNotEmpty && mounted) {
      log("⚠️ Too many invalid events (>50%), forcing refresh", name: "AllGroupPostsWidget");
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _forceRefresh();
        }
      });
    }
  }

  @override
  Future<void> onReady(BuildContext context) async {
    // Mark as initialized but don't reinitialize the provider
    // The provider should already be initialized by CommunitiesScreen
    if (!_isInitialized) {
      _isInitialized = true;
      
      // Force initialize to ensure we have content
      try {
        if (groupFeedProvider == null) {
          groupFeedProvider = Provider.of<GroupFeedProvider>(context, listen: false);
        }
        
        if (listProvider == null) {
          listProvider = Provider.of<ListProvider>(context, listen: false);
        }
        
        // Get current group count
        if (listProvider != null) {
          _lastGroupCount = listProvider!.groupIdentifiers.length;
        }
        
        // Force a query to ensure we have data
        if (groupFeedProvider != null && groupFeedProvider!.notesBox.isEmpty()) {
          log("onReady: Initializing feed with subscribe and query", name: "AllGroupPostsWidget");
          groupFeedProvider!.subscribe();
          groupFeedProvider!.doQuery(null);
        } else if (groupFeedProvider != null) {
          log("onReady: Feed already has data, ensuring subscription is active", 
              name: "AllGroupPostsWidget");
          groupFeedProvider!.subscribe();
        }
      } catch (e) {
        log("Error initializing feed: $e", name: "AllGroupPostsWidget");
      }
    }
  }

  Future<void> onRefresh() async {
    log("Manual refresh requested", name: "AllGroupPostsWidget");
    
    // Clear content cache when refreshing
    _cachedContentWidget = null;
    _cachedEventIds = null;
    
    // Update group count if needed
    if (listProvider != null) {
      _lastGroupCount = listProvider!.groupIdentifiers.length;
    }
    
    // Request fresh data
    if (groupFeedProvider != null) {
      // Make sure we're subscribed
      groupFeedProvider!.subscribe();
      // Force a fresh query
      groupFeedProvider!.refresh();
    }
  }
  
  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }
  
  // Helper method for debugging that you can call from doBuild
  void _logDebugInfo() {
    if (groupFeedProvider != null && listProvider != null) {
      final provider = groupFeedProvider!;
      
      log("🔄 FEED DEBUG INFO:", name: "AllGroupPostsWidget");
      
      // Log feed provider stats
      log("📊 Event counts - main box: ${provider.notesBox.length()}, new events box: ${provider.newNotesBox.length()}", 
          name: "AllGroupPostsWidget");
      
      // Log loading state  
      log("🔄 Loading state: ${provider.isLoading ? 'LOADING' : 'READY'}", 
          name: "AllGroupPostsWidget");
      
      // Log static cache info
      log("💾 Static cache size: ${provider.staticEventCache.length} events", 
          name: "AllGroupPostsWidget");
          
      // Log group information
      final groups = listProvider!.groupIdentifiers;
      log("👥 User belongs to ${groups.length} groups:", name: "AllGroupPostsWidget");
      
      if (groups.isNotEmpty) {
        for (int i = 0; i < groups.length; i++) {
          final group = groups[i];
          log("  Group ${i+1}: ${group.groupId} at ${group.host}", 
              name: "AllGroupPostsWidget");
        }
      }
      
      // Show a few sample events from the feed for debugging
      if (provider.notesBox.length() > 0) {
        log("📝 Sample events in feed:", name: "AllGroupPostsWidget");
        final events = provider.notesBox.all();
        final sampleSize = events.length > 3 ? 3 : events.length;
        
        for (int i = 0; i < sampleSize; i++) {
          final event = events[i];
          final eventGroups = event.tags
              .where((tag) => tag is List && tag.isNotEmpty && tag.length > 1 && tag[0] == "h")
              .map((tag) => tag[1] as String)
              .toList();
          
          log("  Event ${i+1}: ${event.id.substring(0, 8)}, kind=${event.kind}, groups=[${eventGroups.join(', ')}]", 
              name: "AllGroupPostsWidget");
        }
      } else if (!provider.isLoading) {
        log("⚠️ No events in feed despite not being in loading state!", 
            name: "AllGroupPostsWidget");
        
        // Check if there are events in static cache despite empty notesBox
        if (provider.staticEventCache.isNotEmpty) {
          log("⚠️ FOUND ${provider.staticEventCache.length} EVENTS IN STATIC CACHE but notesBox is empty!", 
              name: "AllGroupPostsWidget");
              
          // Log some sample events from the static cache
          int count = 0;
          for (var eventId in provider.staticEventCache.keys) {
            if (count >= 3) break;
            final cacheEvent = provider.staticEventCache[eventId];
            if (cacheEvent != null) {
              final eventGroups = cacheEvent.tags
                  .where((tag) => tag is List && tag.isNotEmpty && tag.length > 1 && tag[0] == "h")
                  .map((tag) => tag[1] as String)
                  .toList();
                  
              log("  Cache Event ${count+1}: ${cacheEvent.id.substring(0, 8)}, kind=${cacheEvent.kind}, groups=[${eventGroups.join(', ')}]", 
                  name: "AllGroupPostsWidget");
              count++;
            }
          }
          
          // Check if these events are valid by testing against hasValidGroupTag
          log("🔍 Checking if cache events would pass hasValidGroupTag validation:", 
              name: "AllGroupPostsWidget");
              
          int validCount = 0;
          for (var eventId in provider.staticEventCache.keys) {
            final cacheEvent = provider.staticEventCache[eventId];
            if (cacheEvent != null && provider.hasValidGroupTag(cacheEvent)) {
              validCount++;
            }
          }
          
          log("✅ ${validCount} out of ${provider.staticEventCache.length} cache events pass validation",
              name: "AllGroupPostsWidget");
              
          if (validCount > 0) {
            log("🔄 Cache contains valid events but they're not in notesBox. Try refreshing.",
                name: "AllGroupPostsWidget");
          }
        }
      }
    } else {
      log("⚠️ Cannot log debug info - providers not available", 
          name: "AllGroupPostsWidget");
    }
  }
}