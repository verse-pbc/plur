import 'package:flutter/material.dart';
import 'package:nostrmo/nostr_sdk/nostr_sdk.dart';

import 'image_widget.dart';

class BadgeWidget extends StatelessWidget {
  static const double IMAGE_WIDTH = 28;

  BadgeDefinition badgeDefinition;

  BadgeWidget({
    required this.badgeDefinition,
  });

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    var imagePath = badgeDefinition.thumb;
    if (StringUtil.isBlank(imagePath)) {
      imagePath = badgeDefinition.image;
    }

    Widget? imageWidget;
    if (StringUtil.isNotBlank(imagePath)) {
      imageWidget = ImageWidget(
        imageUrl: imagePath!,
        width: IMAGE_WIDTH,
        height: IMAGE_WIDTH,
        fit: BoxFit.cover,
        placeholder: (context, url) => const CircularProgressIndicator(),
      );
    }

    var main = Container(
      alignment: Alignment.center,
      height: IMAGE_WIDTH,
      width: IMAGE_WIDTH,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(IMAGE_WIDTH / 2),
        color: themeData.hintColor,
      ),
      child: imageWidget,
    );

    return main;
  }
}
