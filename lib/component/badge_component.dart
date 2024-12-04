import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:nostr_sdk/nip58/badge_definition.dart';
import 'package:nostr_sdk/utils/string_util.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../provider/badge_definition_provider.dart';
import 'image_component.dart';

class BadgeWidget extends StatelessWidget {
  static const double IMAGE_WIDTH = 28;

  BadgeDefinition badgeDefinition;

  BadgeWidget({
    required this.badgeDefinition,
  });

  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
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
