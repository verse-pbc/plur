import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';

import '../../consts/base.dart';
import '../../consts/router_path.dart';
import '../../util/router_util.dart';
import 'zap_event_main_widget.dart';

class ZapEventListWidget extends StatefulWidget {
  final Event event;

  final bool jumpable;

  const ZapEventListWidget({super.key,
    required this.event,
    this.jumpable = true,
  });

  @override
  State<StatefulWidget> createState() {
    return _ZapEventListWidgetState();
  }
}

class _ZapEventListWidgetState extends State<ZapEventListWidget> {
  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    var cardColor = themeData.cardColor;

    var main = Container(
      color: cardColor,
      margin: const EdgeInsets.only(bottom: Base.basePaddingHalf),
      padding: const EdgeInsets.only(
        top: Base.basePadding,
        bottom: Base.basePadding,
      ),
      child: ZapEventMainWidget(
        event: widget.event,
      ),
    );

    if (widget.jumpable) {
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
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
