import 'package:flutter/material.dart';
import 'package:nostrmo/nostr_sdk/nostr_sdk.dart';

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
    var mainColor = themeData.primaryColor;
    var fontSize = themeData.textTheme.bodyMedium!.fontSize;

    return GestureDetector(
      onTap: () {
        onTap();
      },
      child: Text(
        StringUtil.breakWord(str),
        style: TextStyle(
          color: mainColor,
          decoration:
              showUnderline ? TextDecoration.underline : TextDecoration.none,
          decorationColor: mainColor,
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
