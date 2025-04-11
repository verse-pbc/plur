import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:blurhash_dart/blurhash_dart.dart';
import 'package:image/image.dart' as img;

Widget? genBlurhashImageWidget(
    FileMetadata fileMetadata, Color color, BoxFit imageBoxFix) {
  // Use blurhash_dart for web platforms
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
    // Try to decode the blurhash
    final blurhashImage = BlurHash.decode(fileMetadata.blurhash!);
    
    // Generate the image data with proper dimensions - using positional arguments
    final image = blurhashImage.toImage(width, height);
    
    // Convert the image to bytes that can be used with Image.memory
    // We need to get a Uint8List from the Image object
    final pngBytes = img.encodePng(image);
    
    // Create a memory image from the decoded blurhash
    return Container(
      color: color.withAlpha(51),
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: Image.memory(
          pngBytes,
          fit: imageBoxFix,
          width: width.toDouble(),
          height: height.toDouble(),
          errorBuilder: (context, error, stackTrace) {
            // Fallback if blurhash fails
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
    // Fallback if blurhash decoding fails
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
