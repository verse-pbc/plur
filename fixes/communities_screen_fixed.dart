import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:provider/provider.dart' as provider;

import '../../component/shimmer/shimmer.dart';
import 'package:nostrmo/theme/app_colors.dart';
import '../provider/group_feed_provider.dart';
import '../provider/group_read_status_provider.dart';
import '../provider/index_provider.dart';
import '../provider/list_provider.dart';
import '../router/group/communities_feed_widget.dart';
import '../router/group/no_communities_widget.dart';
import 'communities_controller.dart';
import 'communities_grid_widget.dart';
import 'communities_list_widget.dart';

/// This is an improved implementation of the CommunitiesScreen that ensures
/// proper provider initialization order and avoids static references.
class CommunitiesScreen extends ConsumerStatefulWidget {
  const CommunitiesScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _CommunitiesScreenState();
  }
}

class _CommunitiesScreenState extends ConsumerState<CommunitiesScreen> with AutomaticKeepAliveClientMixin {
  // Persistent cached widgets that survive rebuild cycles
  static Widget? _cachedGridWidget;
  static Widget? _cachedListWidget;
  static Widget? _cachedFeedWidget;
  static Widget? _cachedEmptyWidget;
  
  // Cache for view mode state
  static CommunityViewMode? _lastViewMode;
  
  // Pre-built loading widget for faster display
  final Widget _loadingWidget = const Center(child: CircularProgressIndicator());
  
  @override
  bool get wantKeepAlive => true;

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
        }
        _lastViewMode = viewMode;
        
        // Create the providers for groups
        return _buildProviderTree(
          context,
          child: Consumer(
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
                    if (_cachedFeedWidget == null || viewModeChanged) {
                      debugPrint("🏗️ CREATING CACHED FEED WIDGET for the first time");
                      _cachedFeedWidget = const CommunitiesFeedWidget();
                    } else {
                      debugPrint("♻️ REUSING CACHED FEED WIDGET");
                    }
                    return _cachedFeedWidget!;
                  } else if (viewMode == CommunityViewMode.list) {
                    // Only create list widget if not already cached
                    if (_cachedListWidget == null || viewModeChanged) {
                      debugPrint("🏗️ CREATING CACHED LIST WIDGET: first time=${_cachedListWidget == null}, viewModeChanged=$viewModeChanged");
                      
                      _cachedListWidget = Shimmer(
                        linearGradient: shimmerGradient,
                        child: CommunitiesListWidget(groupIds: sortedGroupIds),
                      );
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
                      );
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
        );
      },
    );
  }

  /// Build the provider tree with proper dependencies
  Widget _buildProviderTree(BuildContext context, {required Widget child}) {
    return provider.MultiProvider(
      providers: [
        provider.ChangeNotifierProvider(
          create: (context) {
            // Create a new instance of GroupReadStatusProvider
            final readStatusProvider = GroupReadStatusProvider();
            
            // Initialize it immediately
            Future.microtask(() {
              readStatusProvider.init();
            });
            
            return readStatusProvider;
          },
        ),
        provider.Consumer<GroupReadStatusProvider>(
          builder: (context, readStatusProvider, _) {
            // Get the ListProvider from higher in the tree
            final listProvider = provider.Provider.of<ListProvider>(context, listen: false);
            
            // Now create the GroupFeedProvider with correct dependencies
            return provider.ChangeNotifierProvider(
              create: (context) {
                // Create with both dependencies
                final feedProvider = GroupFeedProvider(listProvider, readStatusProvider);
                
                // Schedule post-frame initialization to ensure counts are updated
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  // Initialize the feed provider
                  if (feedProvider.notesBox.isEmpty()) {
                    feedProvider.subscribe();
                    feedProvider.doQuery(null);
                  } else {
                    // Update counts from existing data
                    feedProvider.updateAllGroupReadCounts();
                  }
                });
                
                return feedProvider;
              },
              child: child,
            );
          },
        ),
      ],
    );
  }
}