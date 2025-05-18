import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/provider/group_feed_provider.dart';
import 'package:nostrmo/provider/group_read_status_provider.dart';
import 'package:nostrmo/provider/index_provider.dart';
import 'package:nostrmo/provider/list_provider.dart';
import 'package:nostrmo/router/group/communities_feed_widget.dart';
// Import Provider package with an alias to avoid conflicts
import 'package:provider/provider.dart' as provider;

import '../../component/shimmer/shimmer.dart';
import '../../theme/app_colors.dart';
import '../../generated/l10n.dart';
import '../../router/group/join_community_widget.dart';
import '../../util/community_join_util.dart';
import '../../features/create_community/create_community_dialog.dart';
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
                    developer.log("🚫 NO COMMUNITIES FOUND: Showing empty state", name: "CommunitiesScreen");
                    // Show an empty state directly instead of the sheet
                    return _buildEmptyStateWithOptions(context);
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
  
  // Builds the empty state with community options
  Widget _buildEmptyStateWithOptions(BuildContext context) {
    final colors = context.colors;
    final l10n = S.of(context);
    
    return Container(
      color: colors.background,
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.all(30.0),
            child: Card(
              elevation: 4,
              color: colors.cardBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Text(
                        l10n.communities,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: colors.primaryText,
                        ),
                      ),
                    ),
                    
                    // Create new community option
                    _buildOptionTile(
                      context: context,
                      icon: Icons.add_circle_outline,
                      title: l10n.createGroup,
                      subtitle: "Create a new community for your interests",
                      onTap: () {
                        CreateCommunityDialog.show(context);
                      },
                    ),
                    
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 12),
                    
                    // Join test community option
                    _buildOptionTile(
                      context: context,
                      icon: Icons.people_outline,
                      title: "Join Plur Test Users",
                      subtitle: "Join the official Plur test community",
                      onTap: () {
                        _joinTestUsersGroup(context);
                      },
                    ),
                    
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 12),
                    
                    // Join with invite link option
                    _buildOptionTile(
                      context: context,
                      icon: Icons.link,
                      title: l10n.joinGroup,
                      subtitle: l10n.haveInviteLink,
                      onTap: () {
                        // Navigate to join community page
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => JoinCommunityWidget(
                              onJoinCommunity: (String link) {
                                final success = CommunityJoinUtil.parseAndJoinCommunity(context, link);
                                if (success) {
                                  Navigator.of(context).pop();
                                }
                              },
                            ),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 12),
                    
                    // Search for communities
                    _buildOptionTile(
                      context: context,
                      icon: Icons.search,
                      title: "Find Communities",
                      subtitle: "Search for public communities",
                      enabled: false,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Public community search coming soon!")),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  // Helper to build a consistent option tile
  Widget _buildOptionTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    final colors = context.colors;
    final color = enabled ? colors.primary : colors.secondaryText.withAlpha(153);
    
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: enabled ? colors.primaryText : colors.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Joins the Plur Test Users community group
  void _joinTestUsersGroup(BuildContext context) {
    const String testUsersGroupLink = "plur://join-community?group-id=R6PCSLSWB45E&code=Z2PWD5ML";
    
    // Show confirmation dialog first
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        final colors = context.colors;
        
        return AlertDialog(
          backgroundColor: colors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            "Join Plur Test Users Group",
            style: TextStyle(
              color: colors.primaryText,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            "Would you like to join the Plur Test Users community? "
            "This is a public group for testing features and connecting with other users.",
            style: TextStyle(
              color: colors.primaryText,
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: Text(
                "Cancel",
                style: TextStyle(
                  color: colors.secondaryText,
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                
                // Show loading indicator
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text("Joining Plur Test Users group..."),
                    duration: const Duration(seconds: 1),
                    backgroundColor: colors.primary.withAlpha(230),
                  ),
                );
                
                // Attempt to join the group
                bool success = CommunityJoinUtil.parseAndJoinCommunity(context, testUsersGroupLink);
                
                if (!success && context.mounted) {
                  // Show error message if joining failed
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Failed to join test users group. Please try again later."),
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                "Join Group",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    // No need to dispose providers here - they'll be disposed automatically
    super.dispose();
  }
}