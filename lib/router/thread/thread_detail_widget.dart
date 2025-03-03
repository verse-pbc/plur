import 'package:flutter/material.dart';
import 'package:nostrmo/nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/provider/replaceable_event_provider.dart';
import 'package:nostrmo/provider/single_event_provider.dart';
import 'package:provider/provider.dart';
import 'package:widget_size/widget_size.dart';

import '../../component/appbar_back_btn_widget.dart';
import '../../component/cust_state.dart';
import '../../component/event/event_list_widget.dart';
import '../../component/event/event_load_list_widget.dart';
import '../../component/event_reply_callback.dart';
import '../../component/user/simple_name_widget.dart';
import '../../consts/base.dart';
import '../../main.dart';
import '../../util/router_util.dart';
import '../../util/table_mode_util.dart';
import 'thread_detail_event_main_widget.dart';
import 'thread_detail_item_widget.dart';
import 'thread_router_helper.dart';

class ThreadDetailWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _ThreadDetailWidgetState();
  }

  static String getAppBarTitle(Event event) {
    return event.content.replaceAll("\n", " ").replaceAll("\r", " ");
  }

  static Widget detailAppBarTitle(
      String pubkey, String title, ThemeData themeData) {
    var bodyLargeFontSize = themeData.textTheme.bodyLarge!.fontSize;

    List<Widget> appBarTitleList = [];
    var nameComponnet = SimpleNameWidget(
      pubkey: pubkey,
      textStyle: TextStyle(
        fontSize: bodyLargeFontSize,
        color: themeData.appBarTheme.titleTextStyle!.color,
      ),
    );
    appBarTitleList.add(nameComponnet);
    appBarTitleList.add(const Text(" : "));
    appBarTitleList.add(Expanded(
        child: Text(
      title,
      style: TextStyle(
        overflow: TextOverflow.ellipsis,
        fontSize: bodyLargeFontSize,
      ),
    )));
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: appBarTitleList,
    );
  }
}

