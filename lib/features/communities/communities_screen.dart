import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/provider/group_feed_provider.dart';
import 'package:nostrmo/provider/index_provider.dart';
import 'package:nostrmo/provider/list_provider.dart';
import 'package:nostrmo/router/group/communities_feed_widget.dart';
import 'package:nostrmo/router/group/no_communities_widget.dart';
import 'package:nostrmo/component/paste_join_link_button.dart';
// Import Provider package with an alias to avoid conflicts
import 'package:provider/provider.dart' as provider;

import '../../component/shimmer/shimmer.dart';
import '../../util/theme_util.dart';
import 'communities_controller.dart';
import 'communities_grid_widget.dart';

class CommunitiesScreen extends ConsumerStatefulWidget {
  const CommunitiesScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _CommunitiesScreenState();
  }
}

class _CommunitiesScreenState extends ConsumerState<CommunitiesScreen> with AutomaticKeepAliveClientMixin {
  final subscribeId = StringUtil.rndNameStr(16);
  
  // Static cache to persist between tab switches
  static GroupFeedProvider? _cachedFeedProvider;
  
  // Cache for view mode state
  static CommunityViewMode? _lastViewMode;
  
  // Flag to prevent duplicate initialization 
  static bool _globalInitializationDone = false;
  

  @override
  void dispose() {
    // Don't dispose the feed provider when the widget is disposed - it needs to survive tab switching
    // We'll clean it up in app dispose instead
    super.dispose();
  }

  // Singleton pattern for feed provider to persist across tab switches
  GroupFeedProvider _getFeedProvider(ListProvider listProvider) {
    // Use static cached provider if it exists
    if (_cachedFeedProvider != null) {
      return _cachedFeedProvider!;
    }
    
    // Create a new provider and cache it statically
    _cachedFeedProvider = GroupFeedProvider(listProvider);
    return _cachedFeedProvider!;
  }

  // Initialize feed provider with optimized initialization
  void _initFeedProvider(ListProvider listProvider) {
    final provider = _getFeedProvider(listProvider);
    
    // Force initialization regardless of global flag - sometimes the feed data doesn't load
    // on first launch due to race conditions
    
    // Initialize in a microtask to avoid blocking the UI
    Future.microtask(() {
      // Check if we already have data before re-initializing
      if (provider.notesBox.isEmpty()) {
        // print("Initializing feed provider - subscribing and querying");
        provider.subscribe();
        provider.doQuery(null);
      } else {
        // print("Feed provider already has data - skipping initialization");
      }
      
      // Always mark as initialized
      _globalInitializationDone = true;
      
      // Notify IndexProvider that this tab has loaded
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          try {
            final indexProvider = context.read<IndexProvider>();
            indexProvider.markTabLoaded(0);
          } catch (e) {
            // Ignore context errors during initialization
          }
        }
      });
    });
  }
  
  // Persistent cached widgets that survive rebuild cycles
  static Widget? _cachedGridWidget;
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
  void _initializeState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        try {
          final listProvider = context.read<ListProvider>();
          _initFeedProvider(listProvider);
        } catch (e) {
          // Handle failure to read provider
        }
      }
    });
  }
  
  void _preloadData() {
    if (context.mounted) {
      try {
        // Get providers without triggering rebuilds
        final listProvider = context.read<ListProvider>();
        
        // Initialize feed provider immediately but only once globally
        _initFeedProvider(listProvider);
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
    final appBgColor = themeData.customColors.appBgColor;
    final separatorColor = themeData.customColors.separatorColor;
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
          debugPrint("🔄 COMMUNITY VIEW MODE CHANGED: from ${_lastViewMode?.toString() ?? 'null'} to ${viewMode.toString()}");
        }
        _lastViewMode = viewMode;
        
        // Get the list provider without triggering rebuilds
        final listProvider = provider.Provider.of<ListProvider>(context, listen: false);
        
        // Initialize feed provider early
        final feedProvider = _getFeedProvider(listProvider);
        
        // Check if we have cached widgets to show immediately
        if (!viewModeChanged && 
            ((viewMode == CommunityViewMode.feed && _cachedFeedWidget != null) || 
             (viewMode == CommunityViewMode.grid && _cachedGridWidget != null))) {
          // Return cached widget immediately
          return _buildScaffold(
            context, 
            viewMode,
            viewMode == CommunityViewMode.feed 
                ? _cachedFeedWidget!
                : _cachedGridWidget!,
            feedProvider
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
                  if (viewMode == CommunityViewMode.feed) {
                    // Only create feed widget if not already cached
                    if (_cachedFeedWidget == null) {
                      debugPrint("🏗️ CREATING CACHED FEED WIDGET for the first time");
                      _cachedFeedWidget = provider.ChangeNotifierProvider.value(
                        value: feedProvider,
                        child: const CommunitiesFeedWidget(),
                      );
                    } else {
                      debugPrint("♻️ REUSING CACHED FEED WIDGET");
                    }
                    return _cachedFeedWidget!;
                  } else {
                    // Only create grid widget if not already cached
                    if (_cachedGridWidget == null || viewModeChanged) {
                      debugPrint("🏗️ CREATING CACHED GRID WIDGET: first time=${_cachedGridWidget == null}, viewModeChanged=$viewModeChanged");
                      
                      // Create a copy of the list to sort (no-op for now, sorting will be added in a future PR)
                      final sortedGroupIds = List<GroupIdentifier>.from(groupIds);
                      
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
          // Add toggle view button
          // Removed floating action button - now in index_widget.dart
        );
      }
    );
  }
  
  // Separated widget building methods to improve maintainability
  Widget _buildScaffold(BuildContext context, CommunityViewMode viewMode, Widget body, GroupFeedProvider feedProvider) {
    return Scaffold(
      body: body,
      // Removed floating action button - now in index_widget.dart
    );
  }
  

  Widget _buildFloatingActionButtons(BuildContext context) {
    // Get the current view mode
    final indexProvider = provider.Provider.of<IndexProvider>(context, listen: false);
    final viewMode = indexProvider.communityViewMode;
    
    return Consumer(
      builder: (context, ref, _) {
        final controllerState = ref.watch(communitiesControllerProvider);
        return controllerState.maybeWhen(
          data: (groupIds) {
            if (groupIds.isEmpty) {
              // Only show paste link button when there are no groups
              return const PasteJoinLinkButton();
            } else {
              // Show both buttons when there are groups
              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Toggle view button
                  FloatingActionButton(
                    heroTag: 'toggleView',
                    mini: true,
                    onPressed: () {
                      // Toggle the view mode in IndexProvider
                      final newMode = viewMode == CommunityViewMode.grid
                          ? CommunityViewMode.feed
                          : CommunityViewMode.grid;
                      
                      debugPrint("👆 USER TOGGLED VIEW: Changing from ${viewMode.toString()} to ${newMode.toString()}");
                      
                      indexProvider.setCommunityViewMode(newMode);
                    },
                    tooltip: viewMode == CommunityViewMode.grid
                        ? 'Switch to Feed View'
                        : 'Switch to Grid View',
                    child: Icon(
                      viewMode == CommunityViewMode.grid
                          ? Icons.view_list
                          : Icons.grid_view,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Paste join link button
                  const PasteJoinLinkButton(),
                ],
              );
            }
          },
          orElse: () => const PasteJoinLinkButton(),
        );
      },
    );
  }
}

