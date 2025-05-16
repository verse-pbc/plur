import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/provider/group_feed_provider.dart';
import 'package:nostrmo/provider/group_providers.dart';
import 'package:nostrmo/provider/group_read_status_provider.dart';
import 'package:nostrmo/provider/index_provider.dart';
import 'package:nostrmo/provider/list_provider.dart';
import 'package:nostrmo/router/group/communities_feed_widget.dart';
import 'package:nostrmo/router/group/no_communities_widget.dart';
// Import Provider package with an alias to avoid conflicts
import 'package:provider/provider.dart' as provider;

import '../../component/shimmer/shimmer.dart';
import 'package:nostrmo/theme/app_colors.dart';
import '../features/communities/communities_controller.dart';
import '../features/communities/communities_grid_widget.dart';
import '../features/communities/communities_list_widget.dart';

class CommunitiesScreen extends ConsumerStatefulWidget {
  const CommunitiesScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _CommunitiesScreenState();
  }
}

class _CommunitiesScreenState extends ConsumerState<CommunitiesScreen> with AutomaticKeepAliveClientMixin {
  final subscribeId = StringUtil.rndNameStr(16);
  
  // Cache for view mode state
  static CommunityViewMode? _lastViewMode;
  
  // Flag to prevent duplicate initialization 
  static bool _globalInitializationDone = false;
  

  @override
  void dispose() {
    // We don't need to clean up provider references as we're using the Provider
    // system properly, which will handle disposal for us
    super.dispose();
  }
  
