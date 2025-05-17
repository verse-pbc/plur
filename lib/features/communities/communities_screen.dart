import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/provider/group_feed_provider.dart';
import 'package:nostrmo/provider/group_read_status_provider.dart';
import 'package:nostrmo/provider/index_provider.dart';
import 'package:nostrmo/provider/list_provider.dart';
import 'package:nostrmo/router/group/communities_feed_widget.dart';
import 'package:nostrmo/router/group/no_communities_sheet.dart';
// Import Provider package with an alias to avoid conflicts
import 'package:provider/provider.dart' as provider;

import '../../component/shimmer/shimmer.dart';
import '../../theme/app_colors.dart';
import 'communities_controller.dart';
import 'communities_grid_widget.dart';
import 'communities_list_widget.dart';

// Used for logging
import 'dart:developer' as developer;

class CommunitiesScreen extends ConsumerStatefulWidget {
  const CommunitiesScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _CommunitiesScreenState();
  }
}

class _CommunitiesScreenState extends ConsumerState<CommunitiesScreen> with AutomaticKeepAliveClientMixin {
  // Cached instances to ensure provider stability
  GroupReadStatusProvider? _readStatusProvider;
  GroupFeedProvider? _feedProvider;
  
  // Persistent cached widgets that survive rebuild cycles
  static Widget? _cachedGridWidget;
  static Widget? _cachedListWidget;
  static Widget? _cachedFeedWidget;
  
  // Cache for view mode state
  static CommunityViewMode? _lastViewMode;
  
  // Pre-built loading widget for faster display
  final Widget _loadingWidget = const Center(child: CircularProgressIndicator());
  
  // Track whether the component has loaded to avoid shimmer flickering
  bool _hasLoaded = false;
  
