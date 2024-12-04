import 'package:flutter/material.dart';
import 'package:nostr_sdk/event_kind.dart';
import 'package:nostrmo/provider/setting_provider.dart';
import 'package:provider/provider.dart';

import '../../component/event/event_bitcion_icon_component.dart';
import '../../consts/base.dart';
import 'thread_detail_event.dart';
import 'thread_detail_event_main_component.dart';

class ThreadDetailItemWidget extends StatefulWidget {
  double totalMaxWidth;

  ThreadDetailEvent item;

  String sourceEventId;

  GlobalKey sourceEventKey;

  ThreadDetailItemWidget({
    super.key,
    required this.item,
    required this.totalMaxWidth,
    required this.sourceEventId,
    required this.sourceEventKey,
  });

  @override
  State<StatefulWidget> createState() {
    return _ThreadDetailItemWidgetState();
  }
}

class _ThreadDetailItemWidgetState extends State<ThreadDetailItemWidget> {
  @override
  Widget build(BuildContext context) {
    Widget main = ThreadDetailItemMainWidget(
      item: widget.item,
      totalMaxWidth: widget.totalMaxWidth,
      sourceEventId: widget.sourceEventId,
      sourceEventKey: widget.sourceEventKey,
    );

    if (widget.item.event.kind == EventKind.ZAP) {
      main = Stack(
        children: [
          main,
          Positioned(
            top: -35,
            right: -10,
            child: EventBitcoinIconWidget(),
          ),
        ],
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: Base.BASE_PADDING_HALF),
      child: main,
    );
  }
}
