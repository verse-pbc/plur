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
import 'package:nostrmo/util/theme_util.dart';
import 'package:nostrmo/util/app_logger.dart';
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
    logger.d('Preloading content for global feed');
    
    // If we don't have a provider yet, try getting it
    if (groupFeedProvider == null || listProvider == null) {
      try {
        // First try to get GroupFeedProvider
        if (groupFeedProvider == null) {
          try {
            groupFeedProvider = Provider.of<GroupFeedProvider>(context, listen: false);
            logger.d('Retrieved GroupFeedProvider from context');
          } catch (e) {
            logger.w('GroupFeedProvider not available yet', e);
            // Schedule another attempt
            _scheduleRetry();
            return;
          }
        }
        
        // Then try to get ListProvider
        if (listProvider == null) {
          try {
            listProvider = Provider.of<ListProvider>(context, listen: false);
            logger.d('Retrieved ListProvider from context');
          } catch (e) {
            logger.w('ListProvider not available yet', e);
            // Schedule another attempt
            _scheduleRetry();
            return;
          }
        }
      } catch (e) {
        // Provider not ready yet, will try again later
        logger.e('Error getting providers', e);
        _scheduleRetry();
        return;
      }
    }
    
    // Check if group count has changed, which should force a refresh
    if (listProvider != null) {
      final currentGroupCount = listProvider!.groupIdentifiers.length;
      if (currentGroupCount != _lastGroupCount) {
        logger.i('Group count changed from $_lastGroupCount to $currentGroupCount, forcing refresh');
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
        logger.d('Initializing GroupFeedProvider');
      }
      
      // Always ensure we have posts
      if (groupFeedProvider!.notesBox.isEmpty()) {
        logger.d('No posts found in feed, initiating query');
        // Make sure we're subscribed and query for data
        groupFeedProvider!.subscribe();
        groupFeedProvider!.doQuery(null);
      } else {
        logger.d('Found ${groupFeedProvider!.notesBox.length()} existing posts in feed');
        
        // Even if we have events, check if groups changed
        if (listProvider != null && _hasGroupsChanged()) {
          logger.i('Groups have changed while we have events, forcing refresh');
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
      logger.i('🔄 FORCE RESTORE FROM CACHE: Attempting to restore ${provider.staticEventCache.length} events');
      
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
        
        // IMPORTANT: Call setState to update the UI
        if (mounted) {
          setState(() {}); // Trigger a UI update
        }
        
        logger.i('💾 CACHE RESTORATION COMPLETE: Added $validCount events, removed $invalidCount invalid events');
      } else {
        logger.w('⚠️ CACHE RESTORATION FAILED: Found no valid events in cache');
      }
    }
  }

  @override
  Widget doBuild(BuildContext context) {
    // We're using KeepAliveCustState which handles the keep-alive mixin
    
    // Log that this widget is being built/displayed
    logger.d('🔍 SCREEN DISPLAYED: AllGroupPostsWidget (Your Communities feed)');
    
    var settingsProvider = Provider.of<SettingsProvider>(context);
    final themeData = Theme.of(context);
    
    // Try to get the providers with error handling
    try {
      groupFeedProvider = Provider.of<GroupFeedProvider>(context);
    } catch (e) {
      logger.e('Error getting GroupFeedProvider', e);
      // Return a placeholder when the provider isn't ready
      return Container(
        color: themeData.scaffoldBackgroundColor,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    try {
      listProvider = Provider.of<ListProvider>(context);
    } catch (e) {
      logger.e('Error getting ListProvider', e);
      // Return a placeholder when the provider isn't ready
      return Container(
        color: themeData.scaffoldBackgroundColor,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    // Get current group count
    final currentGroupCount = listProvider?.groupIdentifiers.length ?? 0;
    
    // Check if group count changed, which should force a feed refresh
    if (currentGroupCount != _lastGroupCount) {
      logger.i('Group count changed from $_lastGroupCount to $currentGroupCount while building');
      _lastGroupCount = currentGroupCount;
      
      // Schedule a refresh for after this build completes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          logger.d('Triggering post-build refresh due to group count change');
          _forceRefresh();
        }
      });
    }
    
    // Log debug info to help diagnose feed issues
    _logDebugInfo();
    
    var eventBox = groupFeedProvider!.notesBox;
    var events = eventBox.all();
    
    // Log detailed event information
    logger.d('📊 EVENTS STATUS: Found ${events.length} events in the notesBox');
    logger.d('📊 GROUP STATUS: User belongs to ${listProvider?.groupIdentifiers.length ?? 0} groups');
    logger.d('📊 LOADING STATUS: groupFeedProvider.isLoading = ${groupFeedProvider!.isLoading}');
    
    // Force a query to ensure we have events
    if (events.isEmpty && !groupFeedProvider!.isLoading) {
      logger.i('🔄 FORCING QUERY: No events found in notesBox and not loading');
      
      // Check if we can restore from cache first
      final cacheSize = groupFeedProvider!.staticEventCache.length;
      if (cacheSize > 0) {
        logger.i('💾 ATTEMPTING CACHE RESTORATION: Found $cacheSize events in static cache');
        
        // Try to restore from cache right now (don't wait for post-frame)
        _forceRestoreFromCache();
        
        // Get updated event list after restoration
        events = eventBox.all();
        
        logger.i('💾 CACHE RESTORATION RESULT: Now have ${events.length} events in notesBox');
      }
      
      // If still empty after cache restoration, schedule a query
      if (events.isEmpty) {
        // Schedule query for after this build completes
        WidgetsBinding.instance.addPostFrameCallback((_) {
          groupFeedProvider!.doQuery(null);
        });
      }
    }
    
    // Verify that events belong to our groups
    if (events.isNotEmpty && listProvider != null && currentGroupCount > 0) {
      // Sanity check to ensure events match our groups
      final userGroupIds = {for (var group in listProvider!.groupIdentifiers) group.groupId: true};
      
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
      if (groupFeedProvider!.isLoading) {
        content = const Center(
          child: CircularProgressIndicator(),
        );
      } else {
        // Only show empty state when we've confirmed there are no events
        logger.w('⚠️ SHOWING NO NOTES WIDGET: No events found and not loading');
        
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
                        logger.i('👆 USER CLICKED: Force refresh feed button');
                        if (groupFeedProvider != null) {
                          groupFeedProvider!.refresh();
                        }
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
                        logger.i('👆 USER CLICKED: See My Communities button');
                        
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

      var newNotesLength = groupFeedProvider!.newNotesBox.length();
      if (newNotesLength <= 0) {
        content = main;
      } else {
        List<Widget> stackList = [main];
        stackList.add(Positioned(
          top: Base.basePadding,
          child: NewNotesUpdatedWidget(
            num: newNotesLength,
            onTap: () {
              groupFeedProvider!.mergeNewEvent();
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
    
    logger.d('🔍 Validating ${events.length} events in the feed against ${userGroupIds.length} user groups');
        
    // Log the user's groups for reference
    if (userGroupIds.isNotEmpty) {
      final groupsList = userGroupIds.keys.toList();
      logger.d('👤 User belongs to these groups: ${groupsList.join(', ')}');
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
          logger.w('❌ Event ${event.id.substring(0, 8)} belongs to groups [${eventGroups.join(', ')}] but user is not in these groups');
        } else {
          logger.w('❌ Event ${event.id.substring(0, 8)} has no group tags');
        }
      }
    }
    
    // Log summary
    logger.d('📊 Validation complete: $validEvents valid events, $invalidEvents invalid events');
        
    // Log events per group
    if (groupCounts.isNotEmpty) {
      logger.d('📊 Events per group:');
      groupCounts.forEach((groupId, count) {
        logger.d('  Group $groupId: $count events');
      });
    }
    
    // Check for missing groups (user groups with no events)
    if (userGroupIds.isNotEmpty) {
      final missingGroups = userGroupIds.keys.where((groupId) => !groupCounts.containsKey(groupId)).toList();
      if (missingGroups.isNotEmpty) {
        logger.w('⚠️ WARNING: ${missingGroups.length} groups have no events in the feed: ${missingGroups.join(', ')}');
      }
    }
    
    // If more than half the events are invalid, force a refresh
    if (invalidEvents > validEvents && events.isNotEmpty && mounted) {
      logger.w('⚠️ Too many invalid events (>50%), forcing refresh');
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
      logger.d('onReady called, initializing widget');
      
      // Force initialize to ensure we have content
      try {
        // Try to get GroupFeedProvider if we don't have it
        if (groupFeedProvider == null) {
          try {
            groupFeedProvider = Provider.of<GroupFeedProvider>(context, listen: false);
            logger.d('Successfully retrieved GroupFeedProvider');
          } catch (e) {
            logger.e('Failed to get GroupFeedProvider', e);
            // Schedule a retry and return early
            _scheduleProviderRetry(context);
            return;
          }
        }
        
        // Try to get ListProvider if we don't have it
        if (listProvider == null) {
          try {
            listProvider = Provider.of<ListProvider>(context, listen: false);
            logger.d('Successfully retrieved ListProvider');
          } catch (e) {
            logger.e('Failed to get ListProvider', e);
            // Schedule a retry and return early
            _scheduleProviderRetry(context);
            return;
          }
        }
        
        // Get current group count
        if (listProvider != null) {
          _lastGroupCount = listProvider!.groupIdentifiers.length;
          logger.d('Updated last group count to $_lastGroupCount');
        }
        
        // Force a query to ensure we have data
        if (groupFeedProvider != null && groupFeedProvider!.notesBox.isEmpty()) {
          logger.d('onReady: Initializing feed with subscribe and query');
          groupFeedProvider!.subscribe();
          groupFeedProvider!.doQuery(null);
        } else if (groupFeedProvider != null) {
          logger.d('onReady: Feed already has data, ensuring subscription is active');
          groupFeedProvider!.subscribe();
        }
      } catch (e) {
        logger.e('Error initializing feed', e);
        // Schedule a retry after a short delay
        _scheduleProviderRetry(context);
      }
    }
  }
  
  void _scheduleProviderRetry(BuildContext context) {
    // Only schedule if we're still mounted
    if (!mounted) return;
    
    // Store the context locally
    final currentContext = context;
    
    logger.d('Scheduling provider initialization retry in 1 second');
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        logger.d('Executing scheduled provider initialization retry');
        // Get a fresh context or use setState to trigger a rebuild
        setState(() {
          // This will cause a rebuild with a fresh context
        });
      }
    });
  }

  Future<void> onRefresh() async {
    logger.d('Manual refresh requested');
    
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
  
  // Schedule a retry for provider initialization
  void _scheduleRetry() {
    if (!mounted) return;
    
    logger.d('Scheduling provider retry in 500ms');
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        logger.d('Executing scheduled retry for provider initialization');
        _preloadContent();
      }
    });
  }

  // Helper method for debugging that you can call from doBuild
  void _logDebugInfo() {
    if (groupFeedProvider != null && listProvider != null) {
      final provider = groupFeedProvider!;
      
      logger.d('🔄 FEED DEBUG INFO:');
      
      // Log feed provider stats
      logger.d('📊 Event counts - main box: ${provider.notesBox.length()}, new events box: ${provider.newNotesBox.length()}');
      
      // Log loading state  
      logger.d('🔄 Loading state: ${provider.isLoading ? 'LOADING' : 'READY'}');
      
      // Log static cache info
      logger.d('💾 Static cache size: ${provider.staticEventCache.length} events');
          
      // Log group information
      final groups = listProvider!.groupIdentifiers;
      logger.d('👥 User belongs to ${groups.length} groups:');
      
      if (groups.isNotEmpty) {
        for (int i = 0; i < groups.length; i++) {
          final group = groups[i];
          logger.d('  Group ${i+1}: ${group.groupId} at ${group.host}');
        }
      }
      
      // Show a few sample events from the feed for debugging
      if (provider.notesBox.length() > 0) {
        logger.d('📝 Sample events in feed:');
        final events = provider.notesBox.all();
        final sampleSize = events.length > 3 ? 3 : events.length;
        
        for (int i = 0; i < sampleSize; i++) {
          final event = events[i];
          final eventGroups = event.tags
              .where((tag) => tag is List && tag.isNotEmpty && tag.length > 1 && tag[0] == "h")
              .map((tag) => tag[1] as String)
              .toList();
          
          logger.d('  Event ${i+1}: ${event.id.substring(0, 8)}, kind=${event.kind}, groups=[${eventGroups.join(', ')}]');
        }
      } else if (!provider.isLoading) {
        logger.w('⚠️ No events in feed despite not being in loading state!');
        
        // Check if there are events in static cache despite empty notesBox
        if (provider.staticEventCache.isNotEmpty) {
          logger.w('⚠️ FOUND ${provider.staticEventCache.length} EVENTS IN STATIC CACHE but notesBox is empty!');
          
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
                  
              logger.d('  Cache Event ${count+1}: ${cacheEvent.id.substring(0, 8)}, kind=${cacheEvent.kind}, groups=[${eventGroups.join(', ')}]');
              count++;
            }
          }
          
          // Check if these events are valid by testing against hasValidGroupTag
          logger.d('🔍 Checking if cache events would pass hasValidGroupTag validation:');
              
          int validCount = 0;
          for (var eventId in provider.staticEventCache.keys) {
            final cacheEvent = provider.staticEventCache[eventId];
            if (cacheEvent != null && provider.hasValidGroupTag(cacheEvent)) {
              validCount++;
            }
          }
          
          logger.d('✅ ${validCount} out of ${provider.staticEventCache.length} cache events pass validation');
              
          if (validCount > 0) {
            logger.d("🔄 Cache contains valid events but they're not in notesBox. Try refreshing.");
          }
        }
      }
    } else {
      logger.w('⚠️ Cannot log debug info - providers not available');
    }
  }
}