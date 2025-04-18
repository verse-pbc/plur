import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/component/event_delete_callback.dart';
import 'package:nostrmo/router/tag/topic_map.dart';
import 'package:provider/provider.dart';

import '../../component/appbar_back_btn_widget.dart';
import '../../component/cust_state.dart';
import '../../component/event/event_list_widget.dart';
import '../../component/tag_info_widget.dart';
import '../../consts/base_consts.dart';
import '../../main.dart';
import '../../provider/settings_provider.dart';
import '../../util/router_util.dart';

import '../../util/table_mode_util.dart';

class TagDetailWidget extends StatefulWidget {
  const TagDetailWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return _TagDetailWidgetState();
  }
}

class _TagDetailWidgetState extends CustState<TagDetailWidget>
    with PendingEventsLaterFunction {
  EventMemBox box = EventMemBox();

  final ScrollController _controller = ScrollController();

  bool showTitle = false;

  double tagHeight = 80;

  String? tag;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (_controller.offset > tagHeight * 0.8 && !showTitle) {
        setState(() {
          showTitle = true;
        });
      } else if (_controller.offset < tagHeight * 0.8 && showTitle) {
        setState(() {
          showTitle = false;
        });
      }
    });
  }

  @override
  Widget doBuild(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    if (StringUtil.isBlank(tag)) {
      var arg = RouterUtil.routerArgs(context);
      if (arg != null && arg is String) {
        tag = arg;
      }
    } else {
      var arg = RouterUtil.routerArgs(context);
      if (arg != null && arg is String && tag != arg) {
        // arg changed! reset
        tag = arg;

        box = EventMemBox();
        doQuery();
      }
    }
    if (StringUtil.isBlank(tag)) {
      RouterUtil.back(context);
      return Container();
    }

    final themeData = Theme.of(context);
    var bodyLargeFontSize = themeData.textTheme.bodyLarge!.fontSize;

    Widget? appBarTitle;
    if (showTitle) {
      appBarTitle = Text(
        "#${tag!}",
        style: TextStyle(
          fontSize: bodyLargeFontSize,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    Widget main = EventDeleteCallback(
      onDeleteCallback: onDeleteCallback,
      child: ListView.builder(
        controller: _controller,
        itemBuilder: (context, index) {
          if (index == 0) {
            return TagInfoWidget(
              tag: tag!,
              height: tagHeight,
            );
          }

          var event = box.get(index - 1);
          if (event == null) {
            return null;
          }

          return EventListWidget(
            event: event,
            showVideo: settingsProvider.videoPreviewInList != OpenStatus.close,
          );
        },
        itemCount: box.length() + 1,
      ),
    );

    if (TableModeUtil.isTableMode()) {
      main = GestureDetector(
        onVerticalDragUpdate: (detail) {
          _controller.jumpTo(_controller.offset - detail.delta.dy);
        },
        behavior: HitTestBehavior.translucent,
        child: main,
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: const AppbarBackBtnWidget(),
        actions: const [],
        title: appBarTitle,
      ),
      body: main,
    );
  }

  var subscribeId = StringUtil.rndNameStr(16);

  @override
  Future<void> onReady(BuildContext context) async {
    doQuery();
  }

  void doQuery() {
    // tag query
    // https://github.com/nostr-protocol/nips/blob/master/12.md
    var filter = Filter(kinds: EventKind.supportedEvents, limit: 100);
    var queryArg = filter.toJson();
    var plainTag = tag!.replaceFirst("#", "");
    // this place set #t not #r ???
    var list = TopicMap.getList(plainTag);
    if (list != null) {
      queryArg["#t"] = list;
    } else {
      // can't find from topicMap, change to query the source, upperCase and lowerCase
      var upperCase = plainTag.toUpperCase();
      var lowerCase = plainTag.toLowerCase();
      list = [upperCase];
      if (upperCase != lowerCase) {
        list.add(lowerCase);
      }
      if (upperCase != plainTag && lowerCase != plainTag) {
        list.add(plainTag);
      }
      queryArg["#t"] = list;
    }
    nostr!.query([queryArg], onEvent, id: subscribeId);
  }

  void onEvent(Event event) {
    later(event, (list) {
      box.addList(list);
      setState(() {});
    }, null);
  }

  @override
  void dispose() {
    super.dispose();
    disposeLater();

    try {
      nostr!.unsubscribe(subscribeId);
    } catch (_) {}
  }

  onDeleteCallback(Event event) {
    box.delete(event.id);
    setState(() {});
  }
}
