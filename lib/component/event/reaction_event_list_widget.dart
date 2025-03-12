import 'package:flutter/material.dart';
import 'package:nostrmo/nostr_sdk/nostr_sdk.dart';

import '../../consts/base.dart';
import '../../consts/router_path.dart';
import '../../util/router_util.dart';
import 'reaction_event_item_widget.dart';

class ReactionEventListWidget extends StatefulWidget {
  Event event;

  bool jumpable;

  String text;

  ReactionEventListWidget({
    required this.event,
    this.jumpable = true,
    required this.text,
  });

  @override
  State<StatefulWidget> createState() => _ReactionEventListWidgetState();
}

class _ReactionEventListWidgetState extends State<ReactionEventListWidget> {
  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    var cardColor = themeData.cardColor;

    var main = Container(
      color: cardColor,
      margin: const EdgeInsets.only(bottom: Base.BASE_PADDING_HALF),
      padding: const EdgeInsets.only(
        top: Base.basePadding,
        bottom: Base.basePadding,
      ),
      child: ReactionEventItemWidget(
        pubkey: widget.event.pubkey,
        text: widget.text,
        createdAt: widget.event.createdAt,
      ),
    );

    if (widget.jumpable) {
      return GestureDetector(
        onTap: jumpToThread,
        child: main,
      );
    } else {
      return main;
    }
  }

  void jumpToThread() {
    RouterUtil.router(context, RouterPath.getThreadDetailPath(), widget.event);
  }
}
