import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';

// Since this file is only loaded on IO platforms, import directly with a safe wrapper
import 'package:nostrmo/component/blurhash_image_component/empty_blurhash_ffi.dart' as blurhash_ffi;
import 'package:nostrmo/component/blurhash_image_component/stub_platform.dart';

Widget? genBlurhashImageWidget(
    FileMetadata fileMetadata, Color color, BoxFit imageBoxFix) {
  try {
    // Disable blurhash on iOS and macOS to avoid build issues
    if (SafePlatform.isIOS() || SafePlatform.isMacOS() || fileMetadata.blurhash == null) {
      return _buildPlaceholder(fileMetadata, color, imageBoxFix);
    }
    
    // Only try to use blurhash on other platforms
    try {
      // Import blurhash_ffi lazily to avoid issues on iOS/macOS
      if (!SafePlatform.isIOS() && !SafePlatform.isMacOS()) {
        return _buildBlurHashImage(fileMetadata, color, imageBoxFix);
      }
    } catch (e) {
      // Fallback to placeholder on any error - silent failure
    }
    
    // Default to placeholder
    return _buildPlaceholder(fileMetadata, color, imageBoxFix);
  } catch (e) {
    // Final fallback if anything fails
    try {
      return Container(
        width: 80.0,
        height: 80.0,
        decoration: BoxDecoration(
          color: color.withAlpha(30),
          borderRadius: BorderRadius.circular(4),
        ),
      );
    } catch (_) {
      // If even the fallback fails, return null
      return null;
    }
  }
}

// Implementation that will be used on platforms other than iOS/macOS
Widget? _buildBlurHashImage(FileMetadata fileMetadata, Color color, BoxFit imageBoxFix) {
  try {
    // Get dimensions from metadata if available
    int? width = fileMetadata.getImageWidth();
    int? height = fileMetadata.getImageHeight();
    
    // Use default dimensions if not specified
    width ??= 80;
    height ??= 80;
    
    // Calculate aspect ratio from dimensions if available
    double aspectRatio = 1.6; // default
    if (height > 0 && width > 0) {
      aspectRatio = width / height;
    }
    
    // Prevent extreme aspect ratios that could break layout
    if (aspectRatio > 3) aspectRatio = 3;
    if (aspectRatio < 0.3) aspectRatio = 0.3;

    // Import here to avoid iOS/macOS build errors
    // This code will only execute on Android and other platforms
    // ignore: avoid_dynamic_calls
    dynamic imageProvider;
    if (!SafePlatform.isIOS() && !SafePlatform.isMacOS()) {
      // Validate blurhash format
      final blurhash = fileMetadata.blurhash ?? '';
      if (blurhash.isEmpty || blurhash.length < 6) {
        return _buildPlaceholder(fileMetadata, color, imageBoxFix);
      }
      
      // We'll use dynamic to avoid compile errors, and platform checks to prevent runtime errors
      imageProvider = _createImageProvider(blurhash, width, height);
      
      if (imageProvider != null) {
        return Container(
          color: color.withAlpha(30),
          child: AspectRatio(
            aspectRatio: aspectRatio,
            child: Image(
              fit: imageBoxFix,
              width: width.toDouble(),
              height: height.toDouble(),
              image: imageProvider,
              errorBuilder: (context, error, stackTrace) {
                // On any error, show placeholder instead of error message
                return _buildPlaceholder(fileMetadata, color, imageBoxFix);
              },
            ),
          ),
        );
      }
    }
  } catch (e) {
    // Silently fail and use placeholder - no error messages to user
  }
  
  // Fallback 
  return _buildPlaceholder(fileMetadata, color, imageBoxFix);
}

// This will be implemented properly only on non-iOS platforms
dynamic _createImageProvider(String blurhash, int width, int height) {
  try {
    if (!SafePlatform.isIOS() && !SafePlatform.isMacOS()) {
      // Use the conditionally imported package
      return blurhash_ffi.BlurhashFfiImage(
        blurhash,
        decodingHeight: height,
        decodingWidth: width
      );
    }
  } catch (e) {
    // Silently handle errors - no printing to console
  }
  return null;
}

// Create a placeholder widget for when blurhash isn't available
Widget _buildPlaceholder(FileMetadata fileMetadata, Color color, BoxFit imageBoxFix) {
  try {
    int? width = fileMetadata.getImageWidth() ?? 80;
    int? height = fileMetadata.getImageHeight() ?? 80;
    
    // Default aspect ratio if dimensions are invalid
    double aspectRatio = 1.6;
    
    // Protect against zero height which would cause division by zero
    if (height > 0 && width > 0) {
      aspectRatio = width / height;
    }
    
    // Prevent extreme aspect ratios that could break layout
    if (aspectRatio > 3) aspectRatio = 3;
    if (aspectRatio < 0.3) aspectRatio = 0.3;
    
    return Container(
      color: color.withAlpha(30), // Very subtle background
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: Container(
          width: width.toDouble(),
          height: height.toDouble(),
          decoration: BoxDecoration(
            color: color.withAlpha(30),
            borderRadius: BorderRadius.circular(4),
          ),
          // No icon or text to make it clean and simple
        ),
      ),
    );
  } catch (e) {
    // Simplified fallback for any errors
    return Container(
      width: 80.0,
      height: 80.0,
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

// Nothing to replace this with, we're removing the unused method
