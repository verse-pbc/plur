
import 'package:bot_toast/bot_toast.dart';
import 'package:convert/convert.dart';
import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/component/content/content_widget.dart';
import 'package:provider/provider.dart';

import '../../consts/base.dart';
import '../../data/event_reactions.dart';
import '../../generated/l10n.dart';
import '../../main.dart';
import '../../provider/event_reactions_provider.dart';
import '../../util/number_format_util.dart';
import '../../util/spider_util.dart';
import '../../util/zap_action.dart';
import '../editor/text_input_dialog.dart';

class EventPollWidget extends StatefulWidget {
  final Event event;

  const EventPollWidget({super.key, required this.event});

  @override
  State<StatefulWidget> createState() {
    return _EventPollWidgetState();
  }
}

class _EventPollWidgetState extends State<EventPollWidget> {
  PollInfo? pollInfo;

  @override
  Widget build(BuildContext context) {
    final localization = S.of(context);
    final themeData = Theme.of(context);
    var hintColor = themeData.hintColor;
    var pollBackgroundColor = hintColor.withOpacity(0.3);
    var mainColor = themeData.primaryColor;

    return Selector<EventReactionsProvider, EventReactions?>(
      builder: (context, eventReactions, child) {
        // count the poll number.
        int total = 0;
        Map<String, int> pollNums = {};
        var myNum = 0;
        if (eventReactions != null) {
          for (var zapEvent in eventReactions.zaps) {
            int num = 0;
            String? selectKey;
            String? senderPubkey;

            for (var tag in zapEvent.tags) {
              if (tag.length > 1) {
                var tagType = tag[0] as String;
                if (tagType == "bolt11") {
                  var zapStr = tag[1] as String;
                  num = ZapInfoUtil.getNumFromStr(zapStr);
                } else if (tagType == "description") {
                  var text = tag[1];
                  selectKey =
                      SpiderUtil.subUntil(text, "[\"poll_option\",\"", "\"");
                  senderPubkey = SpiderUtil.subUntil(text, "pubkey\":\"", "\"");
                }
              }
            }

            if (num > 0 && StringUtil.isNotBlank(selectKey)) {
              total += num;

              if (senderPubkey == nostr!.publicKey) {
                myNum += num;
              }

              var pollOptionNum = pollNums[selectKey];
              pollOptionNum ??= 0;
              pollOptionNum += num;
              pollNums[selectKey!] = pollOptionNum;
            }
          }
        }

        List<Widget> list = [];

        pollInfo = PollInfo.fromEvent(widget.event);

        if (StringUtil.isNotBlank(pollInfo!.consensusThreshold) &&
            pollInfo!.consensusThreshold != "null") {
          list.add(Text(pollInfo!.consensusThreshold!));
        }

        if (pollInfo!.closedAt != null) {
          var closeAtDT =
              DateTime.fromMillisecondsSinceEpoch(pollInfo!.closedAt!);
          var format = FixedDateTimeFormatter("YYYY-MM-DD hh:mm:ss");
          list.add(Row(
            children: [Text("${localization.Close_at} ${format.encode(closeAtDT)}")],
          ));
        }

        if (myNum > 0) {
          var myNumStr = NumberFormatUtil.format(myNum);
          list.add(Text("${localization.You_had_voted_with} $myNumStr sats."));
        }

        List<Widget> pollList = [];
        for (var pollOption in pollInfo!.pollOptions) {
          String selectKey = pollOption[0];
          double percent = 0;

          var num = pollNums[selectKey];
          if (num != null && total > 0) {
            percent = num / total;
          }
          num ??= 0;

          var pollItemWidget = Container(
            width: double.maxFinite,
            margin: const EdgeInsets.only(
              top: Base.basePaddingHalf,
            ),
            decoration: BoxDecoration(
              color: pollBackgroundColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(Base.basePaddingHalf),
                  width: double.maxFinite,
                  child: AbsorbPointer(
                    child: ContentWidget(
                      content: pollOption[1],
                      event: widget.event,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      heightFactor: 1,
                      widthFactor: percent,
                      child: Container(
                        decoration: BoxDecoration(
                          color: mainColor.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: Base.basePadding,
                  child: Text(
                    "${(percent * 100).toStringAsFixed(2)}% ${NumberFormatUtil.format(num)} sats",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );

          pollList.add(GestureDetector(
            onTap: () {
              tapZap(selectKey);
            },
            child: pollItemWidget,
          ));
        }
        list.add(Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: pollList,
        ));

        if (pollInfo!.valueMinimum != null && pollInfo!.valueMaximum != null) {
          list.add(Container(
            margin: const EdgeInsets.only(top: Base.basePaddingHalf),
            child: Text(
              "${localization.min_zap_num}: ${pollInfo!.valueMinimum}  ${localization.max_zap_num}: ${pollInfo!.valueMaximum}",
              style: TextStyle(
                color: hintColor,
              ),
            ),
          ));
        }

        return Container(
          // color: Colors.red,
          width: double.maxFinite,
          margin: const EdgeInsets.only(
            top: Base.basePaddingHalf,
            bottom: Base.basePaddingHalf,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: list,
          ),
        );
      },
      selector: (_, provider) {
        return provider.get(widget.event.id);
      },
    );
  }

  Future<void> tapZap(String selectKey) async {
    var numStr = await TextInputDialog.show(
        context, S.of(context).Input_Sats_num,
        valueCheck: inputCheck);
    if (numStr != null) {
      var num = int.tryParse(numStr);
      if (num != null) {
        if (!mounted) return;
        ZapAction.handleZap(
          context,
          num,
          widget.event.pubkey,
          eventId: widget.event.id,
          pollOption: selectKey,
        );
      }
    }
  }

  bool inputCheck(BuildContext context, String value) {
    if (StringUtil.isBlank(value)) {
      BotToast.showText(text: S.of(context).Input_can_not_be_null);
      return false;
    }

    var num = int.tryParse(value);
    if (num == null) {
      BotToast.showText(text: S.of(context).Input_parse_error);
      return false;
    } else {
      if (pollInfo != null &&
          pollInfo!.valueMinimum != null &&
          pollInfo!.valueMinimum! > num) {
        BotToast.showText(
            text:
                "${S.of(context).Zap_num_can_not_smaller_then} ${pollInfo!.valueMinimum!}");
        return false;
      }
      if (pollInfo != null &&
          pollInfo!.valueMaximum != null &&
          pollInfo!.valueMaximum! < num) {
        BotToast.showText(
            text:
                "${S.of(context).Zap_num_can_not_bigger_then} ${pollInfo!.valueMaximum!}");
        return false;
      }
    }

    return true;
  }
}
