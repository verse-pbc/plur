import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:nostr_sdk/event.dart';
import 'package:nostr_sdk/zap/zap_info_util.dart';
import 'package:provider/provider.dart';

import '../../consts/base.dart';
import '../../data/metadata.dart';
import '../../provider/metadata_provider.dart';
import '../../util/number_format_util.dart';
import '../../util/spider_util.dart';
import 'package:nostr_sdk/utils/string_util.dart';
import 'reaction_event_item_component.dart';

class ZapEventMainWidget extends StatefulWidget {
  Event event;

  ZapEventMainWidget({super.key, required this.event});

  @override
  State<StatefulWidget> createState() {
    return _ZapEventMainWidgetState();
  }
}

class _ZapEventMainWidgetState extends State<ZapEventMainWidget> {
  String? senderPubkey;

  late String eventId;

  @override
  void initState() {
    super.initState();

    eventId = widget.event.id;
    senderPubkey = ZapInfoUtil.parseSenderPubkey(widget.event);
  }

  @override
  Widget build(BuildContext context) {
    if (StringUtil.isBlank(senderPubkey)) {
      return Container();
    }

    if (eventId != widget.event.id) {
      senderPubkey = ZapInfoUtil.parseSenderPubkey(widget.event);
    }

    var zapNum = ZapInfoUtil.getNumFromZapEvent(widget.event);
    String zapNumStr = NumberFormatUtil.format(zapNum);

    var text = "zapped $zapNumStr sats";

    return ReactionEventItemWidget(
        pubkey: senderPubkey!, text: text, createdAt: widget.event.createdAt);
  }
}
