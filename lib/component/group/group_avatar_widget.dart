import 'package:flutter/material.dart';
import 'package:nostrmo/util/theme_util.dart';

/// A circular avatar widget for displaying group images.
/// Shows a fallback group icon when no image is provided or when image loading fails.
class GroupAvatar extends StatelessWidget {
  /// The URL of the group's avatar image
  final String? imageUrl;

  /// The size of the avatar. Both width and height will be set to this value.
  /// Defaults to 130.0
  final double size;

  /// The width of the border around the avatar.
  /// Defaults to 4.0
  final double borderWidth;

  const GroupAvatar({
    super.key,
    this.imageUrl,
    this.size = 130.0,
    this.borderWidth = 4.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconSize = size * 0.46;

    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: theme.customColors.dimmedColor,
          width: borderWidth,
        ),
      ),
      child: SizedBox(
        width: size,
        height: size,
        child: ClipOval(
          child: imageUrl != null
              ? Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.group,
                    size: iconSize,
                    color: Colors.white,
                  ),
                )
              : Icon(
                  Icons.group,
                  size: iconSize,
                  color: Colors.white,
                ),
        ),
      ),
    );
  }
}
