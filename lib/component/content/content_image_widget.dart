import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/component/blurhash_image_component/blurhash_image_widget.dart'
    if (dart.library.io) 'package:nostrmo/component/blurhash_image_component/blurhash_image_component_io.dart'
    if (dart.library.js) 'package:nostrmo/component/blurhash_image_component/blurhash_image_component_web.dart';
import 'package:nostrmo/component/cust_state.dart';
import 'package:nostrmo/consts/base_consts.dart';
import 'package:nostrmo/main.dart';

import '../../consts/base.dart';
import '../image_widget.dart';
import '../image_preview_dialog.dart';

class ContentImageWidget extends StatefulWidget {
  final String imageUrl;

  final List<String>? imageList;

  final int imageIndex;

  final double? width;

  final double? height;

  final BoxFit imageBoxFix;

  final FileMetadata? fileMetadata;

  const ContentImageWidget({super.key,
    required this.imageUrl,
    this.imageList,
    this.imageIndex = 0,
    this.width,
    this.height,
    this.imageBoxFix = BoxFit.cover,
    this.fileMetadata,
  });

  @override
  State<StatefulWidget> createState() {
    return _ContentImageWidgetState();
  }
}

class _ContentImageWidgetState extends CustState<ContentImageWidget> {
  @override
  Future<void> onReady(BuildContext context) async {}

  @override
  Widget doBuild(BuildContext context) {
    final themeData = Theme.of(context);

    // Validate the image URL first
    if (widget.imageUrl.isEmpty || 
        widget.imageUrl == "null" || 
        widget.imageUrl == "undefined") {
      // Return a simple placeholder for invalid URLs
      return Container(
        width: widget.width,
        height: widget.height,
        margin: const EdgeInsets.only(
          top: Base.basePaddingHalf / 2,
          bottom: Base.basePaddingHalf / 2,
        ),
        decoration: BoxDecoration(
          color: themeData.hintColor.withAlpha(25), // ~10% opacity
          borderRadius: BorderRadius.circular(4),
        ),
      );
    }

    // Try-catch entire build to prevent widget errors
    try {
      Widget? main;
      Widget? placeholder;
      
      // Use blurhash if available and enabled
      if (settingsProvider.openBlurhashImage != OpenStatus.close &&
          widget.fileMetadata != null &&
          StringUtil.isNotBlank(widget.fileMetadata!.blurhash)) {
        try {
          placeholder = genBlurhashImageWidget(
              widget.fileMetadata!, themeData.hintColor, widget.imageBoxFix);
        } catch (e) {
          // Silently fail if blurhash generation fails
          placeholder = null;
        }
      }
      
      main = GestureDetector(
        onTap: () {
          previewImages(context);
        },
        child: Center(
          child: ImageWidget(
            url: widget.imageUrl,
            fit: widget.imageBoxFix,
            width: widget.width,
            height: widget.height,
            placeholder:
                placeholder != null ? (context, url) => placeholder! : null,
          ),
        ),
      );

      return Container(
        width: widget.width,
        height: widget.height,
        margin: const EdgeInsets.only(
          top: Base.basePaddingHalf / 2,
          bottom: Base.basePaddingHalf / 2,
        ),
        child: main,
      );
    } catch (e) {
      // If anything fails, return a simple placeholder
      return Container(
        width: widget.width,
        height: widget.height,
        margin: const EdgeInsets.only(
          top: Base.basePaddingHalf / 2,
          bottom: Base.basePaddingHalf / 2,
        ),
        decoration: BoxDecoration(
          color: themeData.hintColor.withAlpha(25), // ~10% opacity
          borderRadius: BorderRadius.circular(4),
        ),
      );
    }
  }

  void previewImages(BuildContext context) {
    try {
      // Get the image list, falling back to the single image
      List<String> imageList = widget.imageList ?? [];
      if (imageList.isEmpty) {
        imageList = [widget.imageUrl];
      }
      
      // Process image URLs to handle problematic formats before preview
      List<ImageProvider> imageProviders = [];
      for (var imageUrl in imageList) {
        // Skip empty or invalid URLs
        if (imageUrl.isEmpty || imageUrl == "null" || imageUrl == "undefined") {
          continue;
        }
        
        // Skip nostr.download URLs as they frequently cause problems
        if (imageUrl.contains('nostr.download/')) {
          continue;
        }
        
        // Process URL to handle AVIF and other problematic formats
        if (PlatformUtil.isWeb()) {
          // Check for problematic image formats
          final problematicFormats = ['.avif', '.webp', '.heic', '.heif', '.tiff', '.bpg', '.jfif'];
          final lowercaseUrl = imageUrl.toLowerCase();
          bool isProblem = false;
          
          for (final format in problematicFormats) {
            if (lowercaseUrl.endsWith(format)) {
              isProblem = true;
              break;
            }
          }
          
          if (isProblem) {
            // For problematic formats, try to get a version without extension
            final extensionMatch = RegExp(r'\.([a-zA-Z0-9]+)$').firstMatch(imageUrl);
            if (extensionMatch != null) {
              final extension = extensionMatch.group(0) ?? '';
              imageUrl = imageUrl.substring(0, imageUrl.length - extension.length);
            }
          }
          
          // Handle CORS issues for specific hosts
          if (imageUrl.startsWith("https://nostr.build/i/p/")) {
            imageUrl = imageUrl.replaceFirst(
                "https://nostr.build/i/p/", "https://pfp.nostr.build/");
          } else if (imageUrl.startsWith("https://nostr.build/i/")) {
            imageUrl = imageUrl.replaceFirst(
                "https://nostr.build/i/", "https://image.nostr.build/");
          } else if (imageUrl.startsWith("https://cdn.nostr.build/i/")) {
            imageUrl = imageUrl.replaceFirst(
                "https://cdn.nostr.build/i/", "https://image.nostr.build/");
          }
        }
        
        // Try to load the image, with error handling
        try {
          // Add a simple validation for web URLs
          if (!imageUrl.startsWith('http://') && !imageUrl.startsWith('https://')) {
            continue;
          }
          
          imageProviders.add(CachedNetworkImageProvider(
            imageUrl,
            cacheManager: imageLocalCacheManager,
          ));
        } catch (e) {
          // If adding a specific image fails, just skip it
          // Silent fail - no logging
        }
      }
      
      // Only show the dialog if we have at least one valid image
      if (imageProviders.isNotEmpty) {
        // Ensure the initial index is valid
        int safeIndex = widget.imageIndex;
        if (safeIndex >= imageProviders.length) {
          safeIndex = 0;
        }
        
        // Create the multi-image provider
        MultiImageProvider multiImageProvider =
            MultiImageProvider(imageProviders, initialIndex: safeIndex);

        // Show the image preview dialog with a try-catch block for additional safety
        try {
          ImagePreviewDialog.show(
            context, 
            multiImageProvider,
            doubleTapZoomable: true, 
            swipeDismissible: true,
          );
        } catch (e) {
          // No message to user - just fail silently
        }
      }
      // Silent failure if no images to show - no error messages to console or user
    } catch (e) {
      // Catch any errors during the preview process - fail silently
    }
  }
}