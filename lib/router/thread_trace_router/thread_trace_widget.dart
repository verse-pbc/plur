
import 'package:flutter/material.dart';
import 'package:nostrmo/nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/router/thread_trace_router/event_trace_info.dart';
import 'package:nostrmo/router/thread_trace_router/thread_trace_event_widget.dart';

import '../../component/appbar_back_btn_widget.dart';
import '../../component/event/event_bitcoin_icon_widget.dart';
import '../../component/event_reply_callback.dart';
import '../../consts/base.dart';
import '../../util/router_util.dart';
import '../../util/table_mode_util.dart';
import '../thread/thread_detail_event_main_widget.dart';
import '../thread/thread_detail_item_widget.dart';
import '../thread/thread_detail_widget.dart';
import '../thread/thread_router_helper.dart';

class ThreadTraceWidget extends StatefulWidget {
  const ThreadTraceWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return _ThreadTraceWidgetState();
  }
}

class _ThreadTraceWidgetState extends State<ThreadTraceWidget>
    with PenddingEventsLaterFunction, WhenStopFunction, ThreadRouterHelper {
  // used to filter parent events
  List<EventTraceInfo> parentEventTraces = [];

  Event? sourceEvent;

  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var arg = RouterUtil.routerArgs(context);
    if (arg == null || arg is! Event) {
      RouterUtil.back(context);
      return Container();
    }
    if (sourceEvent == null) {
      // first load
      sourceEvent = arg;
      fetchDatas();
    } else {
      if (sourceEvent!.id != arg.id) {
        // find update
        sourceEvent = arg;
        fetchDatas();
      }
    }

    final themeData = Theme.of(context);
    var cardColor = themeData.cardColor;

    var title = ThreadDetailWidget.getAppBarTitle(sourceEvent!);
    var appBarTitle = ThreadDetailWidget.detailAppBarTitle(
        sourceEvent!.pubkey, title, themeData);

    List<Widget> mainList = [];

    List<Widget> traceList = [];
    if (parentEventTraces.isNotEmpty) {
      var length = parentEventTraces.length;
      for (var i = 0; i < length; i++) {
        var pet = parentEventTraces[length - 1 - i];

        traceList.add(GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            RouterUtil.router(
                context, RouterPath.getThreadDetailPath(), pet.event);
          },
          child: ThreadTraceEventWidget(
            pet.event,
            textOnTap: () {
              RouterUtil.router(
                  context, RouterPath.getThreadDetailPath(), pet.event);
            },
          ),
        ));
      }
    }

    Widget mainEventWidget = ThreadTraceEventWidget(
      sourceEvent!,
      key: sourceEventKey,
      traceMode: false,
    );
    if (sourceEvent!.kind == EventKind.ZAP) {
      mainEventWidget = EventBitcoinIconWidget.wrapper(mainEventWidget);
    }

    mainList.add(Container(
      color: cardColor,
      margin: const EdgeInsets.only(bottom: Base.BASE_PADDING_HALF),
      padding: const EdgeInsets.only(top: Base.BASE_PADDING_HALF),
      child: Column(
        children: [
          Stack(
            children: [
              Positioned(
                top: 38,
                bottom: 0,
                left: 28,
                child: Container(
                  width: 2,
                  color: themeData.hintColor.withOpacity(0.25),
                ),
              ),
              Column(
                children: traceList,
              ),
            ],
          ),
          mainEventWidget
        ],
      ),
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

  void fetchDatas() {
    box.clear();
    parentEventTraces.clear();
    rootSubList.clear();
    forceParentId = null;
    sourceEventKey = GlobalKey();

    wotProvider.addTempFromEvent(sourceEvent!);

    // find parent data
    var eventRelation = EventRelation.fromEvent(sourceEvent!);
    var replyId = eventRelation.replyOrRootId;
    if (StringUtil.isNotBlank(replyId)) {
      // this query move onReplyQueryComplete function call, avoid query limit.

      // this sourceEvent has parent event, so it is reply event, only show the sub reply events.
      forceParentId = sourceEvent!.id;
    }

    // find reply data
    AId? aId;
    if (eventRelation.aId != null &&
        eventRelation.aId!.kind == EventKind.LONG_FORM) {
      aId = eventRelation.aId;
    }

    List<int> replyKinds = [...EventKind.SUPPORTED_EVENTS]
      ..remove(EventKind.REPOST)
      ..remove(EventKind.LONG_FORM)
      ..add(EventKind.ZAP);

    // query sub events
    var parentIds = [sourceEvent!.id];
    if (StringUtil.isNotBlank(eventRelation.rootId)) {
      // only the query from root can query all sub replies.
      parentIds.add(eventRelation.rootId!);
    }
    var filter = Filter(e: parentIds, kinds: replyKinds);

    var filters = [filter.toJson()];
    if (aId != null) {
      var f = Filter(kinds: replyKinds);
      var m = f.toJson();
      m["#a"] = [aId.toAString()];
      filters.add(m);
    }

    List<String> tempRelays = [];
    if (StringUtil.isNotBlank(eventRelation.replyOrRootRelayAddr)) {
      var eventRelays = nostr!
          .getExtralReadableRelays([eventRelation.replyOrRootRelayAddr!], 1);
      tempRelays.addAll(eventRelays);
    }
    if (StringUtil.isNotBlank(eventRelation.pubkey)) {
      var subEventPubkeyRelays =
          metadataProvider.getExtralRelays(eventRelation.pubkey, false);
      tempRelays.addAll(subEventPubkeyRelays);
    }

    beginQueryParentFlag = false;
    nostr!.query(filters, onEvent,
        onComplete: beginQueryParent, tempRelays: tempRelays);
    Future.delayed(const Duration(seconds: 1)).then((value) {
      // avoid query onComplete no callback.
      beginQueryParent();
    });
  }

  var beginQueryParentFlag = false;

  void beginQueryParent() {
    if (!beginQueryParentFlag) {
      beginQueryParentFlag = true;
      var eventRelation = EventRelation.fromEvent(sourceEvent!);
      var replyId = eventRelation.replyOrRootId;
      if (StringUtil.isNotBlank(replyId)) {
        findParentEvent(replyId!,
            eventRelayAddr: eventRelation.replyOrRootRelayAddr,
            subEventPubkey: sourceEvent!.pubkey);
      }
    }
  }

  String parentEventId(String eventId) {
    return "eventTrace${eventId.substring(0, 8)}";
  }

  void findParentEvent(String eventId,
      {String? eventRelayAddr, String? subEventPubkey}) {
    // log("findParentEvent $eventId");
    // query from reply events
    var pe = box.getById(eventId);
    if (pe != null) {
      onParentEvent(pe);
      return;
    }

    // query from singleEventProvider
    pe = singleEventProvider.getEvent(eventId, queryData: false);
    if (pe != null) {
      onParentEvent(pe);
      return;
    }

    var filter = Filter(ids: [eventId]);
    List<String> tempRelays = [];
    if (StringUtil.isNotBlank(eventRelayAddr)) {
      var eventRelays = nostr!.getExtralReadableRelays([eventRelayAddr!], 1);
      tempRelays.addAll(eventRelays);
    }
    if (StringUtil.isNotBlank(subEventPubkey)) {
      var subEventPubkeyRelays =
          metadataProvider.getExtralRelays(subEventPubkey!, false);
      tempRelays.addAll(subEventPubkeyRelays);
    }
    nostr!.query([filter.toJson()], onParentEvent,
        id: parentEventId(eventId), tempRelays: tempRelays);
  }

  void onParentEvent(Event e) {
    singleEventProvider.onEvent(e);

    EventTraceInfo? addedEti;
    if (parentEventTraces.isEmpty) {
      addedEti = EventTraceInfo(e);
      parentEventTraces.add(addedEti);
    } else {
      if (parentEventTraces.last.eventRelation.replyOrRootId == e.id) {
        addedEti = EventTraceInfo(e);
        parentEventTraces.add(addedEti);
      }
    }

    if (addedEti != null) {
      // a new event find, try to find a new parent event
      var replyId = addedEti.eventRelation.replyOrRootId;
      if (StringUtil.isNotBlank(replyId)) {
        findParentEvent(replyId!,
            eventRelayAddr: addedEti.eventRelation.replyOrRootRelayAddr,
            subEventPubkey: addedEti.event.pubkey);
      }

      setState(() {});
      scrollToSourceEvent();
    }
  }
}
