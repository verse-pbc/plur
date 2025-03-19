import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/consts/base_consts.dart';
import 'package:nostrmo/provider/settings_provider.dart';
import 'package:nostrmo/util/theme_util.dart';
import 'package:provider/provider.dart';

import '../../data/user.dart';
import '../../provider/metadata_provider.dart';
import '../image_widget.dart';

/// A stateful widget to display user's profile picture
class UserPicWidget extends StatefulWidget {
  /// The public key of the user.
  final String pubkey;

  /// The width of the profile picture.
  final double width;

  /// The metadata of the user. This is optional.
  final User? user;

  const UserPicWidget({
    super.key,
    required this.pubkey,
    required this.width,
    this.user,
  });

  @override
  State<StatefulWidget> createState() {
    return _UserPicWidgetState();
  }
}

class _UserPicWidgetState extends State<UserPicWidget> {
  @override
  Widget build(BuildContext context) {
    if (widget.user != null) {
      return buildWidget(widget.user);
    }

    // Using Selector to watch changes in MetadataProvider and rebuild widget
    // accordingly.
    return Selector<MetadataProvider, User?>(
      builder: (context, user, child) {
        return buildWidget(user);
      },
      selector: (_, provider) {
        return provider.getUser(widget.pubkey);
      },
    );
  }

  /// Builds the widget displaying the profile picture.
  ///
  /// If metadata is provided, it will use the picture URL from the metadata
  /// to display the profile picture. Otherwise, it will use a placeholder.
  Widget buildWidget(User? user) {
    final themeData = Theme.of(context);
    var provider = Provider.of<SettingsProvider>(context);

    // Calculate the border size for the image based on widget width.
    double imageBorder = widget.width / 14;

    Widget? imageWidget;
    if (user != null) {
      // Checking if profile picture preview is enabled and metadata contains a
      // picture.
      bool showPreview = provider.profilePicturePreview != OpenStatus.CLOSE;
      bool hasMetadataPic = StringUtil.isNotBlank(user.picture);

      if (showPreview && hasMetadataPic) {
        imageWidget = ImageWidget(
          imageUrl: user.picture!,
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
