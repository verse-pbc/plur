import 'package:flutter/material.dart';
import 'package:flutter_placeholder_textlines/placeholder_lines.dart';

import '../../consts/base.dart';

class MusicPlaceholder extends StatelessWidget {
  const MusicPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    var cardColor = themeData.cardColor;
    var titleFontSize = themeData.textTheme.bodyMedium!.fontSize;
    var nameFontSize = themeData.textTheme.bodySmall!.fontSize;
    var hintColor = themeData.hintColor;

    var imageHeight = (titleFontSize! + nameFontSize!) * 1.7;

    Widget progressBar = Container(
      height: 4,
    );

    var imageWidget = Container(
      width: imageHeight,
      height: imageHeight,
      color: themeData.hintColor.withOpacity(0.5),
    );
    List<Widget> topList = [
      imageWidget,
      Expanded(
          child: Container(
        padding: const EdgeInsets.only(
          left: Base.basePadding,
          right: Base.basePadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 200,
              margin: const EdgeInsets.only(bottom: Base.basePaddingHalf),
              child: PlaceholderLines(
                count: 1,
                lineHeight: titleFontSize,
                color: hintColor,
              ),
            ),
            SizedBox(
              width: 100,
              child: PlaceholderLines(
                count: 1,
                lineHeight: nameFontSize,
                color: hintColor,
              ),
            ),
          ],
        ),
      )),
      SizedBox(
        width: imageHeight,
        height: imageHeight,
        child: const Icon(Icons.play_circle_outline),
      ),
    ];

    var topWidget = Row(
      children: topList,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          color: cardColor,
          height: imageHeight,
          child: topWidget,
        ),
        progressBar,
      ],
    );
  }
}
