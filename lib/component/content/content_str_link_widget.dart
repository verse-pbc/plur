import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/consts/plur_colors.dart';

class ContentStrLinkWidget extends StatelessWidget {
  final bool showUnderline;

  final String str;

  final Function onTap;

  const ContentStrLinkWidget(
      {super.key,
      required this.str,
      required this.onTap,
      this.showUnderline = true});

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    var fontSize = themeData.textTheme.bodyMedium!.fontSize;
    
    // Using Plur's primaryPurple color for all interactive links based on the design
    // This ensures hashtags, mentions, and links all use the same vibrant purple color
    const linkColor = PlurColors.primaryPurple;

    return GestureDetector(
      onTap: () {
        onTap();
      },
      child: Text(
        StringUtil.breakWord(str),
        style: TextStyle(
          color: linkColor,
          fontWeight: FontWeight.w500,
          decoration:
              showUnderline ? TextDecoration.underline : TextDecoration.none,
          decorationColor: linkColor,
          fontSize: fontSize,
        ),
        // fix when flutter upgrade, text not vertical align by bottom
        strutStyle: StrutStyle(
          forceStrutHeight: true,
          fontSize: fontSize! + 2,
        ),
      ),
    );
  }
}
