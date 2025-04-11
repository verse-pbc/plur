import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';

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

  @override
  Widget build(BuildContext context) {
    final imageUrl = () {
      if (PlatformUtil.isWeb()) {
        // TODO temp handle nostr.build cors error, these should be handled later.
        if (url.startsWith("https://nostr.build/i/p/")) {
          return url.replaceFirst(
              "https://nostr.build/i/p/", "https://pfp.nostr.build/");
        } else if (url.startsWith("https://nostr.build/i/")) {
          return url.replaceFirst(
              "https://nostr.build/i/", "https://image.nostr.build/");
        } else if (url.startsWith("https://cdn.nostr.build/i/")) {
          return url.replaceFirst(
              "https://cdn.nostr.build/i/", "https://image.nostr.build/");
        }
      }
      return url;
    }();

    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: placeholder,
      errorWidget: (context, url, error) => const Icon(Icons.error),
      cacheManager: imageLocalCacheManager,
      // imageRenderMethodForWeb: ImageRenderMethodForWeb.HttpGet,
    );
  }
}
