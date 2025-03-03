import 'package:flutter/material.dart';
import 'package:nostrmo/component/webview_widget.dart';

import '../../consts/base.dart';

class WebUtilItemWidget extends StatelessWidget {
  String link;

  String des;

  WebUtilItemWidget({required this.link, required this.des});

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    var cardColor = themeData.cardColor;
    var hintColor = themeData.hintColor;
    var largeTextSize = themeData.textTheme.bodyLarge!.fontSize;

    var main = Container(
      width: double.maxFinite,
      color: cardColor,
      margin: const EdgeInsets.only(bottom: Base.BASE_PADDING_HALF),
      padding: const EdgeInsets.all(
        Base.BASE_PADDING,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 3),
            child: Text(
              link,
              style: TextStyle(
                fontSize: largeTextSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            des,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: hintColor,
            ),
          ),
        ],
      ),
    );

    return GestureDetector(
      onTap: () {
        WebViewWidget.open(context, link);
      },
      behavior: HitTestBehavior.translucent,
      child: main,
    );
  }
}
