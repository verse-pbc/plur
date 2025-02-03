import 'dart:async';
import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:nostr_sdk/utils/platform_util.dart';
import 'package:nostr_sdk/utils/string_util.dart';
import 'package:nostrmo/component/music/music_widget.dart';
import 'package:nostrmo/component/cust_state.dart';
import 'package:nostrmo/component/pc_router_fake.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/consts/base_consts.dart';
import 'package:nostrmo/provider/music_provider.dart';
import 'package:nostrmo/provider/pc_router_fake_provider.dart';
import 'package:nostrmo/router/follow_suggest/follow_suggest_widget.dart';
import 'package:nostrmo/router/index/index_pc_drawer_wrapper.dart';
import 'package:provider/provider.dart';

import '../../generated/l10n.dart';
import '../../main.dart';
import '../../provider/index_provider.dart';
import '../../provider/setting_provider.dart';
import '../../util/auth_util.dart';
import '../../util/table_mode_util.dart';
import '../dm/dm_widget.dart';
import '../edit/editor_widget.dart';
import '../follow/follow_index_widget.dart';
import '../group/communities_widget.dart';
import '../login/login_widget.dart';
import '../search/search_widget.dart';
import 'index_app_bar.dart';
import 'index_bottom_bar.dart';
import 'index_drawer_content.dart';
import 'index_tab_item_widget.dart';

class IndexWidget extends StatefulWidget {
  static double PC_MAX_COLUMN_0 = 200;

  static double PC_MAX_COLUMN_1 = 550;

  Function reload;

  IndexWidget({super.key, required this.reload});

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

    WidgetsBinding.instance.addObserver(this);

    if (settingProvider.defaultTab != null) {
      if (settingProvider.defaultIndex == 1) {
        globalsInitTab = settingProvider.defaultTab!;
      } else {
        followInitTab = settingProvider.defaultTab!;
      }
    }

    followTabController =
        TabController(initialIndex: followInitTab, length: 3, vsync: this);
    globalsTabController =
        TabController(initialIndex: globalsInitTab, length: 3, vsync: this);
    dmTabController = TabController(length: 2, vsync: this);

    if (!PlatformUtil.isPC() && !PlatformUtil.isWeb()) {
      try {
        asyncInitState();
      } catch (e) {
        print(e);
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        print("AppLifecycleState.resumed");
        if (nostr != null) {
          nostr!.reconnect();
        }
        break;
      case AppLifecycleState.inactive:
        print("AppLifecycleState.inactive");
        break;
      case AppLifecycleState.detached:
        print("AppLifecycleState.detached");
        break;
      case AppLifecycleState.paused:
        print("AppLifecycleState.paused");
        break;
      case AppLifecycleState.hidden:
        print("AppLifecycleState.hidden");
        break;
    }
  }

  @override
  Future<void> onReady(BuildContext context) async {
    if (settingProvider.lockOpen == OpenStatus.OPEN && !unlock) {
      doAuth();
    } else {
      setState(() {
        unlock = true;
      });
    }
  }

  bool unlock = false;

  @override
  Widget doBuild(BuildContext context) {
    mediaDataCache.update(context);
    final localization = S.of(context);

    final settingProvider = Provider.of<SettingProvider>(context);
    if (nostr == null) {
      return LoginSignupWidget();
    }

    if (!unlock) {
      return Scaffold();
    }

    var indexProvider = Provider.of<IndexProvider>(context);
    indexProvider.setFollowTabController(followTabController);
    indexProvider.setGlobalTabController(globalsTabController);
    final themeData = Theme.of(context);
    var titleTextColor = themeData.appBarTheme.titleTextStyle!.color;
    var titleTextStyle = TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: titleTextColor,
    );
    Color? indicatorColor = themeData.primaryColor;

