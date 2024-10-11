import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:nostr_sdk/event.dart';
import 'package:nostr_sdk/event_kind.dart';
import 'package:nostr_sdk/event_mem_box.dart';
import 'package:nostr_sdk/event_relation.dart';
import 'package:nostr_sdk/utils/peddingevents_later_function.dart';
import 'package:nostr_sdk/utils/when_stop_function.dart';

import '../../main.dart';
import 'package:nostr_sdk/utils/string_util.dart';
import 'thread_detail_event.dart';

mixin ThreadRouterHelper<T extends StatefulWidget>
    on State<T>, WhenStopFunction, PenddingEventsLaterFunction {
  EventMemBox box = EventMemBox();

  GlobalKey sourceEventKey = GlobalKey();

  List<ThreadDetailEvent> rootSubList = [];

  String? forceParentId;

  void listToTree({bool refresh = true}) {
    // event in box had been sorted. The last one is the oldest.
    var all = box.all();
    var length = all.length;
    List<ThreadDetailEvent> _rootSubList = [];
    // key - id, value - item
    Map<String, ThreadDetailEvent> itemMap = {};
    for (var i = length - 1; i > -1; i--) {
      var event = all[i];
      var relation = EventRelation.fromEvent(event);
      var item = ThreadDetailEvent(event: event, relation: relation);
      itemMap[event.id] = item;
    }

    for (var i = length - 1; i > -1; i--) {
      var event = all[i];
      var item = itemMap[event.id]!;
      var relation = item.relation;

      if (StringUtil.isBlank(forceParentId)) {
        // is not reply page
        if (relation.replyId == null) {
          _rootSubList.add(item);
        } else {
          var replyItem = itemMap[relation.replyId];
          if (replyItem == null) {
            _rootSubList.add(item);
          } else {
            replyItem.subItems.add(item);
          }
        }
      } else {
        // this is reply page
        if (relation.replyId != null) {
          if (relation.replyId == forceParentId) {
            // reply the forceParentId, set as root
            _rootSubList.add(item);
          } else {
            var replyItem = itemMap[relation.replyId];
            if (replyItem != null) {
              replyItem.subItems.add(item);
            }
          }
        }
      }
    }

    rootSubList = _rootSubList;
    rootSubList.sort((tde1, tde2) {
      return tde1.event.createdAt - tde2.event.createdAt;
    });
    for (var rootSub in rootSubList) {
      rootSub.handleTotalLevelNum(0);
    }

    if (refresh) {
      setState(() {});
      scrollToSourceEvent();
    }
  }

  void scrollToSourceEvent() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (sourceEventKey.currentContext != null) {
        Scrollable.ensureVisible(sourceEventKey.currentContext!);
      }
    });
    whenStop(() {
      if (sourceEventKey.currentContext != null) {
        Scrollable.ensureVisible(sourceEventKey.currentContext!);
      }
    });
  }

  void onEvent(Event event) {
    wotProvider.addTempFromEvent(event);

    if (event.kind == EventKind.ZAP && StringUtil.isBlank(event.content)) {
      var innerZapContent = EventRelation.getInnerZapContent(event);
      if (StringUtil.isBlank(innerZapContent)) {
        return;
      }
    }

    later(event, (list) {
      box.addList(list);
      listToTree();
      eventReactionsProvider.onEvents(list);
    }, null);
  }

  @override
  void dispose() {
    super.dispose();
    disposeLater();
  }

  onReplyCallback(Event event) {
    onEvent(event);
  }
}
