import 'package:flutter/material.dart';
import 'package:flutter_placeholder_textlines/placeholder_lines.dart';

import '../../consts/base.dart';

class EventTopPlaceholder extends StatelessWidget {
  static const double imageWidth = 34;

  static const double halfImageWidth = 17;

  const EventTopPlaceholder({super.key});
  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    var hintColor = themeData.hintColor;
    var textSize = themeData.textTheme.bodyMedium!.fontSize;
    var smallTextSize = themeData.textTheme.bodySmall!.fontSize;

    return Container(
      padding: const EdgeInsets.only(
        left: Base.basePadding,
        right: Base.basePadding,
        bottom: Base.basePaddingHalf,
      ),
      child: Row(
        children: [
          Container(
            width: imageWidth,
            height: imageWidth,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(halfImageWidth),
              color: hintColor,
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(left: Base.basePaddingHalf),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    width: 100,
                    child: PlaceholderLines(
                      count: 1,
                      lineHeight: textSize!,
                      color: hintColor,
                    ),
                  ),
                  SizedBox(
                    width: 50,
                    child: PlaceholderLines(
                      count: 1,
                      lineHeight: smallTextSize!,
                      color: hintColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
