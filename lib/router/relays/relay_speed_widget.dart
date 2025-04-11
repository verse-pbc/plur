import 'package:flutter/material.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/provider/url_speed_provider.dart';
import 'package:provider/provider.dart';

import '../../consts/base.dart';

class RelaySpeedWidget extends StatefulWidget {
  final String addr;

  const RelaySpeedWidget(this.addr, {super.key});

  @override
  State<StatefulWidget> createState() {
    return _RelaySpeedWidgetState();
  }
}

class _RelaySpeedWidgetState extends State<RelaySpeedWidget> {
  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);

    Widget? main = Selector<UrlSpeedProvider, int?>(
      builder: ((context, speed, child) {
        if (speed == null) {
          return const Icon(Icons.speed);
        } else if (speed == -2) {
          return const Icon(Icons.sync);
        } else if (speed == -1) {
          return const Icon(
            Icons.error,
            color: Colors.red,
          );
        } else if (speed > 0) {
          return Text(
            "${speed}ms",
            style: TextStyle(
              fontSize: themeData.textTheme.bodySmall!.fontSize,
              color: Colors.green,
            ),
          );
        }

        return Container();
      }),
      selector: ((context, provider) {
        return provider.getSpeed(widget.addr);
      }),
    );

    return GestureDetector(
      onTap: beginTest,
      child: Container(
        alignment: Alignment.center,
        constraints: const BoxConstraints(minWidth: 30),
        height: 30,
        margin: const EdgeInsets.only(right: Base.basePadding),
        child: main,
      ),
    );
  }

  Future<void> beginTest() async {
    urlSpeedProvider.testSpeed(widget.addr);
  }
}