  // Properly initialize feed provider with appropriate provider tree
  void _initializeFeedProvider() {
    // Safely initialize using proper provider dependency mechanisms
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        try {
          // First access the ListProvider from context
          final listProvider = provider.Provider.of<ListProvider>(context, listen: false);
          
          // Access the GroupReadStatusProvider from context
          final readStatusProvider = context.read<GroupReadStatusProvider>();
          
          // Ensure the read status provider is initialized
          readStatusProvider.init().then((_) {
            // Get the GroupFeedProvider
            final feedProvider = provider.Provider.of<GroupFeedProvider>(context, listen: false);
            
            // Initialize the group feed provider only if needed
            if (feedProvider.notesBox.isEmpty()) {
              debugPrint("🔄 Initializing feed provider - subscribing and querying");
              feedProvider.subscribe();
              feedProvider.doQuery(null);
            } else {
              debugPrint("🔄 Feed provider has data - updating counts");
              // Update counts from existing data
              feedProvider.updateAllGroupReadCounts();
            }
            
            // Always mark as initialized
            _globalInitializationDone = true;
          });
        } catch (e) {
          debugPrint("Error getting providers: $e");
        }
      }
    });
  }
  
  // Persistent cached widgets that survive rebuild cycles
  static Widget? _cachedGridWidget;
  static Widget? _cachedListWidget;
  static Widget? _cachedFeedWidget;
  static Widget? _cachedEmptyWidget;
  
  // Pre-built loading widget for faster display
  final Widget _loadingWidget = const Center(child: CircularProgressIndicator());
  
  @override
  bool get wantKeepAlive => true;
  
  @override
  void initState() {
    super.initState();
    
    // Always preload on init to ensure data is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preloadData();
    });
  }
  
  // Initialize on first build
  void _preloadData() {
    if (context.mounted && !_globalInitializationDone) {
      try {
        // Initialize feed provider
        _initializeFeedProvider();
      } catch (e) {
        // Ignore provider errors during initialization
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Must call super for AutomaticKeepAliveClientMixin
    super.build(context);
    
    final themeData = Theme.of(context);
    final appBgColor = context.colors.background;
    final separatorColor = context.colors.divider;
    final shimmerGradient = LinearGradient(
      colors: [separatorColor, appBgColor, separatorColor],
      stops: const [0.1, 0.3, 0.4],
      begin: const Alignment(-1.0, -0.3),
      end: const Alignment(1.0, 0.3),
      tileMode: TileMode.clamp,
    );
    
    // Get the view mode from IndexProvider
    // Use a Selector to minimize rebuilds on view mode changes
    return provider.Selector<IndexProvider, CommunityViewMode>(
      selector: (_, provider) => provider.communityViewMode,
      builder: (context, viewMode, _) {
        // Check if view mode changed
        final viewModeChanged = _lastViewMode != viewMode;
        if (viewModeChanged) {
          // Log view mode change for debugging
          debugPrint("🔄 VIEW MODE CHANGED: from ${_lastViewMode?.toString() ?? 'null'} to ${viewMode.toString()}");
          
          // When view mode changes, this is a good time to ensure counts are updated
          // Will only run in debug mode
          if (kDebugMode) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                try {
                  // Get the feed provider
                  final feedProvider = context.read<GroupFeedProvider>();
                  // Force update counts
                  feedProvider.forceUpdateAllReadCounts(log: false);
                } catch (e) {
                  // Ignore errors during this debugging operation
                }
              }
            });
          }
        }
        _lastViewMode = viewMode;
        
        // Check if we have cached widgets to show immediately
        if (!viewModeChanged && 
            ((viewMode == CommunityViewMode.feed && _cachedFeedWidget != null) || 
             (viewMode == CommunityViewMode.grid && _cachedGridWidget != null) ||
             (viewMode == CommunityViewMode.list && _cachedListWidget != null))) {
          // Return cached widget immediately
          Widget cachedWidget;
          if (viewMode == CommunityViewMode.feed) {
            cachedWidget = _cachedFeedWidget!;
          } else if (viewMode == CommunityViewMode.list) {
            cachedWidget = _cachedListWidget!;
          } else {
            cachedWidget = _cachedGridWidget!;
          }
          
          return _buildScaffold(
            context, 
            viewMode,
            cachedWidget,
          );
        }
        
        // Use Scaffold directly for better layout management
        return Scaffold(
          body: Consumer(
            builder: (context, ref, child) {
              // Use a less reactive watch pattern
              final controller = ref.watch(communitiesControllerProvider);
              
              // If loading and cached widget available
              if (controller is AsyncLoading) {
                if (viewMode == CommunityViewMode.feed && _cachedFeedWidget != null) {
                  return _cachedFeedWidget!;
                } else if (viewMode == CommunityViewMode.grid && _cachedGridWidget != null) {
                  return _cachedGridWidget!;
                }
                return _loadingWidget;
              }
              
              return controller.when(
                data: (groupIds) {
                  if (groupIds.isEmpty) {
                    // Cache empty state widget
                    _cachedEmptyWidget ??= const Center(
                      child: NoCommunitiesWidget(),
                    );
                    return _cachedEmptyWidget!;
                  }
                  
                  // Choose content based on view mode with persistent caching
                  // Create a copy of the list to sort
                  final sortedGroupIds = List<GroupIdentifier>.from(groupIds);
                  
                  if (viewMode == CommunityViewMode.feed) {
                    // Only create feed widget if not already cached
                    if (_cachedFeedWidget == null) {
                      debugPrint("🏗️ CREATING CACHED FEED WIDGET for the first time");
                      _cachedFeedWidget = const CommunitiesFeedWidget().withGroupProviders();
                    } else {
                      debugPrint("♻️ REUSING CACHED FEED WIDGET");
                    }
                    return _cachedFeedWidget!;
                  } else if (viewMode == CommunityViewMode.list) {
                    // Only create list widget if not already cached
                    if (_cachedListWidget == null || viewModeChanged) {
                      debugPrint("🏗️ CREATING CACHED LIST WIDGET: first time=${_cachedListWidget == null}, viewModeChanged=$viewModeChanged");
                      
                      // Wrap with our providers to ensure GroupReadStatusProvider is available
                      _cachedListWidget = Shimmer(
                        linearGradient: shimmerGradient,
                        child: CommunitiesListWidget(groupIds: sortedGroupIds),
                      ).withGroupProviders();
                    } else {
                      debugPrint("♻️ REUSING CACHED LIST WIDGET");
                    }
                    return _cachedListWidget!;
                  } else {
                    // Only create grid widget if not already cached
                    if (_cachedGridWidget == null || viewModeChanged) {
                      debugPrint("🏗️ CREATING CACHED GRID WIDGET: first time=${_cachedGridWidget == null}, viewModeChanged=$viewModeChanged");
                      
                      _cachedGridWidget = Shimmer(
                        linearGradient: shimmerGradient,
                        child: CommunitiesGridWidget(groupIds: sortedGroupIds),
                      ).withGroupProviders();
                    } else {
                      debugPrint("♻️ REUSING CACHED GRID WIDGET");
                    }
                    return _cachedGridWidget!;
                  }
                },
                error: (error, stackTrace) => Center(child: ErrorWidget(error)),
                loading: () => _loadingWidget,
              );
            },
          ),
          // No FAB at the top level
        );
      }
    );
  }
  
  // Separated widget building methods to improve maintainability
  Widget _buildScaffold(BuildContext context, CommunityViewMode viewMode, Widget body) {
    // Wrap the scaffold with our group providers to ensure they're available
    return Scaffold(
      body: body.withGroupProviders(),
      // No FAB at the top level
    );
  }
}