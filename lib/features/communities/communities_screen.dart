import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/component/editor/search_mention_user_widget.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostrmo/generated/l10n.dart';
import 'package:nostrmo/provider/dm_provider.dart';
import 'package:nostrmo/provider/group_feed_provider.dart';
import 'package:nostrmo/provider/index_provider.dart';
import 'package:nostrmo/provider/list_provider.dart';
import 'package:nostrmo/router/edit/editor_widget.dart';
import 'package:nostrmo/router/group/communities_feed_widget.dart';
import 'package:nostrmo/features/create_community/create_community_dialog.dart';
import 'package:nostrmo/router/group/no_communities_widget.dart';
import 'package:nostrmo/component/paste_join_link_button.dart';
import 'package:nostrmo/util/community_join_util.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:bot_toast/bot_toast.dart';
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
          // Add speed dial FAB
          floatingActionButton: _buildSpeedDial(context, viewMode),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        );
      }
    );
  }
  
  // Separated widget building methods to improve maintainability
  Widget _buildScaffold(BuildContext context, CommunityViewMode viewMode, Widget body, GroupFeedProvider feedProvider) {
    return Scaffold(
      body: body,
      floatingActionButton: _buildSpeedDial(context, viewMode),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
  

  Widget _buildSpeedDial(BuildContext context, CommunityViewMode viewMode) {
    final themeData = Theme.of(context);
    final primaryColor = themeData.primaryColor;
    final accentColor = themeData.colorScheme.secondary;
    final l10n = S.of(context);
    final indexProvider = provider.Provider.of<IndexProvider>(context, listen: true);
    final communityViewMode = indexProvider.communityViewMode;
    
    return Consumer(
      builder: (context, ref, _) {
        final controllerState = ref.watch(communitiesControllerProvider);
        
        return controllerState.maybeWhen(
          data: (groupIds) {
            // For empty groups, just show paste link button
            if (groupIds.isEmpty) {
              return const PasteJoinLinkButton();
            }
            
            // Full speed dial for groups with content
            return SpeedDial(
              icon: Icons.add,
              activeIcon: Icons.close,
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              overlayColor: Colors.black,
              overlayOpacity: 0.5,
              spacing: 15,
              spaceBetweenChildren: 12,
              tooltip: 'Actions',
              visible: true,
              direction: SpeedDialDirection.up,
              switchLabelPosition: false,
              children: [
                // Post creation
                SpeedDialChild(
                  child: const Icon(Icons.post_add),
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  label: l10n.post,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  labelBackgroundColor: Colors.white,
                  onTap: () {
                    debugPrint("Tapped on post button");
                    _openPostEditor(context);
                  },
                ),
                // Chat creation
                SpeedDialChild(
                  child: const Icon(Icons.chat),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  label: l10n.chat,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  labelBackgroundColor: Colors.white,
                  onTap: () {
                    debugPrint("Tapped on chat button");
                    _showSearchUserForDM(context);
                  },
                ),
                // Asks & Offers
                SpeedDialChild(
                  child: const Icon(Icons.question_answer),
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  label: l10n.asksAndOffers,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  labelBackgroundColor: Colors.white,
                  onTap: () {
                    debugPrint("Tapped on asks/offers button");
                    RouterUtil.router(context, RouterPath.listings, null);
                  },
                ),
                // Create community
                SpeedDialChild(
                  child: const Icon(Icons.group_add),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  label: l10n.createGroup,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  labelBackgroundColor: Colors.white,
                  onTap: () {
                    debugPrint("Tapped on create group button");
                    CreateCommunityDialog.show(context);
                  },
                ),
                // Toggle view
                SpeedDialChild(
                  child: Icon(
                    communityViewMode == CommunityViewMode.grid
                        ? Icons.view_list
                        : Icons.grid_view,
                  ),
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  label: communityViewMode == CommunityViewMode.grid
                      ? l10n.switchToFeedView 
                      : l10n.switchToGridView,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  labelBackgroundColor: Colors.white,
                  onTap: () {
                    debugPrint("Tapped on toggle view button");
                    _toggleViewMode(indexProvider);
                  },
                ),
                // Paste join link
                SpeedDialChild(
                  child: const Icon(Icons.content_paste),
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  label: l10n.joinGroup,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  labelBackgroundColor: Colors.white,
                  onTap: () async {
                    // Simulate paste join link button tap
                    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
                    final clipboardText = clipboardData?.text?.trim();
                    
                    if (clipboardText != null) {
                      if (context.mounted) {
                        CommunityJoinUtil.parseAndJoinCommunity(context, clipboardText);
                      }
                    }
                  },
                ),
              ],
            );
          },
          orElse: () => const PasteJoinLinkButton(),
        );
      },
    );
  }
  
  // Helper methods for the speed dial FAB
  void _openPostEditor(BuildContext context) {
    EditorWidget.open(context).then((event) {
      if (event != null && context.mounted) {
        BotToast.showText(text: S.of(context).send);
      }
    });
  }
  
  void _showSearchUserForDM(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text(S.of(context).chat)),
          body: const SearchMentionUserWidget(),
        ),
      ),
    ).then((pubkey) {
      if (pubkey != null && pubkey is String && context.mounted) {
        final dmProvider = provider.Provider.of<DMProvider>(context, listen: false);
        final dmDetail = dmProvider.findOrNewADetail(pubkey);
        RouterUtil.router(context, RouterPath.dmDetail, dmDetail);
      }
    });
  }
  
  void _toggleViewMode(IndexProvider indexProvider) {
    final currentMode = indexProvider.communityViewMode;
    final newMode = currentMode == CommunityViewMode.grid
        ? CommunityViewMode.feed
        : CommunityViewMode.grid;
    
    debugPrint("👆 USER TOGGLED VIEW: Changing from ${currentMode.toString()} to ${newMode.toString()}");
    
    indexProvider.setCommunityViewMode(newMode);
  }
}

