import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';

import '../../util/theme_util.dart';

/// Displays the image of a community with an appropiate fallback mechanism.
class CommunityImageWidget extends StatelessWidget {
  /// Identifier to show when there is no name inside [metadata].
  final String identifier;

  /// Metadata of the community being displayed.
  final GroupMetadata? metadata;

  /// Size used when doing layout for displaying the image.
  static const double imageSize = 120;

  const CommunityImageWidget(this.identifier, this.metadata, {super.key});

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final separatorColor = themeData.customColors.separatorColor;
    final dimmedColor = themeData.customColors.dimmedColor;
    final imageUrl = metadata?.picture;
    return Container(
      width: imageSize,
      height: imageSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: separatorColor,
          width: 4,
        ),
      ),
      child: ClipOval(
        child: imageUrl != null
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                width: imageSize,
                height: imageSize,
              )
            : Icon(Icons.group, color: dimmedColor, size: 64),
      ),
    );
  }
}
