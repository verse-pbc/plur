import 'dart:async';
import 'dart:io';
import 'dart:developer';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/component/editor/search_mention_user_widget.dart';
import 'package:nostrmo/component/music/music_widget.dart';
import 'package:nostrmo/component/cust_state.dart';
import 'package:nostrmo/component/pc_router_fake.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/consts/base_consts.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostrmo/provider/dm_provider.dart';
import 'package:nostrmo/provider/music_provider.dart';
import 'package:nostrmo/provider/pc_router_fake_provider.dart';
import 'package:nostrmo/router/index/index_pc_drawer_wrapper.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:provider/provider.dart';

import '../../features/communities/communities_screen.dart';
// We still need CreateCommunityDialog import because it's used in CommunityOptionsDialog
import '../../features/create_community/create_community_dialog.dart'; 
import '../../features/create_community/community_options_dialog.dart';
import '../../generated/l10n.dart';
import '../../main.dart';
import '../../provider/index_provider.dart';
import '../../provider/settings_provider.dart';
import '../../util/auth_util.dart';
import '../../util/table_mode_util.dart';
import '../dm/dm_widget.dart';
import '../login/login_widget.dart';
import '../search/search_widget.dart';
import 'index_app_bar.dart';
import 'index_drawer_content.dart';
import 'index_tab_item_widget.dart';

/// Main navigation hub of the application that manages different sections including:
/// * Groups
/// * Search functionality
/// * Direct Messages (DMs)
///
/// This widget handles:
/// * Tab-based navigation
/// * Responsive layout (PC/tablet vs mobile)
/// * Authentication state
/// * App lifecycle management
/// * Music player integration
class IndexWidget extends StatefulWidget {
  /// Maximum width for the navigation drawer in PC mode
  static double pcMaxColumn0 = 240;

  /// Maximum width for the main content area in PC mode
  static double pcMaxColumn1 = 550;

  /// Callback function to reload the application state
  final Function reload;

  const IndexWidget({super.key, required this.reload});

  @override
  State<StatefulWidget> createState() {
    return _IndexWidgetState();
  }
}

