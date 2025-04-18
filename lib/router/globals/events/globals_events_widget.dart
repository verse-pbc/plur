import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/component/event_delete_callback.dart';
import 'package:nostrmo/component/keep_alive_cust_state.dart';
import 'package:provider/provider.dart';

import '../../../component/event/event_list_widget.dart';
import '../../../component/placeholder/event_list_placeholder.dart';
import '../../../consts/base.dart';
import '../../../consts/base_consts.dart';
import '../../../main.dart';
import '../../../provider/settings_provider.dart';
import '../../../util/dio_util.dart';
import '../../../util/table_mode_util.dart';

class GlobalsEventsWidget extends StatefulWidget {
  const GlobalsEventsWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return _GlobalsEventsWidgetState();
  }
}

class _GlobalsEventsWidgetState extends KeepAliveCustState<GlobalsEventsWidget>
    with PendingEventsLaterFunction {
  ScrollController scrollController = ScrollController();

  List<String> ids = [];

  EventMemBox eventBox = EventMemBox(sortAfterAdd: false);

  @override
  Widget doBuild(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    if (eventBox.isEmpty()) {
      return EventListPlaceholder(
        onRefresh: refresh,
      );
    }

    var list = eventBox.all();

    var main = EventDeleteCallback(
      onDeleteCallback: onDeleteCallback,
      child: ListView.builder(
        controller: scrollController,
        itemBuilder: (context, index) {
          var event = list[index];
          return EventListWidget(
            event: event,
            showVideo: settingsProvider.videoPreviewInList != OpenStatus.close,
          );
        },
        itemCount: list.length,
      ),
    );

    if (TableModeUtil.isTableMode()) {
      return GestureDetector(
        onVerticalDragUpdate: (detail) {
          scrollController.jumpTo(scrollController.offset - detail.delta.dy);
        },
        behavior: HitTestBehavior.translucent,
        child: main,
      );
    }

    return main;
  }

  var subscribeId = StringUtil.rndNameStr(16);

  @override
  Future<void> onReady(BuildContext context) async {
    indexProvider.setEventScrollController(scrollController);
    refresh();
  }

  Future<void> refresh() async {
    if (StringUtil.isNotBlank(subscribeId)) {
      unsubscribe();
    }

    var str = await DioUtil.getStr(Base.indexsEvents);

    if (StringUtil.isNotBlank(str)) {
      ids.clear();
      var itfs = jsonDecode(str!);
      for (var itf in itfs) {
        ids.add(itf as String);
      }
    }

    var filter = Filter(ids: ids, kinds: [EventKind.textNote]);
    nostr!.subscribe([filter.toJson()], (event) {
      if (eventBox.isEmpty()) {
        laterTimeMS = 200;
      } else {
        laterTimeMS = 1000;
      }

      later(event, (list) {
        eventBox.addList(list);
        setState(() {});
      }, null);
    }, id: subscribeId);
  }

  void unsubscribe() {
    try {
      nostr!.unsubscribe(subscribeId);
    } catch (_) {}
  }

  @override
  void dispose() {
    super.dispose();

    unsubscribe();
    disposeLater();
  }

  onDeleteCallback(Event event) {
    eventBox.delete(event.id);
    setState(() {});
  }
}
