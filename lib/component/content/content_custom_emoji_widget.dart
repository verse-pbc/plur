import 'dart:io';

import 'package:flutter/material.dart';

import '../image_widget.dart';

class ContentCustomEmojiWidget extends StatelessWidget {
  final String imagePath;

  const ContentCustomEmojiWidget({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    if (imagePath.indexOf("http") == 0) {
      // network image
      return Container(
        constraints: const BoxConstraints(maxWidth: 80, maxHeight: 80),
        child: ImageWidget(
          imageUrl: imagePath,
        ),
      );
    } else {
      // local image
      return Container(
        constraints: const BoxConstraints(maxWidth: 80, maxHeight: 80),
        child: Image.file(
          File(imagePath),
        ),
      );
    }
  }
}
