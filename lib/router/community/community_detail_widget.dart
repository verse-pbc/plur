import 'package:flutter/material.dart';
import 'package:nostrmo/nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/component/community_info_widget.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/provider/community_info_provider.dart';
import 'package:provider/provider.dart';
import 'package:widget_size/widget_size.dart';

import '../../component/appbar_back_btn_widget.dart';
import '../../component/cust_state.dart';
import '../../component/event/event_list_widget.dart';
import '../../component/event_delete_callback.dart';
import '../../consts/base_consts.dart';
import '../../main.dart';
import '../../provider/settings_provider.dart';
import '../../util/router_util.dart';
import '../edit/editor_widget.dart';

class CommunityDetailWidget extends StatefulWidget {
  const CommunityDetailWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return _CommunityDetailWidgetState();
  }
}

class _CommunityDetailWidgetState extends CustState<CommunityDetailWidget>
    with PenddingEventsLaterFunction {
  EventMemBox box = EventMemBox();

  AId? aId;

  final ScrollController _controller = ScrollController();

  bool showTitle = false;

  double infoHeight = 80;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (_controller.offset > infoHeight * 0.8 && !showTitle) {
        setState(() {
          showTitle = true;
        });
      } else if (_controller.offset < infoHeight * 0.8 && showTitle) {
        setState(() {
          showTitle = false;
        });
      }
    });
  }

  @override
  Widget doBuild(BuildContext context) {
    if (aId == null) {
      var arg = RouterUtil.routerArgs(context);
      if (arg != null) {
        aId = arg as AId;
      }
    }
    if (aId == null) {
      RouterUtil.back(context);
      return Container();
    }
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final themeData = Theme.of(context);
    var bodyLargeFontSize = themeData.textTheme.bodyLarge!.fontSize;

    Widget? appBarTitle;
    if (showTitle) {
      appBarTitle = Text(
        aId!.title,
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
            return Selector<CommunityInfoProvider, CommunityInfo?>(
                builder: (context, info, child) {
              if (info == null) {
                return Container();
              }

              return WidgetSize(
                onChange: (localization) {
                  infoHeight = localization.height;
                },
                child: CommunityInfoWidget(info: info),
              );
            }, selector: (_, provider) {
              return provider.getCommunity(aId!.toAString());
            });
          }

          var event = box.get(index - 1);
          if (event == null) {
            return null;
          }

          return EventListWidget(
            event: event,
            showVideo: settingsProvider.videoPreviewInList != OpenStatus.CLOSE,
            showCommunity: false,
          );
        },
        itemCount: box.length() + 1,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        leading: const AppbarBackBtnWidget(),
        actions: [
          GestureDetector(
            onTap: addToCommunity,
            child: Container(
              margin: const EdgeInsets.only(
                left: Base.BASE_PADDING,
                right: Base.BASE_PADDING,
              ),
              child: Icon(
                Icons.add,
                color: themeData.appBarTheme.titleTextStyle!.color,
              ),
            ),
          )
        ],
        title: appBarTitle,
      ),
      body: main,
    );
  }

  var infoSubscribeId = StringUtil.rndNameStr(16);

  var subscribeId = StringUtil.rndNameStr(16);

  @override
  Future<void> onReady(BuildContext context) async {
    if (aId != null) {
      queryEvents();
    }
  }

  void queryEvents() {
    var filter = Filter(kinds: EventKind.SUPPORTED_EVENTS, limit: 100);
    var queryArg = filter.toJson();
    queryArg["#a"] = [aId!.toAString()];
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
    } catch (e) {}
  }

  onDeleteCallback(Event event) {
    box.delete(event.id);
    setState(() {});
  }

  Future<void> addToCommunity() async {
    if (aId != null) {
      List<String> aTag = ["a", aId!.toAString()];
      if (relayProvider.relayAddrs.isNotEmpty) {
        aTag.add(relayProvider.relayAddrs[0]);
      }

      var event = await EditorWidget.open(context, tags: [aTag]);
      if (event != null) {
        queryEvents();
      }
    }
  }
}
