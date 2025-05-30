import 'package:flutter/material.dart';
import 'package:nostrmo/component/content/content_str_link_widget.dart';
import 'package:nostrmo/component/event/event_main_widget.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/router/thread/thread_detail_event.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';

import '../../consts/base.dart';
import '../../generated/l10n.dart';
import '../../provider/settings_provider.dart';

class ThreadDetailItemMainWidget extends StatefulWidget {
  static const double borderLeftWidth = 2;

  static const double eventMainMinWidth = 200;

  final ThreadDetailEvent item;

  final double totalMaxWidth;

  final String sourceEventId;

  final GlobalKey sourceEventKey;

  const ThreadDetailItemMainWidget({
    super.key,
    required this.item,
    required this.totalMaxWidth,
    required this.sourceEventId,
    required this.sourceEventKey,
  });

  @override
  State<StatefulWidget> createState() {
    return _ThreadDetailItemMainWidgetState();
  }
}

class _ThreadDetailItemMainWidgetState extends State<ThreadDetailItemMainWidget> {
  ScreenshotController screenshotController = ScreenshotController();

  @override
  Widget build(BuildContext context) {
    final localization = S.of(context);
    final themeData = Theme.of(context);
    var hintColor = themeData.hintColor;
    var cardColor = themeData.cardColor;

    var settingsProvider = Provider.of<SettingsProvider>(context);

    bool showSubItems = true;
    if (settingsProvider.maxSubEventLevel != null &&
        widget.item.currentLevel > settingsProvider.maxSubEventLevel!) {
      showSubItems = false;
    }

    var currentMainEvent = EventMainWidget(
      screenshotController: screenshotController,
      event: widget.item.event,
      showReplying: false,
      showVideo: true,
      imageListMode: false,
      showSubject: false,
      showLinkedLongForm: false,
    );

    List<Widget> list = [];
    var currentWidth = mediaDataCache.size.width;
    var leftWidth = (widget.item.currentLevel - 1) *
        (Base.basePadding + ThreadDetailItemMainWidget.borderLeftWidth);
    currentWidth = mediaDataCache.size.width - leftWidth;
    if (currentWidth < ThreadDetailItemMainWidget.eventMainMinWidth) {
      currentWidth = ThreadDetailItemMainWidget.eventMainMinWidth;
    }
    list.add(Container(
      alignment: Alignment.centerLeft,
      width: currentWidth,
      child: currentMainEvent,
    ));

    if (widget.item.subItems.isNotEmpty) {
      // this event has sub items
      if (showSubItems) {
        List<Widget> subWidgets = [];
        for (var subItem in widget.item.subItems) {
          subWidgets.add(
            ThreadDetailItemMainWidget(
              item: subItem,
              totalMaxWidth: widget.totalMaxWidth,
              sourceEventId: widget.sourceEventId,
              sourceEventKey: widget.sourceEventKey,
            ),
          );
        }
        list.add(Container(
          alignment: Alignment.centerLeft,
          margin: const EdgeInsets.only(
            bottom: Base.basePadding,
            left: Base.basePadding,
          ),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                width: ThreadDetailItemMainWidget.borderLeftWidth,
                color: hintColor,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: subWidgets,
          ),
        ));
      } else {
        list.add(Container(
          alignment: Alignment.centerLeft,
          margin: const EdgeInsets.only(
            bottom: Base.basePadding,
            left: Base.basePadding,
          ),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                width: ThreadDetailItemMainWidget.borderLeftWidth,
                color: hintColor,
              ),
            ),
          ),
          child: Container(
            margin: const EdgeInsets.only(
              top: Base.basePaddingHalf,
              left: Base.basePadding,
              bottom: Base.basePadding,
            ),
            child: ContentStrLinkWidget(
              str: localization.Show_more_replies,
              onTap: () {
                RouterUtil.router(
                    context, RouterPath.threadTrace, widget.item.event);
              },
            ),
          ),
        ));
      }
    }

    Key? currentEventKey;
    if (widget.item.event.id == widget.sourceEventId) {
      currentEventKey = widget.sourceEventKey;
    }

    return Screenshot(
      controller: screenshotController,
      child: Container(
        key: currentEventKey,
        padding: const EdgeInsets.only(
          top: Base.basePadding,
        ),
        color: cardColor,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: list,
        ),
      ),
    );
  }
}
