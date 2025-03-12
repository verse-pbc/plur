import 'package:flutter/material.dart';
import 'package:flutter_placeholder_textlines/placeholder_lines.dart';

import '../../consts/base.dart';

class UserRelayPlaceholder extends StatelessWidget {
  const UserRelayPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    var cardColor = themeData.cardColor;
    var hintColor = themeData.hintColor;
    var fontSize = themeData.textTheme.bodyMedium!.fontSize;

    Widget rightBtn = GestureDetector(
      onTap: () {},
      child: const Icon(
        Icons.add,
      ),
    );

    Widget bottomWidget = Container();

    return Container(
      margin: const EdgeInsets.only(
        bottom: Base.basePadding,
        left: Base.basePadding,
        right: Base.basePadding,
      ),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Container(
        padding: const EdgeInsets.only(
          top: Base.BASE_PADDING_HALF,
          bottom: Base.BASE_PADDING_HALF,
          left: Base.basePadding,
          right: Base.basePadding,
        ),
        decoration: BoxDecoration(
          color: cardColor,
          border: Border(
            left: BorderSide(
              width: 6,
              color: hintColor,
            ),
          ),
          // borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 230,
                    margin: EdgeInsets.only(bottom: 2),
                    child: PlaceholderLines(
                      count: 1,
                      color: hintColor,
                      lineHeight: fontSize!,
                    ),
                  ),
                  bottomWidget,
                ],
              ),
            ),
            rightBtn,
          ],
        ),
      ),
    );
  }
}
