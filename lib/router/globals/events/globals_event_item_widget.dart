import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/component/event/event_main_widget.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostrmo/provider/single_event_provider.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';

import '../../../consts/base.dart';
import '../../../generated/l10n.dart';

@deprecated
class GlobalEventItemWidget extends StatefulWidget {
  String eventId;

  GlobalEventItemWidget({super.key, required this.eventId});

  @override
  State<StatefulWidget> createState() {
    return _GlobalEventItemWidgetState();
  }
}

class _GlobalEventItemWidgetState extends State<GlobalEventItemWidget> {
  ScreenshotController screenshotController = ScreenshotController();

  Event? _event;

  @override
  Widget build(BuildContext context) {
    final localization = S.of(context);
    final themeData = Theme.of(context);
    var cardColor = themeData.cardColor;
    var hintColor = themeData.hintColor;

    return Selector<SingleEventProvider, Event?>(
      builder: (context, event, child) {
        if (event == null) {
          return Container(
            margin: const EdgeInsets.only(bottom: Base.basePaddingHalf),
            color: cardColor,
            height: 150,
            child: Center(
              child: Text(
                localization.loading,
                style: TextStyle(
                  color: hintColor,
                ),
              ),
            ),
          );
        }
        _event = event;

        var main = Screenshot(
          controller: screenshotController,
          child: Container(
            color: cardColor,
            margin: const EdgeInsets.only(bottom: Base.basePaddingHalf),
            padding: const EdgeInsets.only(
              top: Base.basePadding,
              // bottom: Base.BASE_PADDING,
            ),
            child: EventMainWidget(
              screenshotController: screenshotController,
              event: _event!,
              pagePubkey: null,
              textOnTap: jumpToThread,
            ),
          ),
        );

        return GestureDetector(
          onTap: jumpToThread,
          child: main,
        );
      },
      selector: (_, provider) {
        return provider.getEvent(widget.eventId);
      },
    );
  }

  void jumpToThread() {
    RouterUtil.router(context, RouterPath.getThreadDetailPath(), _event);
  }
}
