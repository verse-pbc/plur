import 'package:flutter/material.dart';
import 'package:nostrmo/nostr_sdk/nostr_sdk.dart';

import 'image_widget.dart';

class BadgeWidget extends StatelessWidget {
  static const double imageWidth = 28;

  final BadgeDefinition badgeDefinition;

  const BadgeWidget({super.key, 
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
        width: imageWidth,
        height: imageWidth,
        fit: BoxFit.cover,
        placeholder: (context, url) => const CircularProgressIndicator(),
      );
    }

    var main = Container(
      alignment: Alignment.center,
      height: imageWidth,
      width: imageWidth,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(imageWidth / 2),
        color: themeData.hintColor,
      ),
      child: imageWidget,
    );

    return main;
  }
}