  // Track whether we've ever seen groups to prevent showing empty state incorrectly
  static bool _hasEverSeenGroups = false;
  
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    
    // Initialize the providers on startup
    _createProviders();
  }

  // Create providers that will live for the lifetime of this widget
  void _createProviders() {
    // Create providers only if they don't exist yet
    if (_readStatusProvider == null) {
      _readStatusProvider = GroupReadStatusProvider();
      _readStatusProvider!.init();
    }
    
    if (_feedProvider == null) {
      // We'll get the ListProvider in didChangeDependencies
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            // This will trigger didChangeDependencies which will complete setup
          });
        }
      });
    }
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Complete provider setup when context is available
    if (_feedProvider == null && _readStatusProvider != null) {
      try {
        // Get the list provider from context
        final listProvider = provider.Provider.of<ListProvider>(context, listen: false);
        
        // Create the feed provider with both dependencies
        _feedProvider = GroupFeedProvider(listProvider, _readStatusProvider);
        
        // Initialize feed provider
        _feedProvider!.subscribe();
        if (_feedProvider!.notesBox.isEmpty()) {
          _feedProvider!.doQuery(null);
        }
      } catch (e) {
        debugPrint("Error getting list provider: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Must call super for AutomaticKeepAliveClientMixin
    super.build(context);
    
    final colors = context.colors;
    final appBgColor = colors.background;
    final separatorColor = colors.divider;
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
        
        // Build UI with local providers
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
                  // Set hasLoaded to true after first successful load
                  if (!_hasLoaded) {
                    debugPrint("🔄 MARKING COMMUNITIES SCREEN AS LOADED");
                    _hasLoaded = true;
                  }
                  
                  // Store original group IDs list length for debugging
                  final int originalGroupCount = groupIds.length;
                  developer.log("📊 RECEIVED $originalGroupCount COMMUNITIES FROM CONTROLLER", name: "CommunitiesScreen");
                  
                  // Keep track if we've ever seen groups to prevent flashing the empty state
                  if (originalGroupCount > 0) {
                    _hasEverSeenGroups = true;
                    developer.log("🔔 MARKED HAS_EVER_SEEN_GROUPS=true because we found $originalGroupCount groups", name: "CommunitiesScreen");
                  }
                  
                  // CRITICAL: Once we've had groups, don't show the empty state unless
                  // explicitly requested, to prevent false emptiness during data refreshes
                  if (groupIds.isEmpty && !_hasEverSeenGroups) {
                    developer.log("🚫 NO COMMUNITIES FOUND: Showing empty state sheet", name: "CommunitiesScreen");
                    // Show the no communities sheet when no communities exist
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _showNoCommunitiesSheet();
                    });
                    // Return an empty scaffold while the sheet is being shown
                    return Container(
                      color: context.colors.background,
                    );
                  } else if (groupIds.isEmpty && (_hasEverSeenGroups || _cachedGridWidget != null)) {
                    // If we had groups before but now they're empty, use the last cached view
                    // This prevents flickering when groups are temporarily not available
                    developer.log("⚠️ WARNING: Group list is empty but using cached view to prevent flickering", name: "CommunitiesScreen");
                    if (viewMode == CommunityViewMode.feed && _cachedFeedWidget != null) {
                      return _cachedFeedWidget!;
                    } else if (viewMode == CommunityViewMode.list && _cachedListWidget != null) {
                      return _cachedListWidget!;
                    } else if (_cachedGridWidget != null) {
                      return _cachedGridWidget!;
                    }
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
                      
                      // Apply Shimmer effect only if this is the first load
                      // This prevents the flickering issue when switching views
                      if (!_hasLoaded) {
                        debugPrint("🏗️ CREATING LIST WIDGET WITH SHIMMER for first load");
                        _cachedListWidget = Shimmer(
                          linearGradient: shimmerGradient,
                          child: CommunitiesListWidget(groupIds: sortedGroupIds),
                        );
                      } else {
                        debugPrint("🏗️ CREATING LIST WIDGET WITHOUT SHIMMER for subsequent loads");
                        _cachedListWidget = CommunitiesListWidget(groupIds: sortedGroupIds);
                      }
                    } else {
                      debugPrint("♻️ REUSING CACHED LIST WIDGET");
                    }
                    return _cachedListWidget!;
                  } else {
                    // Only create grid widget if not already cached
                    if (_cachedGridWidget == null || viewModeChanged) {
                      debugPrint("🏗️ CREATING CACHED GRID WIDGET: first time=${_cachedGridWidget == null}, viewModeChanged=$viewModeChanged");
                      
                      // Apply Shimmer effect only if this is the first load
                      // This prevents the flickering issue when switching views
                      if (!_hasLoaded) {
                        debugPrint("🏗️ CREATING GRID WIDGET WITH SHIMMER for first load");
                        _cachedGridWidget = Shimmer(
                          linearGradient: shimmerGradient,
                          child: CommunitiesGridWidget(groupIds: sortedGroupIds),
                        );
                      } else {
                        debugPrint("🏗️ CREATING GRID WIDGET WITHOUT SHIMMER for subsequent loads");
                        _cachedGridWidget = CommunitiesGridWidget(groupIds: sortedGroupIds);
                      }
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

  /// Build the provider tree with local providers
  Widget _buildProviderTree(BuildContext context, {required Widget child}) {
    // Make sure providers are created
    if (_readStatusProvider == null || _feedProvider == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    // Provide the local providers to the child widgets
    return provider.MultiProvider(
      providers: [
        provider.ChangeNotifierProvider<GroupReadStatusProvider>.value(
          value: _readStatusProvider!,
        ),
        provider.ChangeNotifierProvider<GroupFeedProvider>.value(
          value: _feedProvider!,
        ),
      ],
      child: child,
    );
  }
  
  @override
  void dispose() {
    // No need to dispose providers here - they'll be disposed automatically
    super.dispose();
  }
  
  /// Shows the no communities bottom sheet
  void _showNoCommunitiesSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (sheetContext) => GestureDetector(
        onTap: () => Navigator.of(sheetContext).pop(),
        child: Container(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: () {}, // Prevent taps from propagating to dismiss
            child: const NoCommunitiesSheet(),
          ),
        ),
      ),
    );
  }
}