class _ThreadDetailWidgetState extends CustState<ThreadDetailWidget>
    with PenddingEventsLaterFunction, WhenStopFunction, ThreadRouterHelper {
  Event? sourceEvent;

  bool showTitle = false;

  final ScrollController _controller = ScrollController();

  double rootEventHeight = 120;

  String? titlePubkey;

  String? title;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (_controller.offset > rootEventHeight * 0.5 && !showTitle) {
        setState(() {
          showTitle = true;
        });
      } else if (_controller.offset < rootEventHeight * 0.5 && showTitle) {
        setState(() {
          showTitle = false;
        });
      }
    });
  }

  void initFromArgs() {
    // do some init oper
    var eventRelation = EventRelation.fromEvent(sourceEvent!);
    rootId = eventRelation.rootId;
    rootEventRelayAddr = eventRelation.rootRelayAddr;
    if (eventRelation.aId != null &&
        eventRelation.aId!.kind == EventKind.LONG_FORM) {
      aId = eventRelation.aId;
    }
    if (rootId == null) {
      if (aId == null) {
        if (eventRelation.replyId != null) {
          rootId = eventRelation.replyId;
        } else {
          // source event is root event
          rootId = sourceEvent!.id;
          rootEvent = sourceEvent!;
        }
      } else {
        // aid linked root event
        rootEvent = replaceableEventProvider.getEvent(aId!);
        if (rootEvent != null) {
          rootId = rootEvent!.id;
        }
      }
    }
    if (rootEvent != null && StringUtil.isNotBlank(eventRelation.dTag)) {
      aId = AId(
          kind: rootEvent!.kind,
          pubkey: rootEvent!.pubkey,
          title: eventRelation.dTag!);
    }

    // load replies from cache and avoid blank page
    {
      var eventReactions =
          eventReactionsProvider.get(sourceEvent!.id, avoidPull: true);
      if (eventReactions != null && eventReactions.replies.isNotEmpty) {
        box.addList(eventReactions.replies);
      }
    }
    if (rootId != null && rootId != sourceEvent!.id) {
      var eventReactions = eventReactionsProvider.get(rootId!, avoidPull: true);
      if (eventReactions != null && eventReactions.replies.isNotEmpty) {
        box.addList(eventReactions.replies);
      }
    }
    if (rootEvent == null) {
      box.add(sourceEvent!);
    }

    // try to handle temp wot filter
    wotProvider.addTempFromEvents(box.all());

    // make list to tree
    listToTree(refresh: false);
  }

  @override
  Widget doBuild(BuildContext context) {
    if (sourceEvent == null) {
      var obj = RouterUtil.routerArgs(context);
      if (obj != null && obj is Event) {
        sourceEvent = obj;
      }
      if (sourceEvent == null) {
        RouterUtil.back(context);
        return Container();
      }

      initFromArgs();
    } else {
      var obj = RouterUtil.routerArgs(context);
      if (obj != null && obj is Event) {
        if (obj.id != sourceEvent!.id) {
          // arg change! reset.
          sourceEvent = null;
          rootId = null;
          rootEvent = null;
          box = EventMemBox();
          rootSubList = [];

          sourceEvent = obj;
          initFromArgs();
          doQuery();
        }
      }
    }

    final themeData = Theme.of(context);

    Widget? appBarTitle;
    if (rootEvent != null) {
      titlePubkey = rootEvent!.pubkey;
      title = ThreadDetailWidget.getAppBarTitle(rootEvent!);
    }
    if (showTitle) {
      if (StringUtil.isNotBlank(titlePubkey) && StringUtil.isNotBlank(title)) {
        appBarTitle = ThreadDetailWidget.detailAppBarTitle(
            titlePubkey!, title!, themeData);
      }
    }

    Widget? rootEventWidget;
    if (rootEvent == null) {
      if (StringUtil.isNotBlank(rootId)) {
        rootEventWidget = Selector<SingleEventProvider, Event?>(
            builder: (context, event, child) {
          if (event == null) {
            return EventLoadListWidget();
          }

          titlePubkey = event.pubkey;
          title = ThreadDetailWidget.getAppBarTitle(event);

          {
            // check if the rootEvent isn't rootEvent
            var newRelation = EventRelation.fromEvent(event);
            String? newRootId;
            String? newRootEventRelayAddr;
            if (newRelation.rootId != null) {
              newRootId = newRelation.rootId;
              newRootEventRelayAddr = newRelation.rootRelayAddr;
            } else if (newRelation.replyId != null) {
              newRootId = newRelation.replyId;
              newRootEventRelayAddr = newRelation.replyRelayAddr;
            }

            if (StringUtil.isNotBlank(newRootId)) {
              rootId = newRootId;
              rootEventRelayAddr = newRootEventRelayAddr;
              doQuery();
              singleEventProvider.getEvent(newRootId!,
                  eventRelayAddr: newRootEventRelayAddr);
            }
          }

          return EventListWidget(
            event: event,
            jumpable: false,
            showVideo: true,
            imageListMode: false,
            showLongContent: true,
          );
        }, selector: (context, provider) {
          return provider.getEvent(rootId!, eventRelayAddr: rootEventRelayAddr);
        });
      } else if (aId != null) {
        rootEventWidget = Selector<ReplaceableEventProvider, Event?>(
            builder: (context, event, child) {
          if (event == null) {
            return EventLoadListWidget();
          }

          if (rootId != null) {
            // find the root event now! try to load data again!
            rootId = event.id;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              doQuery();
            });
          }

          titlePubkey = event.pubkey;
          title = ThreadDetailWidget.getAppBarTitle(event);

          return EventListWidget(
            event: event,
            jumpable: false,
            showVideo: true,
            imageListMode: false,
            showLongContent: true,
          );
        }, selector: (context, provider) {
          return provider.getEvent(aId!);
        });
      } else {
        rootEventWidget = Container();
      }
    } else {
      rootEventWidget = EventListWidget(
        event: rootEvent!,
        jumpable: false,
        showVideo: true,
        imageListMode: false,
        showLongContent: true,
      );
    }

    List<Widget> mainList = [];

    mainList.add(WidgetSize(
      child: rootEventWidget,
      onChange: (size) {
        rootEventHeight = size.height;
      },
    ));

    for (var item in rootSubList) {
      var totalLevelNum = item.totalLevelNum;
      var needWidth = (totalLevelNum - 1) *
              (Base.BASE_PADDING +
                  ThreadDetailItemMainWidget.BORDER_LEFT_WIDTH) +
          ThreadDetailItemMainWidget.EVENT_MAIN_MIN_WIDTH;
      if (needWidth > mediaDataCache.size.width) {
        mainList.add(SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: needWidth,
            child: ThreadDetailItemWidget(
              item: item,
              totalMaxWidth: needWidth,
              sourceEventId: sourceEvent!.id,
              sourceEventKey: sourceEventKey,
            ),
          ),
        ));
      } else {
        mainList.add(ThreadDetailItemWidget(
          item: item,
          totalMaxWidth: needWidth,
          sourceEventId: sourceEvent!.id,
          sourceEventKey: sourceEventKey,
        ));
      }
    }

    Widget main = ListView(
      controller: _controller,
      children: mainList,
    );

    if (TableModeUtil.isTableMode()) {
      main = GestureDetector(
        onVerticalDragUpdate: (detail) {
          _controller.jumpTo(_controller.offset - detail.delta.dy);
        },
        behavior: HitTestBehavior.translucent,
        child: main,
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: const AppbarBackBtnWidget(),
        title: appBarTitle,
      ),
      body: EventReplyCallback(
        onReplyCallback: onReplyCallback,
        child: main,
      ),
    );
  }

  @override
  Future<void> onReady(BuildContext context) async {
    doQuery();
  }

  void doQuery() {
    if (StringUtil.isNotBlank(rootId)) {
      // if (rootEvent == null) {
      //   // source event isn't root event，query root event
      //   var filter = Filter(ids: [rootId!]);
      //   nostr!.query([filter.toJson()], onRootEvent);
      // }

      List<int> replyKinds = [...EventKind.SUPPORTED_EVENTS]
        ..remove(EventKind.REPOST)
        ..remove(EventKind.LONG_FORM)
        ..add(EventKind.ZAP);

      // query sub events
      var filter = Filter(e: [rootId!], kinds: replyKinds);

      var filters = [filter.toJson()];
      if (aId != null) {
        var f = Filter(kinds: replyKinds);
        var m = f.toJson();
        m["#a"] = [aId!.toAString()];
        filters.add(m);
      }

      // print(filters);

      nostr!.query(filters, onEvent);
    }
  }

  AId? aId;

  String? rootId;

  String? rootEventRelayAddr;

  Event? rootEvent;
}
