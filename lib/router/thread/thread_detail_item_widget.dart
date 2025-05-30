import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';

import '../../component/event/event_bitcoin_icon_widget.dart';
import '../../consts/base.dart';
import 'thread_detail_event.dart';
import 'thread_detail_event_main_widget.dart';

class ThreadDetailItemWidget extends StatefulWidget {
  final double totalMaxWidth;

  final ThreadDetailEvent item;

  final String sourceEventId;

  final GlobalKey sourceEventKey;

  const ThreadDetailItemWidget({
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

    if (widget.item.event.kind == EventKind.zap) {
      main = Stack(
        children: [
          main,
          const Positioned(
            top: -35,
            right: -10,
            child: EventBitcoinIconWidget(),
          ),
        ],
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: Base.basePaddingHalf),
      child: main,
    );
  }
}
