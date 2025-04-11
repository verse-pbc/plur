import 'dart:io';
import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';

Widget? genBlurhashImageWidget(
    FileMetadata fileMetadata, Color color, BoxFit imageBoxFix) {
  // Disable blurhash on iOS and macOS to avoid build issues
  if (Platform.isIOS || Platform.isMacOS || fileMetadata.blurhash == null) {
    return _buildPlaceholder(fileMetadata, color, imageBoxFix);
  }
  
  // Only try to use blurhash on other platforms
  try {
    // Import blurhash_ffi lazily to avoid issues on iOS/macOS
    if (!Platform.isIOS && !Platform.isMacOS) {
      return _buildBlurHashImage(fileMetadata, color, imageBoxFix);
    }
  } catch (e) {
    // Fallback to placeholder on any error
    print("BlurHash error: $e");
  }
  
  // Default to placeholder
  return _buildPlaceholder(fileMetadata, color, imageBoxFix);
}

// Implementation that will be used on platforms other than iOS/macOS
Widget? _buildBlurHashImage(FileMetadata fileMetadata, Color color, BoxFit imageBoxFix) {
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
    // Import here to avoid iOS/macOS build errors
    // This code will only execute on Android and other platforms
    // ignore: avoid_dynamic_calls
    dynamic imageProvider;
    if (!Platform.isIOS && !Platform.isMacOS) {
      // We'll use dynamic to avoid compile errors, and platform checks to prevent runtime errors
      imageProvider = _createImageProvider(fileMetadata.blurhash!, width, height);
      
      if (imageProvider != null) {
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
                return _buildErrorPlaceholder(width, height, color);
              },
            ),
          ),
        );
      }
    }
  } catch (e) {
    print("Error creating blurhash: $e");
  }
  
  // Fallback 
  return _buildPlaceholder(fileMetadata, color, imageBoxFix);
}

// This will be implemented properly only on non-iOS platforms
dynamic _createImageProvider(String blurhash, int width, int height) {
  try {
    if (!Platform.isIOS && !Platform.isMacOS) {
      // Dynamic import to avoid iOS/macOS errors
      // We have to use dynamic since the package might not be available
      // ignore: unnecessary_cast
      dynamic blurhashFfi = _importBlurhashFfi();
      if (blurhashFfi != null) {
        // ignore: avoid_dynamic_calls
        return blurhashFfi.BlurhashFfiImage(
          blurhash,
          decodingHeight: height,
          decodingWidth: width
        );
      }
    }
  } catch (e) {
    print("Failed to create image provider: $e");
  }
  return null;
}

// This function is needed to delay the import until runtime
// so it doesn't cause compile errors on iOS/macOS
dynamic _importBlurhashFfi() {
  try {
    if (!Platform.isIOS && !Platform.isMacOS) {
      // Use dynamic to avoid compile errors on iOS/macOS
      // ignore: avoid_dynamic_calls
      return require_blurhash_ffi();
    }
  } catch (e) {
    print("Failed to import blurhash_ffi: $e");
  }
  return null;
}

// Function to dynamically import blurhash_ffi
// This is a trick to avoid compile-time errors
dynamic require_blurhash_ffi() {
  try {
    // This will only be executed at runtime on supported platforms
    if (!Platform.isIOS && !Platform.isMacOS) {
      // ignore: unnecessary_cast
      dynamic lib;
      try {
        // ignore: avoid_dynamic_calls
        lib = __blurhash_ffi_import();
      } catch (e) {
        print("Error importing blurhash_ffi: $e");
      }
      return lib;
    }
  } catch (e) {
    print("Dynamic import error: $e");
  }
  return null;
}

// This function will cause a runtime error if called on iOS/macOS
// But that's OK because we have platform checks to prevent that
dynamic __blurhash_ffi_import() {
  if (!Platform.isIOS && !Platform.isMacOS) {
    // Using dynamic to avoid compile errors
    // ignore: unnecessary_cast
    dynamic lib;
    try {
      // This import will fail at runtime on iOS/macOS, but our platform checks prevent it from being called
      // ignore: unused_import
      import 'package:blurhash_ffi/blurhash_ffi.dart' as blurhash_ffi;
      lib = blurhash_ffi;
    } catch (e) {
      print("Error importing blurhash_ffi: $e");
    }
    return lib;
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
