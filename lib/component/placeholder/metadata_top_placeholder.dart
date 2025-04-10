import 'package:flutter/material.dart';
import 'package:flutter_placeholder_textlines/placeholder_lines.dart';
import 'package:nostrmo/util/table_mode_util.dart';

import '../../consts/base.dart';
import '../../main.dart';
import '../user/user_top_widget.dart';

class MetadataTopPlaceholderWidget extends StatelessWidget {
  static const double imageBorder = 4;

  static const double imageWidth = 80;

  static const double halfImageWidth = 40;

  const MetadataTopPlaceholderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    var hintColor = themeData.hintColor;
    var scaffoldBackgroundColor = themeData.scaffoldBackgroundColor;
    var maxWidth = mediaDataCache.size.width;
    var bannerHeight = maxWidth / 3;
    if (TableModeUtil.isTableMode()) {
      bannerHeight =
          UserTopWidget.getPcBannerHeight(mediaDataCache.size.height);
    }
    var textSize = themeData.textTheme.bodyMedium!.fontSize;

    List<Widget> topBtnList = [
      Expanded(
        child: Container(),
      )
    ];
    topBtnList.add(Container(
      width: 140,
      margin: const EdgeInsets.only(right: Base.basePaddingHalf),
      child: PlaceholderLines(
        count: 1,
        lineHeight: 30,
        color: hintColor,
        minWidth: 1,
      ),
    ));

    Widget userNameWidget = Container(
      width: 120,
      margin: const EdgeInsets.only(
        left: Base.basePadding,
        right: Base.basePadding,
        bottom: Base.basePaddingHalf,
      ),
      child: PlaceholderLines(
        count: 1,
        lineHeight: 18,
        color: hintColor,
      ),
    );

    List<Widget> topList = [];
    topList.add(Container(
      width: maxWidth,
      height: bannerHeight,
      color: hintColor.withAlpha(128),
    ));
    topList.add(SizedBox(
      height: 50,
      // color: Colors.red,
      child: Row(
        children: topBtnList,
      ),
    ));
    topList.add(userNameWidget);

    topList.add(Container(
      margin: const EdgeInsets.only(
        left: Base.basePadding,
        right: Base.basePadding,
      ),
      width: maxWidth,
      child: PlaceholderLines(
        count: 1,
        lineHeight: textSize!,
        color: hintColor,
        minWidth: 1,
        maxWidth: 1,
      ),
    ));

    Widget userImageWidget = Container(
      alignment: Alignment.center,
      height: imageWidth,
      width: imageWidth,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(halfImageWidth),
        color: hintColor,
      ),
    );

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: topList,
        ),
        Positioned(
          left: Base.basePadding,
          top: bannerHeight - halfImageWidth,
          child: Container(
            height: imageWidth + imageBorder * 2,
            width: imageWidth + imageBorder * 2,
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(halfImageWidth + imageBorder),
              border: Border.all(
                width: imageBorder,
                color: scaffoldBackgroundColor,
              ),
            ),
            child: userImageWidget,
          ),
        )
      ],
    );
  }
}
