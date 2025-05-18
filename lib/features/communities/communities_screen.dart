import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/provider/group_feed_provider.dart';
import 'package:nostrmo/provider/group_read_status_provider.dart';
import 'package:nostrmo/provider/index_provider.dart';
import 'package:nostrmo/provider/list_provider.dart';
import 'package:nostrmo/router/group/communities_feed_widget.dart';
import 'package:nostrmo/router/group/no_communities_sheet.dart';
import 'package:nostrmo/main.dart';
// Import Provider package with an alias to avoid conflicts
import 'package:provider/provider.dart' as provider;

import '../../component/shimmer/shimmer.dart';
import '../../theme/app_colors.dart';
import '../../generated/l10n.dart';
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
  
  // Persistent cached widgets that survive rebuild cycles - now stored by user
  static Map<String, Widget?> _cachedGridWidgets = {};
  static Map<String, Widget?> _cachedListWidgets = {};
  static Map<String, Widget?> _cachedFeedWidgets = {};
  
  // These static properties need to be retained for backward compatibility
  static Widget? _cachedGridWidget;
  static Widget? _cachedListWidget;
  static Widget? _cachedFeedWidget;
  static bool _hasEverSeenGroups = false;
  
  // Cache for view mode state - now per user
  static Map<String, CommunityViewMode?> _lastViewModes = {};
  
  // Pre-built loading widget for faster display
  final Widget _loadingWidget = const Center(child: CircularProgressIndicator());
  
  // Track whether the component has loaded to avoid shimmer flickering
  bool _hasLoaded = false;
  
  // Track whether we've ever seen groups to prevent showing empty state incorrectly
  static Map<String, bool> _hasEverSeenGroupsByUser = {};
  
  // Current user's public key - for caching
  String? _currentUserKey;

  // Flag to track if the no communities sheet is currently open or being shown
  bool _isNoCommunitiesSheetOpen = false;
  
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    
    // Get the current user's public key
    _currentUserKey = nostr?.publicKey;
    debugPrint("🔑 INITIALIZING FOR USER: $_currentUserKey");
    
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
    
    // Check if user has changed
    final currentUserKey = nostr?.publicKey;
    if (currentUserKey != _currentUserKey && currentUserKey != null) {
      // User has changed, update our user key
      debugPrint("🔄 USER CHANGED: From $_currentUserKey to $currentUserKey");
      _currentUserKey = currentUserKey;
      
      // Reset state for the new user
      _hasLoaded = false;
      
      // Initialize user tracking if needed
      if (!_hasEverSeenGroupsByUser.containsKey(currentUserKey)) {
        _hasEverSeenGroupsByUser[currentUserKey] = false;
        debugPrint("🔄 INITIALIZING TRACKING FOR NEW USER: $currentUserKey");
      }
      
      // Reset feed provider to trigger reloading data
      if (_feedProvider != null) {
        _feedProvider = null;
        debugPrint("🔄 RESETTING FEED PROVIDER FOR USER CHANGE");
      }
    }
    
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
        
        debugPrint("✅ FEED PROVIDER INITIALIZED FOR USER: $_currentUserKey");
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
        // Make sure we have a current user key
        if (_currentUserKey == null) {
          _currentUserKey = nostr?.publicKey;
          debugPrint("🔑 SETTING USER KEY DURING VIEW MODE CHECK: $_currentUserKey");
        }
        
        // Check if view mode changed
        CommunityViewMode? lastViewMode;
        if (_currentUserKey != null) {
          lastViewMode = _lastViewModes[_currentUserKey!];
        }
        final viewModeChanged = lastViewMode != viewMode;
        if (viewModeChanged) {
          // Log view mode change for debugging
          debugPrint("🔄 VIEW MODE CHANGED: from ${lastViewMode?.toString() ?? 'null'} to ${viewMode.toString()} for user $_currentUserKey");
        }
        
        // Update last view mode for this user
        if (_currentUserKey != null) {
          _lastViewModes[_currentUserKey!] = viewMode;
        }
        
        // Build UI with local providers
        return _buildProviderTree(
          context,
          child: Consumer(
            builder: (context, ref, child) {
              // Use a less reactive watch pattern
              final controller = ref.watch(communitiesControllerProvider);
              
              // If loading and cached widget available
              if (controller is AsyncLoading) {
                // Get cached widgets for current user if available
                if (_currentUserKey != null) {
                  final cachedFeedWidget = _cachedFeedWidgets[_currentUserKey!];
                  final cachedGridWidget = _cachedGridWidgets[_currentUserKey!];
                  
                  if (viewMode == CommunityViewMode.feed && cachedFeedWidget != null) {
                    return cachedFeedWidget;
                  } else if (viewMode == CommunityViewMode.grid && cachedGridWidget != null) {
                    return cachedGridWidget;
                  }
                }
                
                // Fall back to old cache system for backward compatibility
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
                    _hasEverSeenGroupsByUser[_currentUserKey ?? ''] = true;
                    developer.log("🔔 MARKED HAS_EVER_SEEN_GROUPS=true because we found $originalGroupCount groups", name: "CommunitiesScreen");
                  }
                  
                  // CRITICAL: Show the no communities sheet in two scenarios:
                  // 1. When no communities are found and we've never seen any before (new user)
                  // 2. When communities are found but we need to show the sheet anyway (debug flag)
                  // 
                  // NOTE: We're setting this to false to attempt to show the communities list
                  // before falling back to the empty state sheet
                  final bool forceShowEmptyState = false; // Set to false to try showing communities first
                  
                  // Safety check - make sure we have a current user key
                  if (_currentUserKey == null) {
                    _currentUserKey = nostr?.publicKey;
                    debugPrint("🔑 UPDATING USER KEY DURING BUILD: $_currentUserKey");
                  }
                  
                  // Initialize tracking for this user if needed
                  if (_currentUserKey != null && !_hasEverSeenGroupsByUser.containsKey(_currentUserKey!)) {
                    _hasEverSeenGroupsByUser[_currentUserKey!] = false;
                    debugPrint("🔄 INITIALIZING TRACKING FOR NEW USER: $_currentUserKey");
                  }
                  
                  // Force check with the list provider to get actual count
                  final actualGroupCount = provider.Provider.of<ListProvider>(context, listen: false).groupIdentifiers.length;
                  developer.log("📊 ACTUAL GROUP COUNT FROM ListProvider: $actualGroupCount", name: "CommunitiesScreen");
                  
                  // IMPORTANT: Check if we should show the empty state
                  // Either for new users or when the newUser flag is set from the login flow
                  final bool isNewUser = actualGroupCount == 0 && originalGroupCount == 0 && 
                      (!_hasEverSeenGroupsByUser.containsKey(_currentUserKey ?? '') ||
                       (_currentUserKey != null && _hasEverSeenGroupsByUser[_currentUserKey!] == false));
                  
                  if (isNewUser || newUser == true) {
                    // We show the empty state sheet for completely new users who have never seen any groups
                    developer.log("🚫 NEW USER WITH ZERO GROUPS: Showing empty state sheet. newUser flag: ${newUser == true}", 
                        name: "CommunitiesScreen");
                    
                    // Show the no communities sheet
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _showNoCommunitiesSheet(forceForNewUsers: true);
                      
                      // Reset the newUser flag after showing the sheet to prevent showing it again
                      if (newUser == true) {
                        Future.delayed(const Duration(seconds: 1), () {
                          newUser = false;
                        });
                      }
                    });
                    
                    // Return an empty scaffold while the sheet is being shown
                    return Container(
                      color: context.colors.background,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.groups_outlined,
                              size: 64,
                              color: context.colors.secondaryText.withAlpha(128),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              S.of(context).noCommunitiesYet,
                              style: TextStyle(
                                fontSize: 18,
                                color: context.colors.secondaryText,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              S.of(context).startOrJoinACommunity,
                              style: TextStyle(
                                fontSize: 14,
                                color: context.colors.secondaryText.withAlpha(178),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  
                  // Handle case when communities are empty but we've seen them before
                  if (groupIds.isEmpty) {
                    // Check if this user has ever seen groups
                    final bool hasEverSeenGroups = _currentUserKey != null ? 
                        (_hasEverSeenGroupsByUser[_currentUserKey!] ?? false) : _hasEverSeenGroups;
                        
                    // Check if we have cached widgets for this user
                    final bool hasCachedWidgets = _currentUserKey != null && (
                        _cachedFeedWidgets[_currentUserKey!] != null || 
                        _cachedListWidgets[_currentUserKey!] != null || 
                        _cachedGridWidgets[_currentUserKey!] != null
                    );
                    
                    if (hasEverSeenGroups || hasCachedWidgets || _cachedGridWidget != null) {
                      // If we had groups before but now they're empty, use the last cached view
                      // This prevents flickering when groups are temporarily not available
                      developer.log("⚠️ WARNING: Group list is empty but using cached view to prevent flickering for user $_currentUserKey", name: "CommunitiesScreen");
                      
                      // First try user-specific cache
                      if (_currentUserKey != null) {
                        final cachedFeedWidget = _cachedFeedWidgets[_currentUserKey!];
                        final cachedListWidget = _cachedListWidgets[_currentUserKey!];
                        final cachedGridWidget = _cachedGridWidgets[_currentUserKey!];
                        
                        if (viewMode == CommunityViewMode.feed && cachedFeedWidget != null) {
                          return cachedFeedWidget;
                        } else if (viewMode == CommunityViewMode.list && cachedListWidget != null) {
                          return cachedListWidget;
                        } else if (cachedGridWidget != null) {
                          return cachedGridWidget;
                        }
                      }
                      
                      // Fall back to old caching system
                      if (viewMode == CommunityViewMode.feed && _cachedFeedWidget != null) {
                        return _cachedFeedWidget!;
                      } else if (viewMode == CommunityViewMode.list && _cachedListWidget != null) {
                        return _cachedListWidget!;
                      } else if (_cachedGridWidget != null) {
                        return _cachedGridWidget!;
                      }
                    }
                  }
                  
                  // Choose content based on view mode with persistent caching
                  // Create a copy of the list to sort
                  final sortedGroupIds = List<GroupIdentifier>.from(groupIds);
                  
                  try {
                    // Make sure we have a user key
                    if (_currentUserKey == null) {
                      _currentUserKey = nostr?.publicKey;
                      debugPrint("🔑 SETTING USER KEY DURING RENDERING: $_currentUserKey");
                    }
                    
                    // Only proceed if we have a user key
                    if (_currentUserKey == null) {
                      debugPrint("⚠️ NO CURRENT USER KEY - CAN'T SHOW COMMUNITIES");
                      return const Center(child: Text("No user logged in"));
                    }
                    
                    // Log the number of groups we're trying to show
                    debugPrint("🔍 ATTEMPTING TO SHOW ${sortedGroupIds.length} GROUPS for user $_currentUserKey in ${viewMode.toString()} mode");
                    
                    // Track that this user has seen groups
                    if (sortedGroupIds.isNotEmpty) {
                      _hasEverSeenGroups = true; // For backward compatibility
                      _hasEverSeenGroupsByUser[_currentUserKey!] = true;
                      debugPrint("🔔 MARKED USER $_currentUserKey AS HAS_SEEN_GROUPS=true");
                    }
                    
                    // Get cached widgets for this user
                    Widget? cachedFeedWidget = _cachedFeedWidgets[_currentUserKey!];
                    Widget? cachedListWidget = _cachedListWidgets[_currentUserKey!];
                    Widget? cachedGridWidget = _cachedGridWidgets[_currentUserKey!];
                    
                    if (viewMode == CommunityViewMode.feed) {
                      // Only create feed widget if not already cached
                      if (cachedFeedWidget == null || viewModeChanged) {
                        debugPrint("🏗️ CREATING CACHED FEED WIDGET for user $_currentUserKey");
                        cachedFeedWidget = const CommunitiesFeedWidget();
                        
                        // Store in both caches
                        _cachedFeedWidgets[_currentUserKey!] = cachedFeedWidget;
                        _cachedFeedWidget = cachedFeedWidget; // For backward compatibility
                      } else {
                        debugPrint("♻️ REUSING CACHED FEED WIDGET for user $_currentUserKey");
                      }
                      return cachedFeedWidget!;
                    } else if (viewMode == CommunityViewMode.list) {
                      // Only create list widget if not already cached
                      if (cachedListWidget == null || viewModeChanged) {
                        debugPrint("🏗️ CREATING CACHED LIST WIDGET for user $_currentUserKey: viewModeChanged=$viewModeChanged");
                        
                        // Apply Shimmer effect only if this is the first load
                        // This prevents the flickering issue when switching views
                        if (!_hasLoaded) {
                          debugPrint("🏗️ CREATING LIST WIDGET WITH SHIMMER for user $_currentUserKey");
                          cachedListWidget = Shimmer(
                            linearGradient: shimmerGradient,
                            child: CommunitiesListWidget(groupIds: sortedGroupIds),
                          );
                        } else {
                          debugPrint("🏗️ CREATING LIST WIDGET WITHOUT SHIMMER for user $_currentUserKey");
                          cachedListWidget = CommunitiesListWidget(groupIds: sortedGroupIds);
                        }
                        
                        // Store in both caches
                        _cachedListWidgets[_currentUserKey!] = cachedListWidget;
                        _cachedListWidget = cachedListWidget; // For backward compatibility
                      } else {
                        debugPrint("♻️ REUSING CACHED LIST WIDGET for user $_currentUserKey");
                      }
                      return cachedListWidget!;
                    } else {
                      // Only create grid widget if not already cached
                      if (cachedGridWidget == null || viewModeChanged) {
                        debugPrint("🏗️ CREATING CACHED GRID WIDGET for user $_currentUserKey: viewModeChanged=$viewModeChanged");
                        
                        // Apply Shimmer effect only if this is the first load
                        // This prevents the flickering issue when switching views
                        if (!_hasLoaded) {
                          debugPrint("🏗️ CREATING GRID WIDGET WITH SHIMMER for user $_currentUserKey");
                          cachedGridWidget = Shimmer(
                            linearGradient: shimmerGradient,
                            child: CommunitiesGridWidget(groupIds: sortedGroupIds),
                          );
                        } else {
                          debugPrint("🏗️ CREATING GRID WIDGET WITHOUT SHIMMER for user $_currentUserKey");
                          cachedGridWidget = CommunitiesGridWidget(groupIds: sortedGroupIds);
                        }
                        
                        // Store in both caches
                        _cachedGridWidgets[_currentUserKey!] = cachedGridWidget;
                        _cachedGridWidget = cachedGridWidget; // For backward compatibility
                      } else {
                        debugPrint("♻️ REUSING CACHED GRID WIDGET for user $_currentUserKey");
                      }
                      return cachedGridWidget!;
                    }
                  } catch (e, stackTrace) {
                    // If we get an error trying to display communities, show the no communities sheet
                    debugPrint("⚠️ ERROR SHOWING COMMUNITIES: $e");
                    debugPrint("🔄 STACK TRACE: $stackTrace");
                    
                    // Show the NoCommunitiesSheet as a fallback
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      // Only show if not already showing
                      if (!_isNoCommunitiesSheetOpen && mounted) {
                        _showNoCommunitiesSheet(forceForNewUsers: true);
                      }
                    });
                    
                    // Return an empty scaffold while the sheet is being shown
                    return Container(
                      color: context.colors.background,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(height: 20),
                              Text(
                                "Loading your communities...",
                                style: TextStyle(
                                  color: context.colors.primaryText,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
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
  
  /// Shows the no communities bottom sheet ONLY if user has no groups
  void _showNoCommunitiesSheet({bool forceForNewUsers = false}) {
    if (_isNoCommunitiesSheetOpen) { 
      developer.log("NoCommunitiesSheet is already open or being shown, skipping.", name: "CommunitiesScreen");
      return;
    }

    // Get the ListProvider to check if user actually has any groups
    final listProvider = provider.Provider.of<ListProvider>(context, listen: false);
    
    // Force a refresh of groups before checking
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        if (!mounted) return;
        
        // Perform an additional check with the ListProvider
        // This is critical for the case where the user has just joined a community
        // and we need to make sure we have the latest data
        final groupCount = listProvider.groupIdentifiers.length;
        developer.log("📊 Checking community count before showing sheet: $groupCount", name: "CommunitiesScreen");
        
        // CRITICAL CHECK: If user has ANY groups, DO NOT show the sheet
        if (groupCount > 0) {
          developer.log("User has communities ($groupCount), NOT showing NoCommunitiesSheet", 
              name: "CommunitiesScreen");
          
          // Force update the screen to show the communities immediately
          if (mounted) {
            setState(() {
              // This will trigger a rebuild with the latest data
              _hasEverSeenGroupsByUser[_currentUserKey ?? ''] = true;
              _hasEverSeenGroups = true;
            });
          }
          return;
        }
        
        // Log that we're going to show the sheet because there are NO groups
        developer.log("User has NO communities. Showing NoCommunitiesSheet", name: "CommunitiesScreen");
        
        // Check if sheet was previously dismissed
        final shouldShow = await NoCommunitiesSheet.shouldShowDialog();
        if (!shouldShow && !forceForNewUsers) {
          developer.log("NoCommunitiesSheet was previously dismissed by user, not showing", name: "CommunitiesScreen");
          return;
        }
        
        if (!mounted || ModalRoute.of(context)?.isCurrent != true) {
          developer.log("Context is no longer valid, not showing sheet", name: "CommunitiesScreen");
          return;
        }
        
        // Set flag to prevent multiple sheets
        _isNoCommunitiesSheetOpen = true; 
        
        // Show the sheet
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent, 
          builder: (BuildContext context) {
            return NoCommunitiesSheet(forceShow: forceForNewUsers);
          },
        ).whenComplete(() {
          developer.log("NoCommunitiesSheet dismissed.", name: "CommunitiesScreen");
          if (mounted) { 
            setState(() { 
              _isNoCommunitiesSheetOpen = false; 
              
              // Check again for communities after dismissal
              // in case the user joined a community while the sheet was open
              if (listProvider.groupIdentifiers.isNotEmpty) {
                _hasEverSeenGroupsByUser[_currentUserKey ?? ''] = true;
                _hasEverSeenGroups = true;
              }
            });
          } else {
            _isNoCommunitiesSheetOpen = false; 
          }
        });
      } catch (e) {
        developer.log("Error showing NoCommunitiesSheet: $e", name: "CommunitiesScreen");
        _isNoCommunitiesSheetOpen = false;
      }
    });
  }
}