class _IndexWidgetState extends CustState<IndexWidget>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late TabController followTabController;
  late TabController globalsTabController;
  late TabController dmTabController;
  
  // Build the communities header without view toggle - only grid view supported now
  Widget _buildCommunityViewToggle(IndexProvider indexProvider, ThemeData themeData) {
    return Center(
      child: Text(
        'Your Communities',
        style: TextStyle(
          color: themeData.textTheme.titleLarge?.color,
          fontWeight: FontWeight.bold,
          fontSize: 20, // Match title size
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    int followInitTab = 0;
    int globalsInitTab = 0;

    // Add observer for app lifecycle events
    WidgetsBinding.instance.addObserver(this);

    // Set initial tab based on user preferences
    if (settingsProvider.defaultTab != null) {
      if (settingsProvider.defaultIndex == 1) {
        globalsInitTab = settingsProvider.defaultTab!;
      } else {
        followInitTab = settingsProvider.defaultTab!;
      }
    }

    followTabController =
        TabController(initialIndex: followInitTab, length: 3, vsync: this);
    globalsTabController =
        TabController(initialIndex: globalsInitTab, length: 3, vsync: this);
    dmTabController = TabController(length: 2, vsync: this);

    // Initialize in-app purchases for mobile platforms
    if (!PlatformUtil.isPC() && !PlatformUtil.isWeb()) {
      try {
        asyncInitState();
      } catch (e) {
        log('$e');
      }
    }
    
    // Initialize tab preloading
    _preloadTabsAfterInit();
  }

  /// Handles app lifecycle state changes to manage Nostr connection
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        log("AppLifecycleState.resumed");
        // Reconnect to Nostr when app is resumed
        if (nostr != null) {
          nostr!.reconnect();
        }
        break;
      case AppLifecycleState.inactive:
        log("AppLifecycleState.inactive");
        break;
      case AppLifecycleState.detached:
        log("AppLifecycleState.detached");
        break;
      case AppLifecycleState.paused:
        log("AppLifecycleState.paused");
        break;
      case AppLifecycleState.hidden:
        log("AppLifecycleState.hidden");
        break;
    }
  }

  bool unlock = false;

  /// Handles initial authentication if lock is enabled
  @override
  Future<void> onReady(BuildContext context) async {
    if (settingsProvider.lockOpen == OpenStatus.open && !unlock) {
      doAuth();
    } else {
      setState(() {
        unlock = true;
      });
    }
  }

  @override
  Widget doBuild(BuildContext context) {
    mediaDataCache.update(context);
    
    // Note: This is critical. Rebuild this widget when settings change.
    Provider.of<SettingsProvider>(context);
    if (nostr == null) {
      return const LoginSignupWidget();
    }

    if (!unlock) {
      return const Scaffold();
    }

    // Listen to IndexProvider with rebuild on change for FAB
    var indexProvider = Provider.of<IndexProvider>(context, listen: true);
    debugPrint("IndexWidget rebuilding, current tab: ${indexProvider.currentTap}");
    
    indexProvider.setFollowTabController(followTabController);
    indexProvider.setGlobalTabController(globalsTabController);

    // Configure TabControllers
    _setupTabControllers(indexProvider);

    // Build the main content
    final mainIndex = _buildMainIndex(context, indexProvider);

    return _buildAppropriateLayout(context, mainIndex);
  }

  void _setupTabControllers(IndexProvider indexProvider) {
    indexProvider.setFollowTabController(followTabController);
    indexProvider.setGlobalTabController(globalsTabController);
  }

  Widget _buildMainIndex(BuildContext context, IndexProvider indexProvider) {
    final appBarContent = _buildAppBarContent(context, indexProvider);
    final mainContent = _buildMainContent(context, indexProvider);
    final musicPlayer = _buildMusicPlayer();

    return Stack(
      children: [
        Column(
          children: [
            IndexAppBar(
              center: appBarContent._center,
              right: appBarContent._right,
            ),
            mainContent,
          ],
        ),
        musicPlayer,
      ],
    );
  }

  // Helper class is defined outside of the widget class
  _AppBarContent _buildAppBarContent(BuildContext context, IndexProvider indexProvider) {
    final localization = S.of(context);
    final themeData = Theme.of(context);
    final titleTextColor = themeData.appBarTheme.titleTextStyle!.color;
    final titleTextStyle = TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: titleTextColor,
    );
    final indicatorColor = themeData.primaryColor;

    Widget? center;
    Widget? right;

    switch (indexProvider.currentTap) {
      case 0: // Communities
        // Build the toggle control for switching between grid and feed views
        center = _buildCommunityViewToggle(indexProvider, themeData);
        
        // Create community button with options
        right = GestureDetector(
          onTap: () {
            // Show the community options dialog instead of directly creating a community
            CommunityOptionsDialog.show(context);
          },
          child: const Icon(Icons.group_add),
        );
        break;
      case 1: // DMs
        center = TabBar(
          indicatorColor: indicatorColor,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.tab,
          dividerHeight: 0,
          tabs: [
            IndexTabItemWidget(
              localization.dms,
              titleTextStyle,
              omitText: "DM",
            ),
            IndexTabItemWidget(
              localization.request,
              titleTextStyle,
              omitText: "R",
            ),
          ],
          controller: dmTabController,
        );
        right = GestureDetector(
          onTap: () {
            _showSearchUserForDM(context);
          },
          child: const Icon(Icons.chat_rounded),
        );
        break;
      case 2: // Search
        center = Center(
          child: Text(
            localization.search,
            style: titleTextStyle,
          ),
        );
        break;
    }

    return _AppBarContent(center, right);
  }

  Widget _buildGroupsTabHeader(S localization, TextStyle titleTextStyle) {
    return Center(
      child: Text(
        localization.yourGroups,
        style: titleTextStyle,
      ),
    );
  }

  Widget _buildCreateGroupButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Show the community options dialog instead of directly creating a community
        CommunityOptionsDialog.show(context);
      },
      child: const Icon(Icons.group_add),
    );
  }

  Widget _buildGlobalsTabBar(S localization, TextStyle titleTextStyle, Color? indicatorColor) {
    return TabBar(
      indicatorColor: indicatorColor,
      indicatorWeight: 3,
      indicatorSize: TabBarIndicatorSize.tab,
      dividerHeight: 0,
      tabs: [
        IndexTabItemWidget(
          localization.notes,
          titleTextStyle,
          omitText: "N",
        ),
        IndexTabItemWidget(
          localization.users,
          titleTextStyle,
          omitText: "U",
        ),
        IndexTabItemWidget(
          localization.topics,
          titleTextStyle,
          omitText: "T",
        ),
      ],
      controller: globalsTabController,
    );
  }

  Widget _buildSearchTabHeader(S localization, TextStyle titleTextStyle) {
    return Center(
      child: Text(
        localization.search,
        style: titleTextStyle,
      ),
    );
  }

  Widget _buildDMTabBar(S localization, TextStyle titleTextStyle, Color? indicatorColor) {
    return TabBar(
      indicatorColor: indicatorColor,
      indicatorWeight: 3,
      indicatorSize: TabBarIndicatorSize.tab,
      dividerHeight: 0,
      tabs: [
        IndexTabItemWidget(
          localization.dms,
          titleTextStyle,
          omitText: "DM",
        ),
        IndexTabItemWidget(
          localization.request,
          titleTextStyle,
          omitText: "R",
        ),
      ],
      controller: dmTabController,
    );
  }

  // Cache for tab widgets with RepaintBoundary for better isolation
  final Map<int, Widget> _tabWidgets = {};
  
  // Tracks if we need to prefetch next tab
  int? _prefetchingTabIndex;
  
  // Used to track if tabs have been preloaded
  final Set<int> _preloadedTabs = {};
  
  // Preload tabs during initialization in overridden init method
  void _preloadTabsAfterInit() {
    // Pre-create all tabs during initialization to avoid lag during first switch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Preload the current tab immediately
      _createTabWidget(0);
      
      // Schedule preloading of other tabs with a delay to not block initial rendering
      Future.delayed(const Duration(milliseconds: 500), () {
        _preloadAllTabs();
      });
    });
  }
  
  // Preload all tabs in the background to avoid lag when switching
  void _preloadAllTabs() {
    // Only preload once
    if (_preloadedTabs.isNotEmpty) return;
    
    for (int i = 0; i < 3; i++) {
      _preloadedTabs.add(i);
      if (!_tabWidgets.containsKey(i)) {
        _createTabWidget(i);
      }
    }
  }
  
  Widget _buildMainContent(BuildContext context, IndexProvider indexProvider) {
    // Pre-fetching: if we're switching tabs, ensure the target tab is built
    if (indexProvider.previousTap != indexProvider.currentTap && 
        _prefetchingTabIndex != indexProvider.currentTap) {
      _prefetchingTabIndex = indexProvider.currentTap;
      
      // Schedule creation of the next tab in a microtask to avoid blocking UI
      Future.microtask(() {
        if (!_tabWidgets.containsKey(indexProvider.currentTap)) {
          _createTabWidget(indexProvider.currentTap);
        }
        _prefetchingTabIndex = null;
      });
    }
    
    // Ensure main tabs are created and cached
    if (!_tabWidgets.containsKey(indexProvider.currentTap)) {
      _createTabWidget(indexProvider.currentTap);
    }
    
    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child: Expanded(
        // IndexedStack preserves state better than Offstage + TickerMode
        // for complex widgets like CommunitiesScreen
        child: IndexedStack(
          index: indexProvider.currentTap,
          sizing: StackFit.expand,
          children: [
            // Wrap each tab in RepaintBoundary to isolate rendering
            RepaintBoundary(
              child: TickerMode(
                enabled: indexProvider.currentTap == 0,
                child: _tabWidgets[0] ?? const SizedBox.shrink(),
              ),
            ),
            RepaintBoundary(
              child: TickerMode(
                enabled: indexProvider.currentTap == 1,
                child: _tabWidgets[1] ?? const SizedBox.shrink(),
              ),
            ),
            RepaintBoundary(
              child: TickerMode(
                enabled: indexProvider.currentTap == 2,
                child: _tabWidgets[2] ?? const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Create and cache tab widgets with memory optimization
  void _createTabWidget(int tabIndex) {
    if (_tabWidgets.containsKey(tabIndex)) {
      return; // Already created, don't recreate
    }
    
    switch (tabIndex) {
      case 0:
        _tabWidgets[0] = const CommunitiesScreen();
        break;
      case 1:
        _tabWidgets[1] = DMWidget(tabController: dmTabController);
        break;
      case 2:
        _tabWidgets[2] = const SearchWidget();
        break;
    }
  }

  Widget _buildMusicPlayer() {
    return Positioned(
      bottom: Base.basePadding,
      left: 0,
      right: 0,
      child: Selector<MusicProvider, MusicInfo?>(
        builder: ((context, musicInfo, child) {
          if (musicInfo != null) {
            return MusicWidget(
              musicInfo,
              clearable: true,
            );
          }
          return Container();
        }),
        selector: (_, provider) => provider.musicInfo,
      ),
    );
  }

  Widget _buildAppropriateLayout(BuildContext context, Widget mainIndex) {
    final localization = S.of(context);
    
    // Make sure we're getting the latest state for tab changes
    final indexProvider = Provider.of<IndexProvider>(context);
    debugPrint("Building layout with current tab: ${indexProvider.currentTap}");
    
    if (TableModeUtil.isTableMode()) {
      return _buildTableModeLayout(context, mainIndex, localization);
    } else {
      return _buildMobileLayout(mainIndex);
    }
  }

  void _showSearchUserForDM(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text("Select User")),
          body: const SearchMentionUserWidget(),
        ),
      ),
    ).then((pubkey) {
      if (pubkey != null && pubkey is String) {
        // Use the DMProvider to create a new session or find an existing one
        final dmProvider = Provider.of<DMProvider>(context, listen: false);
        final dmDetail = dmProvider.findOrNewADetail(pubkey);
        
        // Navigate to the DM detail screen with the selected user
        RouterUtil.router(context, RouterPath.dmDetail, dmDetail);
      }
    });
  }

  Widget _buildMobileLayout(Widget mainIndex) {
    return Scaffold(
      body: mainIndex,
      drawer: const Drawer(
        child: IndexDrawerContent(
          smallMode: false,
        ),
      ),
    );
  }

  Widget _buildTableModeLayout(BuildContext context, Widget mainIndex, S localization) {
    final columnWidths = _calculateTableModeColumnWidths();
    
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (pcRouterFakeProvider.routerFakeInfos.isNotEmpty) {
          pcRouterFakeProvider.removeLast();
        }
      },
      child: Scaffold(
        body: Row(
          children: [
            IndexPcDrawerWrapper(
              fixWidth: columnWidths.column0Width,
            ),
            Container(
              width: columnWidths.column1Width,
              margin: const EdgeInsets.only(right: 1),
              child: mainIndex,
            ),
            Expanded(
              child: _buildRouterFakeContent(localization),
            ),
          ],
        ),
      ),
    );
  }

  _ColumnWidths _calculateTableModeColumnWidths() {
    final maxWidth = mediaDataCache.size.width;
    double column0Width = maxWidth * 2 / 5;
    double column1Width = maxWidth * 2 / 5;
    
    if (column0Width > IndexWidget.pcMaxColumn0) {
      column0Width = IndexWidget.pcMaxColumn0;
    }
    if (column1Width > IndexWidget.pcMaxColumn1) {
      column1Width = IndexWidget.pcMaxColumn1;
    }
    
    return _ColumnWidths(column0Width, column1Width);
  }

  Widget _buildRouterFakeContent(S localization) {
    return Selector<PcRouterFakeProvider, List<RouterFakeInfo>>(
      builder: (context, infos, child) {
        if (infos.isEmpty) {
          return Center(
            child: Text(localization.thereShouldBeAnUniverseHere),
          );
        }

        return IndexedStack(
          index: infos.length - 1,
          children: _buildRouterFakePages(context, infos),
        );
      },
      selector: (_, provider) => provider.routerFakeInfos,
      shouldRebuild: (previous, next) => previous != next,
    );
  }

  List<Widget> _buildRouterFakePages(BuildContext context, List<RouterFakeInfo> infos) {
    final pages = <Widget>[];
    
    for (var info in infos) {
      if (StringUtil.isNotBlank(info.routerPath) && routes[info.routerPath] != null) {
        final builder = routes[info.routerPath];
        if (builder != null) {
          pages.add(PcRouterFake(
            info: info,
            child: builder(context),
          ));
        }
      } else if (info.buildContent != null) {
        pages.add(PcRouterFake(
          info: info,
          child: info.buildContent!(context),
        ));
      }
    }
    
    return pages;
  }

  void doAuth() {
    AuthUtil.authenticate(context, S.of(context).pleaseAuthenticateToUseApp)
        .then((didAuthenticate) {
      if (didAuthenticate) {
        setState(() {
          unlock = true;
        });
      } else {
        doAuth();
      }
    });
  }

  StreamSubscription? _purchaseUpdatedSubscription;

  void asyncInitState() async {
    await FlutterInappPurchase.instance.initialize();
    _purchaseUpdatedSubscription =
        FlutterInappPurchase.purchaseUpdated.listen((productItem) async {
      if (productItem == null) {
        return;
      }

      try {
        if (Platform.isAndroid) {
          await FlutterInappPurchase.instance.finishTransaction(productItem);
        } else if (Platform.isIOS) {
          await FlutterInappPurchase.instance
              .finishTransactionIOS(productItem.transactionId!);
        }
      } catch (e) {
        log('$e');
      }
      log('purchase-updated: $productItem');
      BotToast.showText(text: "Thanks for your coffee!");
    });
  }

  @override
  void dispose() async {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
    // Cleanup in-app purchase subscriptions
    if (!PlatformUtil.isPC() && !PlatformUtil.isWeb()) {
      if (_purchaseUpdatedSubscription != null) {
        _purchaseUpdatedSubscription!.cancel();
        _purchaseUpdatedSubscription = null;
      }
      await FlutterInappPurchase.instance.finalize();
    }
  }
}

/// Helper class to hold appbar components
class _AppBarContent {
  final Widget? _center;
  final Widget? _right;
  
  _AppBarContent(this._center, this._right);
}

/// Helper class to hold column width values
class _ColumnWidths {
  final double column0Width;
  final double column1Width;
  
  _ColumnWidths(this.column0Width, this.column1Width);
}
