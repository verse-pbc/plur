import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/theme/app_colors.dart';

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
    
    // According to feed_m_styles design, interactive elements should use the "Highlight" color
    // This ensures hashtags, mentions, and links use the correct off-white/light purple color
    final linkColor = context.colors.highlightText;

    return GestureDetector(
      onTap: () {
        onTap();
      },
      child: Text(
        StringUtil.breakWord(str),
        style: TextStyle(
          fontFamily: 'SF Pro Rounded',
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
