import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';

import '../../component/group/group_avatar_widget.dart';

/// Displays the image of a community with an appropriate fallback mechanism.
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
    final imageUrl = metadata?.picture;
    
    // Use the GroupAvatar widget for consistent community image display
    return GroupAvatar(
      imageUrl: imageUrl,
      size: imageSize,
      borderWidth: 4.0,
    );
  }
}
