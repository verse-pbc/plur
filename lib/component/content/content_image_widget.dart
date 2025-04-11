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

  void previewImages(context) {
    List<String> imageList = widget.imageList ?? [];
    if (imageList.isEmpty) {
      imageList = [widget.imageUrl];
    }

    List<ImageProvider> imageProviders = [];
    for (var imageUrl in imageList) {
      imageProviders.add(CachedNetworkImageProvider(imageUrl));
    }

    MultiImageProvider multiImageProvider =
        MultiImageProvider(imageProviders, initialIndex: widget.imageIndex);

    ImagePreviewDialog.show(context, multiImageProvider,
        doubleTapZoomable: true, swipeDismissible: true);
  }
}
