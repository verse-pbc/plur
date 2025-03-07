import 'package:flutter/material.dart';
import 'package:nostrmo/nostr_sdk/nostr_sdk.dart';
import 'package:screenshot/screenshot.dart';

import '../../component/event/event_main_widget.dart';

class ThreadTraceEventWidget extends StatefulWidget {
  Event event;

  Function? textOnTap;

  bool traceMode;

  ThreadTraceEventWidget(
    this.event, {
    super.key,
    this.textOnTap,
    this.traceMode = true,
  });

  @override
  State<StatefulWidget> createState() {
    return _ThreadTraceEventWidgetState();
  }
}

class _ThreadTraceEventWidgetState extends State<ThreadTraceEventWidget> {
  ScreenshotController ssController = ScreenshotController();

  @override
  Widget build(BuildContext context) {
    return Screenshot(
      controller: ssController,
      child: EventMainWidget(
        screenshotController: ssController,
        event: widget.event,
        showReplying: false,
        showVideo: true,
        imageListMode: false,
        showSubject: false,
        showLinkedLongForm: false,
        traceMode: widget.traceMode,
        showLongContent: true,
        textOnTap: () {
          if (widget.textOnTap != null) {
            widget.textOnTap!();
          }
        },
      ),
    );
  }
}
