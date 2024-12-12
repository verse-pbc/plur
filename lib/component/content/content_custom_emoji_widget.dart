import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../main.dart';
import '../image_widget.dart';

class ContentCustomEmojiWidget extends StatelessWidget {
  final String imagePath;

  ContentCustomEmojiWidget({required this.imagePath});

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
