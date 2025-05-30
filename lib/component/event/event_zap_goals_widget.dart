import 'package:convert/convert.dart';
import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:provider/provider.dart';

import '../../consts/base.dart';
import '../../data/event_reactions.dart';
import '../../generated/l10n.dart';
import '../../provider/event_reactions_provider.dart';
import '../../util/number_format_util.dart';
import '../zap/zap_bottom_sheet_widget.dart';
import 'event_quote_widget.dart';

class EventZapGoalsWidget extends StatefulWidget {
  final Event event;

  final EventRelation eventRelation;

  const EventZapGoalsWidget({super.key,
    required this.event,
    required this.eventRelation,
  });

  @override
  State<StatefulWidget> createState() {
    return _EventZapGoalsWidgetState();
  }
}

class _EventZapGoalsWidgetState extends State<EventZapGoalsWidget> {
  ZapGoalsInfo? zapGoalsInfo;

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
        int zapNum = 0;
        if (eventReactions != null) {
          zapNum = eventReactions.zapNum;
        }

        List<Widget> list = [];

        zapGoalsInfo = ZapGoalsInfo.fromEvent(widget.event);
        if (zapGoalsInfo!.amount == 0) {
          return Container();
        }

        if (zapGoalsInfo!.closedAt != null) {
          var closeAtDT =
              DateTime.fromMillisecondsSinceEpoch(zapGoalsInfo!.closedAt!);
          var format = FixedDateTimeFormatter("YYYY-MM-DD hh:mm:ss");
          list.add(Row(
            children: [Text("${localization.Close_at} ${format.encode(closeAtDT)}")],
          ));
        }

        double percent = zapNum / zapGoalsInfo!.amount!;

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
                child: Row(children: [
                  const Icon(Icons.bolt),
                  Expanded(child: Container()),
                ]),
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
                  "${(percent * 100).toStringAsFixed(2)}%  ${NumberFormatUtil.format(zapNum)}/${NumberFormatUtil.format(zapGoalsInfo!.amount!)} sats",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );

        list.add(GestureDetector(
          onTap: () {
            ZapBottomSheetWidget.show(
                context, widget.event, widget.eventRelation);
          },
          child: pollItemWidget,
        ));

        if (StringUtil.isNotBlank(zapGoalsInfo!.goal)) {
          list.add(EventQuoteWidget(
            id: zapGoalsInfo!.goal,
          ));
        }

        return Container(
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
  }
}
