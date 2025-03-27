
import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/provider/replaceable_event_provider.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';

import '../../consts/base.dart';
import '../../consts/router_path.dart';
import '../../generated/l10n.dart';
import '../../provider/single_event_provider.dart';
import '../../util/router_util.dart';
import '../cust_state.dart';
import 'event_main_widget.dart';

class EventQuoteWidget extends StatefulWidget {
  final Event? event;

  final String? id;

  final AId? aId;

  final String? eventRelayAddr;

  final bool showVideo;

  const EventQuoteWidget({
    super.key,
    this.event,
    this.id,
    this.aId,
    this.eventRelayAddr,
    this.showVideo = false,
  });

  @override
  State<StatefulWidget> createState() {
    return _EventQuoteWidgetState();
  }
}

class _EventQuoteWidgetState extends CustState<EventQuoteWidget> {
  ScreenshotController screenshotController = ScreenshotController();

  @override
  Widget doBuild(BuildContext context) {
    final themeData = Theme.of(context);
    var cardColor = themeData.cardColor;
    var boxDecoration = BoxDecoration(
      color: cardColor,
      boxShadow: [
        BoxShadow(
          color: themeData.shadowColor,
          offset: const Offset(0, 0),
          blurRadius: 10,
          spreadRadius: 0,
        ),
      ],
    );

    if (widget.event != null) {
      return buildEventWidget(widget.event!, cardColor, boxDecoration);
    }

    if (widget.aId != null) {
      return Selector<ReplaceableEventProvider, Event?>(
        builder: (context, event, child) {
          if (event == null) {
            return buildBlankWidget(boxDecoration);
          }

          return buildEventWidget(event, cardColor, boxDecoration);
        },
        selector: (_, provider) {
          return provider.getEvent(widget.aId!);
        },
      );
    }

    return Selector<SingleEventProvider, Event?>(
      builder: (context, event, child) {
        if (event == null) {
          return buildBlankWidget(boxDecoration);
        }

        return buildEventWidget(event, cardColor, boxDecoration);
      },
      selector: (_, provider) {
        return provider.getEvent(widget.id!,
            eventRelayAddr: widget.eventRelayAddr);
      },
    );
  }

  Widget buildEventWidget(
      Event event, Color cardColor, BoxDecoration boxDecoration) {
    if (event.kind == EventKind.storageSharedFile ||
        event.kind == EventKind.fileHeader) {
      return EventMainWidget(
        screenshotController: screenshotController,
        event: event,
        showReplying: false,
        textOnTap: () {
          jumpToThread(event);
        },
        showVideo: widget.showVideo,
        imageListMode: true,
        inQuote: true,
      );
    }

    return Screenshot(
      controller: screenshotController,
      child: Container(
        padding: const EdgeInsets.only(top: Base.basePadding),
        margin: const EdgeInsets.all(Base.basePadding),
        decoration: boxDecoration,
        child: GestureDetector(
          onTap: () {
            jumpToThread(event);
          },
          behavior: HitTestBehavior.translucent,
          child: EventMainWidget(
            screenshotController: screenshotController,
            event: event,
            showReplying: false,
            textOnTap: () {
              jumpToThread(event);
            },
            showVideo: widget.showVideo,
            imageListMode: true,
            inQuote: true,
          ),
        ),
      ),
    );
  }

  Widget buildBlankWidget(BoxDecoration boxDecoration) {
    return Container(
      margin: const EdgeInsets.all(Base.basePadding),
      height: 60,
      decoration: boxDecoration,
      child: Center(child: Text(S.of(context).Note_loading)),
    );
  }

  void jumpToThread(Event event) {
    RouterUtil.router(context, RouterPath.getThreadDetailPath(), event);
  }

  @override
  Future<void> onReady(BuildContext context) async {}
}
