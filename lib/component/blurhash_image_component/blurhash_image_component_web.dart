import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Platform is not available on web, so we need to handle that through our utility
import 'package:nostrmo/component/blurhash_image_component/stub_platform.dart';

// For web, we'll use a simpler approach without external dependencies
// that might cause issues with Flutter web compatibility

Widget? genBlurhashImageWidget(
    FileMetadata fileMetadata, Color color, BoxFit imageBoxFix) {
  try {
    // On web, always use a simple placeholder
    // This avoids compatibility issues with web platform
    if (kIsWeb || fileMetadata.blurhash == null) {
      return _buildPlaceholder(fileMetadata, color, imageBoxFix);
    }
    
    // For non-web platforms that aren't iOS/macOS, delegate to the IO version
    // The IO implementation will handle this appropriately
    if (!SafePlatform.isIOS() && !SafePlatform.isMacOS()) {
      // Let the IO implementation handle non-web platforms
      return null;
    }
    
    // Fallback to placeholder
    return _buildPlaceholder(fileMetadata, color, imageBoxFix);
  } catch (e) {
    // If anything goes wrong, return null to use the default fallback
    return null;
  }
}

// We've simplified the web implementation to only use placeholders
// This avoids compatibility issues with the Flutter web platform

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
