import 'package:flutter/material.dart';
import 'package:nostrmo/component/content/content_str_link_component.dart';
import 'package:nostrmo/component/event/event_main_component.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/router/thread/thread_detail_event.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';

import '../../consts/base.dart';
import '../../generated/l10n.dart';
import '../../provider/setting_provider.dart';

class ThreadDetailItemMainWidget extends StatefulWidget {
  static double BORDER_LEFT_WIDTH = 2;

  static double EVENT_MAIN_MIN_WIDTH = 200;

  ThreadDetailEvent item;

  double totalMaxWidth;

  String sourceEventId;

  GlobalKey sourceEventKey;

  ThreadDetailItemMainWidget({
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
    var s = S.of(context);
    var themeData = Theme.of(context);
    var hintColor = themeData.hintColor;
    var cardColor = themeData.cardColor;

    var settingProvider = Provider.of<SettingProvider>(context);

    bool showSubItems = true;
    if (settingProvider.maxSubEventLevel != null &&
        widget.item.currentLevel > settingProvider.maxSubEventLevel!) {
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
        (Base.BASE_PADDING + ThreadDetailItemMainWidget.BORDER_LEFT_WIDTH);
    currentWidth = mediaDataCache.size.width - leftWidth;
    if (currentWidth < ThreadDetailItemMainWidget.EVENT_MAIN_MIN_WIDTH) {
      currentWidth = ThreadDetailItemMainWidget.EVENT_MAIN_MIN_WIDTH;
    }
    list.add(Container(
      alignment: Alignment.centerLeft,
      width: currentWidth,
      child: currentMainEvent,
    ));

    if (widget.item.subItems != null && widget.item.subItems.isNotEmpty) {
      // this event has sub items
      if (showSubItems) {
        List<Widget> subWidgets = [];
        for (var subItem in widget.item.subItems) {
          subWidgets.add(
            Container(
              child: ThreadDetailItemMainWidget(
                item: subItem,
                totalMaxWidth: widget.totalMaxWidth,
                sourceEventId: widget.sourceEventId,
                sourceEventKey: widget.sourceEventKey,
              ),
            ),
          );
        }
        list.add(Container(
          alignment: Alignment.centerLeft,
          margin: const EdgeInsets.only(
            bottom: Base.BASE_PADDING,
            left: Base.BASE_PADDING,
          ),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                width: ThreadDetailItemMainWidget.BORDER_LEFT_WIDTH,
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
            bottom: Base.BASE_PADDING,
            left: Base.BASE_PADDING,
          ),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                width: ThreadDetailItemMainWidget.BORDER_LEFT_WIDTH,
                color: hintColor,
              ),
            ),
          ),
          child: Container(
            margin: const EdgeInsets.only(
              top: Base.BASE_PADDING_HALF,
              left: Base.BASE_PADDING,
              bottom: Base.BASE_PADDING,
            ),
            child: ContentStrLinkWidget(
              str: s.Show_more_replies,
              onTap: () {
                RouterUtil.router(
                    context, RouterPath.THREAD_TRACE, widget.item.event);
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
          top: Base.BASE_PADDING,
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
