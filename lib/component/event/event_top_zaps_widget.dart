import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/component/user/user_pic_widget.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostrmo/util/number_format_util.dart';
import 'package:nostrmo/util/router_util.dart';

class EventTopZapsWidget extends StatefulWidget {
  final Event event;
  final dynamic eventRelation;
  final List<Event>? zapEvents;

  const EventTopZapsWidget({
    super.key,
    required this.event,
    required this.eventRelation,
    this.zapEvents,
  });

  @override
  State<StatefulWidget> createState() {
    return _EventTopZapsWidgetState();
  }
}

class _EventTopZapsWidgetState extends State<EventTopZapsWidget> {
  double topHeaderImageWidth = 34;

  double headerImageWidth = 22;

  int showLimit = 5;

  @override
  Widget build(BuildContext context) {
    // Use zap events directly if provided
    if (widget.zapEvents != null && widget.zapEvents!.isNotEmpty) {
      return _buildWithZapEvents(widget.zapEvents!);
    }
    
    // Otherwise, check if we have eventRelation with zapInfos
    if (widget.eventRelation != null && widget.eventRelation.zapInfos.isNotEmpty) {
      return _buildWithZapInfos(widget.eventRelation.zapInfos);
    }
    
    return Container();
  }
  
  Widget _buildWithZapEvents(List<Event> zapEvents) {
    if (zapEvents.isEmpty) {
      return Container();
    }

    List<EventTopZapInfo> zapInfos = [];
    for (var zapEvent in zapEvents) {
      var zapNum = ZapInfoUtil.getNumFromZapEvent(zapEvent);
      var pubkey = ZapInfoUtil.parseSenderPubkey(zapEvent);
      pubkey ??= zapEvent.pubkey;
      zapInfos.add(EventTopZapInfo(pubkey, zapNum));
    }

    zapInfos.sort((a, b) {
      return b.zapNum - a.zapNum;
    });
    
    return _buildTopZapsWidget(zapInfos);
  }
  
  Widget _buildWithZapInfos(List<EventZapInfo> zapInfos) {
    if (zapInfos.isEmpty) {
      return Container();
    }
    
    // Convert EventZapInfo to EventTopZapInfo
    List<EventTopZapInfo> topZapInfos = [];
    for (var zapInfo in zapInfos) {
      // Assume weight is the zap amount for display purposes
      topZapInfos.add(EventTopZapInfo(zapInfo.pubkey, zapInfo.weight.toInt()));
    }
    
    topZapInfos.sort((a, b) {
      return b.zapNum - a.zapNum;
    });

    return _buildTopZapsWidget(topZapInfos);
  }
  
  Widget _buildTopZapsWidget(List<EventTopZapInfo> zapInfos) {
    if (zapInfos.isEmpty) {
      return Container();
    }
    
    List<Widget> list = [];

    List<Widget> topList = [];
    topList.add(const Icon(
      Icons.bolt,
      color: Colors.orange,
    ));
    topList.add(GestureDetector(
      onTap: () {
        RouterUtil.router(context, RouterPath.user, zapInfos[0].pubkey);
      },
      child: UserPicWidget(
        pubkey: zapInfos[0].pubkey,
        width: topHeaderImageWidth,
      ),
    ));
    list.add(Row(
      mainAxisSize: MainAxisSize.min,
      children: topList,
    ));

    list.add(Container(
      margin: const EdgeInsets.only(
        left: Base.basePaddingHalf,
        right: Base.basePadding,
      ),
      child: Text(
        NumberFormatUtil.format(zapInfos[0].zapNum),
        style: const TextStyle(
          color: Colors.orange,
        ),
      ),
    ));

    var zapInfosLength = zapInfos.length;
    if (zapInfosLength < showLimit) {
      for (var i = 1; i < zapInfosLength; i++) {
        list.add(buildUserPic(zapInfos[i].pubkey, headerImageWidth));
      }
    } else {
      for (var i = 1; i < showLimit; i++) {
        list.add(buildUserPic(zapInfos[i].pubkey, headerImageWidth));
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: list,
    );
  }

  Widget buildUserPic(String pubkey, double width) {
    return Container(
      margin: const EdgeInsets.only(right: Base.basePaddingHalf),
      child: GestureDetector(
        onTap: () {
          RouterUtil.router(context, RouterPath.user, pubkey);
        },
        child: UserPicWidget(
          pubkey: pubkey,
          width: width,
        ),
      ),
    );
  }
}

class EventTopZapInfo {
  final String pubkey;

  final int zapNum;

  EventTopZapInfo(this.pubkey, this.zapNum);
}
