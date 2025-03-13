import 'package:flutter/material.dart';
import 'package:get_time_ago/get_time_ago.dart';

import '../../consts/base.dart';
import 'reaction_event_metadata_widget.dart';

class ReactionEventItemWidget extends StatefulWidget {
  String pubkey;

  String text;

  int createdAt;

  ReactionEventItemWidget({super.key, 
    required this.pubkey,
    required this.text,
    required this.createdAt,
  });

  @override
  State<StatefulWidget> createState() {
    return _ReactionEventItemWidgetState();
  }
}

class _ReactionEventItemWidgetState extends State<ReactionEventItemWidget> {
  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    var smallTextSize = themeData.textTheme.bodySmall!.fontSize;

    List<Widget> list = [];

    list.add(ReactionEventMetadataWidget(pubkey: widget.pubkey));

    list.add(Text(" ${widget.text} "));

    list.add(Text(
      GetTimeAgo.parse(
          DateTime.fromMillisecondsSinceEpoch(widget.createdAt * 1000)),
      style: TextStyle(
        fontSize: smallTextSize,
        color: themeData.hintColor,
      ),
    ));

    return Container(
      width: double.maxFinite,
      padding: const EdgeInsets.only(
        left: Base.BASE_PADDING,
        right: Base.BASE_PADDING,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: list,
        ),
      ),
    );
  }
}
