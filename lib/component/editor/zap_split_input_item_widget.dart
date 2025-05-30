import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/component/user/simple_name_widget.dart';
import 'package:nostrmo/component/user/user_pic_widget.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:flutter_seekbar/flutter_seekbar.dart';


class ZapSplitInputItemWidget extends StatefulWidget {
  final EventZapInfo eventZapInfo;

  final Function recountWeightAndRefresh;

  const ZapSplitInputItemWidget(this.eventZapInfo, this.recountWeightAndRefresh, {super.key});

  @override
  State<StatefulWidget> createState() {
    return _ZapSplitInputItemWidgetState();
  }
}

class _ZapSplitInputItemWidgetState extends State<ZapSplitInputItemWidget> {
  @override
  Widget build(BuildContext context) {
    var pubkey = widget.eventZapInfo.pubkey;
    List<Widget> list = [];

    list.add(UserPicWidget(pubkey: pubkey, width: 46));

    list.add(Container(
      padding: const EdgeInsets.only(left: Base.basePadding),
      width: 120,
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SimpleNameWidget(
            pubkey: pubkey,
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text("${(widget.eventZapInfo.weight * 100).toStringAsFixed(0)}%")
        ],
      ),
    ));

    list.add(Expanded(
      child: SeekBar(
        min: 0.01,
        max: 1,
        value: widget.eventZapInfo.weight,
        semanticsValue: "${widget.eventZapInfo.weight}",
        alwaysShowBubble: true,
        onValueChanged: (pv) {
          widget.eventZapInfo.weight = pv.value;
          widget.recountWeightAndRefresh();
        },
      ),
    ));

    return Row(
      children: list,
    );
  }
}