    Widget? appBarCenter;
    if (indexProvider.currentTap == 0) {
      appBarCenter = Center(
        child: Text(
          'Communities',
          style: titleTextStyle,
        ),
      );
    } else if (indexProvider.currentTap == 1) {
      appBarCenter = TabBar(
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
    } else if (indexProvider.currentTap == 2) {
      appBarCenter = Center(
        child: Text(
          localization.Search,
          style: titleTextStyle,
        ),
      );
    } else if (indexProvider.currentTap == 3) {
      appBarCenter = TabBar(
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

    var mainCenterWidget = MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child: Expanded(
          child: IndexedStack(
        index: indexProvider.currentTap,
        children: [
          const CommunitiesWidget(),
          const SearchWidget(),
          DMWidget(
            tabController: dmTabController,
          ),
        ],
      )),
    );

    List<Widget> mainIndexList = [
      Column(
        children: [
          IndexAppBar(
            center: appBarCenter,
          ),
          mainCenterWidget,
        ],
      ),
      Positioned(
        bottom: Base.BASE_PADDING,
        left: 0,
        right: 0,
        child: Selector<MusicProvider, MusicInfo?>(
          builder: ((context, musicInfo, child) {
            if (musicInfo != null) {
              return MusicWidget(
                musicInfo,
                clearAble: true,
              );
            }

            return Container();
          }),
          selector: (_, provider) {
            return provider.musicInfo;
          },
        ),
      )
    ];
    Widget mainIndex = Stack(
      children: mainIndexList,
    );

    if (TableModeUtil.isTableMode()) {
      var maxWidth = mediaDataCache.size.width;
      double column0Width = maxWidth * 1 / 5;
      double column1Width = maxWidth * 2 / 5;
      if (column0Width > IndexWidget.PC_MAX_COLUMN_0) {
        column0Width = IndexWidget.PC_MAX_COLUMN_0;
      }
      if (column1Width > IndexWidget.PC_MAX_COLUMN_1) {
        column1Width = IndexWidget.PC_MAX_COLUMN_1;
      }

      var mainScaffold = Scaffold(
        // floatingActionButton: addBtn,
        // floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        body: Row(children: [
          IndexPcDrawerWrapper(
            fixWidth: column0Width,
          ),
          Container(
            width: column1Width,
            margin: const EdgeInsets.only(
              right: 1,
            ),
            child: mainIndex,
          ),
          Expanded(
            child: Selector<PcRouterFakeProvider, List<RouterFakeInfo>>(
              builder: (context, infos, child) {
                if (infos.isEmpty) {
                  return Center(
                    child: Text(localization.There_should_be_an_universe_here),
                  );
                }

                List<Widget> pages = [];
                for (var info in infos) {
                  if (StringUtil.isNotBlank(info.routerPath) &&
                      routes[info.routerPath] != null) {
                    var builder = routes[info.routerPath];
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

                return IndexedStack(
                  index: pages.length - 1,
                  children: pages,
                );
              },
              selector: (_, provider) {
                return provider.routerFakeInfos;
              },
              shouldRebuild: (previous, next) {
                if (previous != next) {
                  return true;
                }
                return false;
              },
            ),
          )
        ]),
      );

      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (pcRouterFakeProvider.routerFakeInfos.isNotEmpty) {
            pcRouterFakeProvider.removeLast();
          }
        },
        child: mainScaffold,
      );
    } else {
      return Scaffold(
        body: mainIndex,
        drawer: Drawer(
          child: IndexDrawerContentComponnent(
            smallMode: false,
          ),
        ),
      );
    }
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
        print(e);
      }
      print('purchase-updated: $productItem');
      BotToast.showText(text: "Thanks yours coffee!");
    });
  }

  @override
  void dispose() async {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
    if (!PlatformUtil.isPC() && !PlatformUtil.isWeb()) {
      if (_purchaseUpdatedSubscription != null) {
        _purchaseUpdatedSubscription!.cancel();
        _purchaseUpdatedSubscription = null;
      }
      await FlutterInappPurchase.instance.finalize();
    }
  }
}
