import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/consts/base_consts.dart';
import 'package:nostrmo/provider/setting_provider.dart';
import 'package:nostrmo/util/theme_util.dart';
import 'package:provider/provider.dart';

import '../../data/metadata.dart';
import '../../provider/metadata_provider.dart';
import '../image_widget.dart';

/// A stateful widget to display user's profile picture
class UserPicWidget extends StatefulWidget {
  /// The public key of the user.
  final String pubkey;

  /// The width of the profile picture.
  final double width;

  /// The metadata of the user. This is optional.
  final Metadata? metadata;

  const UserPicWidget({
    super.key,
    required this.pubkey,
    required this.width,
    this.metadata,
  });

  @override
  State<StatefulWidget> createState() {
    return _UserPicWidgetState();
  }
}

class _UserPicWidgetState extends State<UserPicWidget> {
  @override
  Widget build(BuildContext context) {
    if (widget.metadata != null) {
      return buildWidget(widget.metadata);
    }

    // Using Selector to watch changes in MetadataProvider and rebuild widget
    // accordingly.
    return Selector<MetadataProvider, Metadata?>(
      builder: (context, metadata, child) {
        return buildWidget(metadata);
      },
      selector: (_, provider) {
        return provider.getMetadata(widget.pubkey);
      },
    );
  }

  /// Builds the widget displaying the profile picture.
  ///
  /// If metadata is provided, it will use the picture URL from the metadata
  /// to display the profile picture. Otherwise, it will use a placeholder.
  Widget buildWidget(Metadata? metadata) {
    final themeData = Theme.of(context);
    var provider = Provider.of<SettingProvider>(context);

    // Calculate the border size for the image based on widget width.
    double imageBorder = widget.width / 14;

    Widget? imageWidget;
    if (metadata != null) {
      // Checking if profile picture preview is enabled and metadata contains a
      // picture.
      bool showPreview = provider.profilePicturePreview != OpenStatus.CLOSE;
      bool hasMetadataPic = StringUtil.isNotBlank(metadata.picture);

      if (showPreview && hasMetadataPic) {
        imageWidget = ImageWidget(
          imageUrl: metadata.picture!,
          width: widget.width - imageBorder * 2,
          height: widget.width - imageBorder * 2,
          fit: BoxFit.cover,
          placeholder: (context, url) => const CircularProgressIndicator(),
        );
      }
    }

    return Container(
      width: widget.width,
      height: widget.width,
      clipBehavior: Clip.hardEdge,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.width / 2),
        color: themeData.customColors.accentColor,
      ),
      child: Container(
        width: widget.width - imageBorder * 2,
        height: widget.width - imageBorder * 2,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.width / 2 - imageBorder),
          color: themeData.hintColor,
        ),
        child: imageWidget,
      ),
    );
  }
}
