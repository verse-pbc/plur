import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';

Widget? genBlurhashImageWidget(
    FileMetadata fileMetadata, Color color, BoxFit imageBoxFix) {
  // For web, since we can't use BlurhashFfiImage, provide a decent placeholder
  int? width = fileMetadata.getImageWidth();
  int? height = fileMetadata.getImageHeight();

  width ??= 80;
  height ??= 80;

  return Container(
    color: color.withAlpha(51),
    child: AspectRatio(
      aspectRatio: 1.6,
      child: Container(
        width: width!.toDouble(),
        height: height!.toDouble(),
        color: color.withAlpha(51),
        child: Center(
          child: Icon(
            Icons.image,
            size: width / 3,
            color: Colors.white.withAlpha(127),
          ),
        ),
      ),
    ),
  );
}
