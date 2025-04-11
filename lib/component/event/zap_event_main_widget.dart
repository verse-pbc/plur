
import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';

import '../../util/number_format_util.dart';
import 'reaction_event_item_widget.dart';

class ZapEventMainWidget extends StatefulWidget {
  final Event event;

  const ZapEventMainWidget({super.key, required this.event});

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
