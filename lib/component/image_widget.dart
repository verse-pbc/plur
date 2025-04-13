import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import 'blurhash_image_component/stub_platform.dart';

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
  // Expanded list of problematic formats for web platform
  static final RegExp problematicFormatRegex = RegExp(
    r'\.(avif|webp|heic|heif|tiff|bpg|jfif)$',
    caseSensitive: false
  );
  
  // Process URL to handle problematic formats and CORS issues
  String _getProcessedUrl(String originalUrl, bool isWeb) {
    try {
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
    } catch (e) {
      // Silently handle any URL processing errors and return original
    }
    
    return originalUrl;
  }

  @override
  Widget build(BuildContext context) {
    // Wrap the entire build method in a try-catch to prevent widget errors
    try {
      // Add safe default to handle null or invalid URLs
      if (url.isEmpty || url == "null" || url == "undefined") {
        return _buildErrorWidget(context);
      }
      
      // Get platform info just once
      final isWeb = SafePlatform.isWeb();
      
      // Additional verification for problematic URLs on web
      if (isWeb) {
        // Check for obviously problematic formats on web
        if (_isUnsupportedFormatOnWeb(url)) {
          // For known problematic formats, just show placeholder without trying to load
          return _buildErrorWidget(context);
        }
      }
      
      // Process the URL safely with additional error handling
      String processedUrl;
      try {
        processedUrl = _getProcessedUrl(url, isWeb);
      } catch (e) {
        // If URL processing fails, use original URL
        processedUrl = url;
      }

      // On web, use a different approach with extra error handling
      if (isWeb) {
        return _buildWebImageWidget(context, processedUrl);
      } else {
        // Use normal CachedNetworkImage on non-web platforms
        // Check if cacheManager is available
        if (imageLocalCacheManager != null) {
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
                try {
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
                } catch (e) {
                  // Handle errors in the image builder
                  return _buildErrorWidget(context);
                }
              },
              errorWidget: (context, url, error) {
                // Always return the simple error widget regardless of error type
                return _buildErrorWidget(context);
              },
              cacheManager: imageLocalCacheManager,
            ),
          );
        } else {
          // Fallback to standard Image.network if cacheManager is not available
          try {
            return Image.network(
              processedUrl,
              width: width,
              height: height,
              fit: fit ?? BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildErrorWidget(context);
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) {
                  return child;
                }
                // Create a loading placeholder
                final themeColor = Theme.of(context).hintColor;
                final bgColor = themeColor.withAlpha(25); // ~10% opacity
                return Container(
                  width: width,
                  height: height,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              },
            );
          } catch (e) {
            return _buildErrorWidget(context);
          }
        }
      }
    } catch (e) {
      // Ultimate fallback in case of any other errors
      try {
        // Return a placeholder widget if context is still valid
        return _buildErrorWidget(context);
      } catch (_) {
        // If context is invalid or any other error happens
        // Return simplest possible widget that won't throw another error
        return SizedBox(width: width, height: height);
      }
    }
  }
  
  // Special handler for web platform to avoid decoding errors
  Widget _buildWebImageWidget(BuildContext context, String processedUrl) {
    // Use a simpler approach for web to avoid compatibility issues
    try {
      // First verify the URL is valid to avoid web platform errors
      if (processedUrl.isEmpty || 
          !processedUrl.startsWith('http') ||
          _isUnsupportedFormatOnWeb(processedUrl)) {
        // If we know this image will cause problems, don't even try to load it
        return _buildErrorWidget(context);
      }
      
      // Replace nostr.download with a more reliable image host if possible
      if (processedUrl.contains('nostr.download/')) {
        // Just use a placeholder for nostr.download URLs since they frequently fail
        return _buildErrorWidget(context);
      }
      
      // Use standard Image.network with error handling for web
      return Image.network(
        processedUrl,
        width: width,
        height: height,
        fit: fit ?? BoxFit.cover,
        // Very important: errorBuilder for when image fails to load
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorWidget(context);
        },
        // Handle loading state with placeholder
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }
          final themeColor = Theme.of(context).hintColor;
          final bgColor = themeColor.withAlpha(25); // ~10% opacity
          return Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(4),
            ),
          );
        },
      );
    } catch (e) {
      // Catch any other errors
      return _buildErrorWidget(context);
    }
  }
  
  // Check if the URL points to a format known to be problematic on web
  bool _isUnsupportedFormatOnWeb(String imageUrl) {
    try {
      final lowercaseUrl = imageUrl.toLowerCase();
      
      // Check for nostr.download which seems to have issues
      if (lowercaseUrl.contains('nostr.download/')) {
        return true;
      }
      
      // Check known problematic formats
      if (problematicFormatRegex.hasMatch(lowercaseUrl)) {
        return true;
      }
      
      // Also check for obviously malformed URLs
      if (!lowercaseUrl.startsWith('http://') && 
          !lowercaseUrl.startsWith('https://') &&
          !lowercaseUrl.startsWith('data:')) {
        return true;
      }
    } catch (e) {
      // If anything goes wrong in the check, consider it problematic
      return true;
    }
    
    return false;
  }
  
  // Helper method to build a consistent error widget
  Widget _buildErrorWidget(BuildContext context) {
    try {
      final themeColor = Theme.of(context).hintColor;
      final bgColor = themeColor.withAlpha(25); // ~10% opacity
      
      // Create a simpler placeholder that doesn't show an error message
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(4),
        ),
        // No icon or text to make it clean and simple
      );
    } catch (e) {
      // If even the error widget creation fails, use the most basic fallback
      return SizedBox(width: width, height: height);
    }
  }
}