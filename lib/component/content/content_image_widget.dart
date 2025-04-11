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

    Widget? main;
    Widget? placeholder;
    // Use blurhash if available and enabled
    if (settingsProvider.openBlurhashImage != OpenStatus.close &&
        widget.fileMetadata != null &&
        StringUtil.isNotBlank(widget.fileMetadata!.blurhash)) {
      // Note: Removed the PlatformUtil.isWeb() check to support blurhash on all platforms
      placeholder = genBlurhashImageWidget(
          widget.fileMetadata!, themeData.hintColor, widget.imageBoxFix);
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
        // Process URL to handle AVIF and other problematic formats
        if (PlatformUtil.isWeb() && 
            (imageUrl.toLowerCase().endsWith('.avif') || 
             imageUrl.toLowerCase().endsWith('.webp') ||
             imageUrl.toLowerCase().endsWith('.heic'))) {
          // For problematic formats, try to get a version without extension
          final extensionMatch = RegExp(r'\.([a-zA-Z0-9]+)$').firstMatch(imageUrl);
          if (extensionMatch != null) {
            final extension = extensionMatch.group(0) ?? '';
            imageUrl = imageUrl.substring(0, imageUrl.length - extension.length);
          }
        }
        
        // Try to load the image, with error handling
        try {
          imageProviders.add(CachedNetworkImageProvider(
            imageUrl,
            cacheManager: imageLocalCacheManager,
          ));
        } catch (e) {
          // If adding a specific image fails, just skip it
          print("Error creating image provider for $imageUrl: $e");
        }
      }
      
      // Only show the dialog if we have at least one valid image
      if (imageProviders.isNotEmpty) {
        // Ensure the initial index is valid
        int safeIndex = widget.imageIndex;
        if (safeIndex >= imageProviders.length) {
          safeIndex = 0;
        }
        
        MultiImageProvider multiImageProvider =
            MultiImageProvider(imageProviders, initialIndex: safeIndex);

        ImagePreviewDialog.show(
          context, 
          multiImageProvider,
          doubleTapZoomable: true, 
          swipeDismissible: true,
        );
      } else {
        // No valid images to show
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not load image for preview'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Catch any errors during the preview process
      print("Error previewing images: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error loading image preview'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}