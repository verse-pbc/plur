import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

Widget? genBlurhashImageWidget(
    FileMetadata fileMetadata, Color color, BoxFit imageBoxFix) {
  // Early return for iOS and macOS platforms or missing blurhash
  if (!kIsWeb && (Platform.isIOS || Platform.isMacOS || fileMetadata.blurhash == null)) {
    return _buildPlaceholder(fileMetadata, color, imageBoxFix);
  }
  
  // Only try to use blurhash on web (or other non-iOS/macOS platforms)
  if (kIsWeb) {
    try {
      return _buildWebBlurHashImage(fileMetadata, color, imageBoxFix);
    } catch (e) {
      print("Web BlurHash error: $e");
    }
  }
  
  // Fallback to placeholder
  return _buildPlaceholder(fileMetadata, color, imageBoxFix);
}

// Web-specific implementation
Widget? _buildWebBlurHashImage(FileMetadata fileMetadata, Color color, BoxFit imageBoxFix) {
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
    // Only try to use blurhash_dart on web - dynamic import to avoid errors on other platforms
    if (kIsWeb) {
      return _processWebBlurhash(fileMetadata.blurhash!, width, height, aspectRatio, color, imageBoxFix);
    }
  } catch (e) {
    print("Error processing web blurhash: $e");
  }
  
  // Fallback if blurhash decoding fails
  return _buildPlaceholder(fileMetadata, color, imageBoxFix);
}

// Function that dynamically handles the web blurhash logic
Widget _processWebBlurhash(String blurhash, int width, int height, double aspectRatio, Color color, BoxFit imageBoxFix) {
  try {
    if (kIsWeb) {
      // Dynamic import to avoid iOS/macOS errors
      // This creates our blurhash image only on web
      final imageBytes = _createWebBlurhashBytes(blurhash, width, height);
      
      if (imageBytes != null) {
        return Container(
          color: color.withAlpha(51),
          child: AspectRatio(
            aspectRatio: aspectRatio,
            child: Image.memory(
              imageBytes,
              fit: imageBoxFix,
              width: width.toDouble(),
              height: height.toDouble(),
              errorBuilder: (context, error, stackTrace) {
                return _buildErrorPlaceholder(width, height, color);
              },
            ),
          ),
        );
      }
    }
  } catch (e) {
    print("Error creating web blurhash: $e");
  }
  
  // If we reach here, something went wrong - return a fallback placeholder
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

// Web-specific function to create blurhash bytes
dynamic _createWebBlurhashBytes(String blurhash, int width, int height) {
  try {
    if (kIsWeb) {
      // Load the web modules using our dynamic import trick
      dynamic blurhash_dart = _importWebBlurhash();
      dynamic image_lib = _importImageLib();
      
      if (blurhash_dart != null && image_lib != null) {
        // Use the dynamic imports to process the blurhash
        // ignore: avoid_dynamic_calls
        final blurhashImage = blurhash_dart.BlurHash.decode(blurhash);
        
        // Generate the image data with proper dimensions
        // ignore: avoid_dynamic_calls
        final image = blurhashImage.toImage(width, height);
        
        // Convert the image to bytes that can be used with Image.memory
        // ignore: avoid_dynamic_calls
        final pngBytes = image_lib.encodePng(image);
        
        return pngBytes;
      }
    }
  } catch (e) {
    print("Error in web blurhash processing: $e");
  }
  return null;
}

// Dynamic import for blurhash_dart
dynamic _importWebBlurhash() {
  try {
    if (kIsWeb) {
      dynamic lib;
      try {
        // This only executes on web
        // ignore: unused_import
        import 'package:blurhash_dart/blurhash_dart.dart' as blurhash_dart;
        lib = blurhash_dart;
      } catch (e) {
        print("Error importing blurhash_dart: $e");
      }
      return lib;
    }
  } catch (e) {
    print("Error in web blurhash import: $e");
  }
  return null;
}

// Dynamic import for image lib
dynamic _importImageLib() {
  try {
    if (kIsWeb) {
      dynamic lib;
      try {
        // This only executes on web
        // ignore: unused_import
        import 'package:image/image.dart' as img;
        lib = img;
      } catch (e) {
        print("Error importing image lib: $e");
      }
      return lib;
    }
  } catch (e) {
    print("Error in image lib import: $e");
  }
  return null;
}

// Create a placeholder widget for when blurhash isn't available
Widget _buildPlaceholder(FileMetadata fileMetadata, Color color, BoxFit imageBoxFix) {
  int? width = fileMetadata.getImageWidth() ?? 80;
  int? height = fileMetadata.getImageHeight() ?? 80;
  
  double aspectRatio = 1.6; // default
  if (width != null && height != null && height > 0) {
    aspectRatio = width / height;
  }
  
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

// Widget for error state
Widget _buildErrorPlaceholder(int? width, int? height, Color color) {
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
}
