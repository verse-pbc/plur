import 'package:blurhash_ffi/blurhash_ffi.dart';
import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';

Widget? genBlurhashImageWidget(
    FileMetadata fileMetadata, Color color, BoxFit imageBoxFix) {
  if (fileMetadata.blurhash == null) {
    return null;
  }
  
  // Get dimensions from metadata if available
  int? width = fileMetadata.getImageWidth();
  int? height = fileMetadata.getImageHeight();
  
  // Use default dimensions if not specified
  width ??= 80;
  height ??= 80;
  
  // Calculate aspect ratio from dimensions if available
  double aspectRatio = 1.6; // default
  if (width != null && height != null && height > 0) {
    aspectRatio = width / height;
  }

  try {
    // Create blurhash image provider
    final imageProvider = BlurhashFfiImage(
      fileMetadata.blurhash!,
      decodingHeight: height,
      decodingWidth: width
    );

    return Container(
      color: color.withAlpha(51),
      child: AspectRatio(
        aspectRatio: aspectRatio,
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
  } catch (e) {
    // Fallback if blurhash processing fails
    return Container(
      color: color.withAlpha(51),
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: Container(
          width: width.toDouble(),
          height: height.toDouble(),
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
}
