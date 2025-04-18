import 'package:flutter/material.dart';
import 'package:flutter_placeholder_textlines/placeholder_lines.dart';

import '../../consts/base.dart';
import 'event_top_placeholder.dart';

class EventPlaceholder extends StatelessWidget {
  const EventPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    var hintColor = themeData.hintColor;
    var smallTextSize = themeData.textTheme.bodySmall!.fontSize;
    var cardColor = themeData.cardColor;

    var textLineMagin = const EdgeInsets.only(bottom: 3);

    var main = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        const EventTopPlaceholder(),
        Container(
          width: double.maxFinite,
          padding: const EdgeInsets.only(
            left: Base.basePadding,
            right: Base.basePadding,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: textLineMagin,
                child: PlaceholderLines(
                  count: 1,
                  lineHeight: smallTextSize!,
                  color: hintColor,
                ),
              ),
              Container(
                margin: textLineMagin,
                child: PlaceholderLines(
                  count: 1,
                  lineHeight: smallTextSize,
                  color: hintColor,
                ),
              ),
              Container(
                margin: textLineMagin,
                child: PlaceholderLines(
                  count: 1,
                  lineHeight: smallTextSize,
                  color: hintColor,
                ),
              ),
              Container(
                width: 200,
                margin: textLineMagin,
                child: PlaceholderLines(
                  count: 1,
                  lineHeight: smallTextSize,
                  color: hintColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.only(
        top: Base.basePadding,
        bottom: Base.basePadding,
      ),
      margin: const EdgeInsets.only(bottom: Base.basePaddingHalf),
      color: cardColor,
      child: main,
    );
  }
}
