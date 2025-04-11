import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'dart:math';

import '../main.dart';

class ImageWidget extends StatelessWidget {
  final String url;

  final double? width;

  final double? height;

  final BoxFit? fit;

  final PlaceholderWidgetBuilder? placeholder;

  const ImageWidget({super.key,
    required this.url,
    this.width,
    this.height,
    this.fit,
    this.placeholder,
  });
  
  // Regular expression to detect known problematic image formats
  static final RegExp problematicFormatRegex = RegExp(
    r'\.(avif|webp|heic|heif|tiff|bpg)$',
    caseSensitive: false
  );
  
  // Process URL to handle problematic formats and CORS issues
  String _getProcessedUrl(String originalUrl, bool isWeb) {
    // Handle CORS workarounds for nostr.build
    if (isWeb) {
      if (originalUrl.startsWith("https://nostr.build/i/p/")) {
        return originalUrl.replaceFirst(
            "https://nostr.build/i/p/", "https://pfp.nostr.build/");
      } else if (originalUrl.startsWith("https://nostr.build/i/")) {
        return originalUrl.replaceFirst(
            "https://nostr.build/i/", "https://image.nostr.build/");
      } else if (originalUrl.startsWith("https://cdn.nostr.build/i/")) {
        return originalUrl.replaceFirst(
            "https://cdn.nostr.build/i/", "https://image.nostr.build/");
      }
    }

    // Special handling for problematic image formats on web
    final match = problematicFormatRegex.firstMatch(originalUrl);
    if (match != null && isWeb) {
      // Remove the extension to let the server return a more compatible format
      final extension = match.group(0) ?? '';
      return originalUrl.substring(0, originalUrl.length - extension.length);
    }
    
    return originalUrl;
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = PlatformUtil.isWeb();
    final processedUrl = _getProcessedUrl(url, isWeb);
    final imageTag = "img_${url.hashCode}"; // Unique tag for preload optimization

    // Use try-catch at the entire build level to catch any unexpected errors
    try {
      return RepaintBoundary(
        child: CachedNetworkImage(
          key: ValueKey(url), // For proper widget identity
          imageUrl: processedUrl,
          width: width,
          height: height,
          fit: fit,
          fadeInDuration: const Duration(milliseconds: 200),
          fadeOutDuration: const Duration(milliseconds: 200),
          placeholder: placeholder,
          imageBuilder: (context, imageProvider) {
            // Successfully loaded image
            return Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: imageProvider,
                  fit: fit ?? BoxFit.cover,
                ),
              ),
            );
          },
          errorWidget: (context, url, error) {
            // Handle different types of errors with specialized fallbacks
            if (error.toString().contains("EncodingError") || 
                error.toString().contains("404") ||
                error.toString().contains("FormatException")) {
              
              // Different fallback strategies depending on the error
              return _handleImageError(context, url, error);
            }
            
            // Default error widget
            return _buildErrorWidget(context);
          },
          cacheManager: imageLocalCacheManager,
        ),
      );
    } catch (e) {
      // Ultimate fallback in case of any other errors
      return _buildErrorWidget(context);
    }
  }
  
  // More sophisticated error handling with different fallback strategies
  Widget _handleImageError(BuildContext context, String url, dynamic error) {
    // Only try one level of fallback to prevent endless loops
    if (url.contains("_fallback")) {
      return _buildErrorWidget(context);
    }
    
    String fallbackUrl;
    
    // Try to extract the extension
    final extensionMatch = RegExp(r'\.([a-zA-Z0-9]+)(?:\?.*)?$').firstMatch(url);
    if (extensionMatch != null) {
      // Create a fallback without extension
      final extension = extensionMatch.group(0) ?? '';
      fallbackUrl = "${url.substring(0, url.length - extension.length)}_fallback";
    } else if (url.contains("nostr.download")) {
      // Special case for nostr.download without extension
      fallbackUrl = "$url?format=jpg_fallback"; 
    } else {
      // Generic fallback - add a parameter to force a different format
      fallbackUrl = "$url?_fallback=1";
    }
    
    // Try loading with the fallback URL
    return CachedNetworkImage(
      imageUrl: fallbackUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: placeholder,
      // Don't nest further fallbacks
      errorWidget: (_, __, ___) => _buildErrorWidget(context),
      cacheManager: imageLocalCacheManager,
    );
  }
  
  // Helper method to build a consistent error widget
  Widget _buildErrorWidget(BuildContext context) {
    final themeColor = Theme.of(context).hintColor;
    
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: themeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.image_not_supported,
              size: _calculateIconSize(),
              color: themeColor,
            ),
            if (width != null && width! > 80 && height != null && height! > 80)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  "Image unavailable",
                  style: TextStyle(
                    fontSize: 12,
                    color: themeColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  // Calculate appropriate icon size based on container dimensions
  double _calculateIconSize() {
    if (width == null || height == null) return 24;
    
    final smallerDimension = min(width!, height!);
    
    // Scale the icon relative to container size, but keep it reasonable
    final iconSize = smallerDimension * 0.4;
    return min(max(iconSize, 16), 64); // Between 16 and 64
  }
}