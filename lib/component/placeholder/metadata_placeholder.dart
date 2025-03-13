import 'package:flutter/material.dart';
import 'package:flutter_placeholder_textlines/placeholder_lines.dart';

import '../../consts/base.dart';
import 'metadata_top_placeholder.dart';

class MetadataPlaceholder extends StatelessWidget {
  const MetadataPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    var hintColor = themeData.hintColor;
    var smallTextSize = themeData.textTheme.bodySmall!.fontSize;

    var textLineMagin = const EdgeInsets.only(bottom: 6);

    List<Widget> mainList = [];

    mainList.add(const MetadataTopPlaceholderWidget());

    mainList.add(
      Container(
        width: double.maxFinite,
        padding: const EdgeInsets.only(
          top: Base.basePaddingHalf,
          left: Base.basePadding,
          right: Base.basePadding,
          bottom: Base.basePadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
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
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: mainList,
    );
  }
}
