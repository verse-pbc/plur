import 'package:flutter/material.dart';

import '../../consts/base.dart';

class SearchActionItemWidget extends StatelessWidget {
  String title;

  Function onTap;

  SearchActionItemWidget({
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    var fontSize = themeData.textTheme.bodyLarge!.fontSize;
    var hintColor = themeData.hintColor;
    var cardColor = themeData.cardColor;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        onTap();
      },
      child: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(
          left: Base.basePadding * 2,
          right: Base.basePadding * 2,
          top: Base.basePadding,
          bottom: Base.basePadding,
        ),
        decoration: BoxDecoration(
          color: cardColor,
          border: Border(
            bottom: BorderSide(
              width: 1,
              color: hintColor,
            ),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(fontSize: fontSize),
        ),
      ),
    );
  }
}
