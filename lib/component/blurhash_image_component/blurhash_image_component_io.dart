import 'package:blurhash_ffi/blurhash_ffi.dart';
import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';

Widget? genBlurhashImageWidget(
    FileMetadata fileMetadata, Color color, BoxFit imageBoxFix) {
  int? width = fileMetadata.getImageWidth();
  int? height = fileMetadata.getImageHeight();

  width ??= 80;
  height ??= 80;

  final imageProvider = BlurhashFfiImage(fileMetadata.blurhash!,
      decodingHeight: height, decodingWidth: width);

  return Container(
    color: color.withAlpha(51),
    child: AspectRatio(
      aspectRatio: 1.6,
      child: Image(
        fit: imageBoxFix,
        width: width.toDouble(),
        height: height.toDouble(),
        image: imageProvider,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width?.toDouble(),
            height: height?.toDouble(),
            color: color.withAlpha(51),
            child: Center(
              child: Icon(
                Icons.image_not_supported,
                size: (width ?? 60) / 3,
                color: Colors.white.withAlpha(127),
              ),
            ),
          );
        },
      ),
    ),
  );
}
