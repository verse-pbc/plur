import 'dart:async';
import 'dart:io';
import 'dart:developer';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/component/music/music_widget.dart';
import 'package:nostrmo/component/cust_state.dart';
import 'package:nostrmo/component/pc_router_fake.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/consts/base_consts.dart';
import 'package:nostrmo/provider/music_provider.dart';
import 'package:nostrmo/provider/pc_router_fake_provider.dart';
import 'package:nostrmo/router/index/index_pc_drawer_wrapper.dart';
import 'package:provider/provider.dart';

import '../../generated/l10n.dart';
import '../../main.dart';
import '../../provider/index_provider.dart';
import '../../provider/settings_provider.dart';
import '../../util/auth_util.dart';
import '../../util/table_mode_util.dart';
import '../dm/dm_widget.dart';
import '../group/communities_widget.dart';
import '../group/create_community_dialog.dart';
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

    var indexProvider = Provider.of<IndexProvider>(context);
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
      case 0: // Groups
        center = _buildGroupsTabHeader(localization, titleTextStyle);
        right = _buildCreateGroupButton(context);
        break;
      case 1: // Globals
        center = _buildGlobalsTabBar(localization, titleTextStyle, indicatorColor);
        break;
      case 2: // Search
        center = _buildSearchTabHeader(localization, titleTextStyle);
        break;
      case 3: // DMs
        center = _buildDMTabBar(localization, titleTextStyle, indicatorColor);
        break;
    }

    return _AppBarContent(center, right);
  }

  Widget _buildGroupsTabHeader(S localization, TextStyle titleTextStyle) {
    return Center(
      child: Text(
        localization.Your_Groups,
        style: titleTextStyle,
      ),
    );
  }

  Widget _buildCreateGroupButton(BuildContext context) {
    return GestureDetector(
      onTap: () => CreateCommunityDialog.show(context),
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
          localization.Notes,
          titleTextStyle,
          omitText: "N",
        ),
        IndexTabItemWidget(
          localization.Users,
          titleTextStyle,
          omitText: "U",
        ),
        IndexTabItemWidget(
          localization.Topics,
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
        localization.Search,
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
          localization.DMs,
          titleTextStyle,
          omitText: "DM",
        ),
        IndexTabItemWidget(
          localization.Request,
          titleTextStyle,
          omitText: "R",
        ),
      ],
      controller: dmTabController,
    );
  }

  Widget _buildMainContent(BuildContext context, IndexProvider indexProvider) {
    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child: Expanded(
        child: IndexedStack(
          index: indexProvider.currentTap,
          children: [
            const CommunitiesWidget(),
            const SizedBox(), // This should be where GlobalsTabView would go
            const SearchWidget(),
            DMWidget(
              tabController: dmTabController,
            ),
          ],
        ),
      ),
    );
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
    
    if (TableModeUtil.isTableMode()) {
      return _buildTableModeLayout(context, mainIndex, localization);
    } else {
      return _buildMobileLayout(mainIndex);
    }
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
            child: Text(localization.There_should_be_an_universe_here),
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
    AuthUtil.authenticate(context, S.of(context).Please_authenticate_to_use_app)
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
