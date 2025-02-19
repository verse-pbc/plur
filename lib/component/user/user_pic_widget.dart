import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/consts/base_consts.dart';
import 'package:nostrmo/provider/setting_provider.dart';
import 'package:nostrmo/util/theme_util.dart';
import 'package:provider/provider.dart';

import '../../data/metadata.dart';
import '../../provider/metadata_provider.dart';
import '../image_widget.dart';

class UserPicWidget extends StatefulWidget {
  String pubkey;

  double width;

  Metadata? metadata;

  UserPicWidget({
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

    return Selector<MetadataProvider, Metadata?>(
      builder: (context, metadata, child) {
        return buildWidget(metadata);
      },
      selector: (_, provider) {
        return provider.getMetadata(widget.pubkey);
      },
    );
  }

  Widget buildWidget(Metadata? metadata) {
    final themeData = Theme.of(context);
    var settingProvider = Provider.of<SettingProvider>(context);

    if (StringUtil.isNotBlank(widget.pubkey) &&
        settingProvider.pubkeyColor != OpenStatus.CLOSE) {
      double imageBorder = widget.width / 14;
      Widget? imageWidget;
      if (metadata != null) {
        if (settingProvider.profilePicturePreview != OpenStatus.CLOSE &&
            StringUtil.isNotBlank(metadata.picture)) {
          imageWidget = ImageWidget(
            imageUrl: metadata.picture!,
            width: widget.width - imageBorder * 2,
            height: widget.width - imageBorder * 2,
            fit: BoxFit.cover,
            placeholder: (context, url) => CircularProgressIndicator(),
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

    Widget? imageWidget;
    if (metadata != null) {
      if (settingProvider.profilePicturePreview != OpenStatus.CLOSE &&
          StringUtil.isNotBlank(metadata.picture)) {
        imageWidget = ImageWidget(
          imageUrl: metadata.picture!,
          width: widget.width,
          height: widget.width,
          fit: BoxFit.cover,
          placeholder: (context, url) => CircularProgressIndicator(),
        );
      }
    }

    return Container(
      width: widget.width,
      height: widget.width,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.width / 2),
        color: themeData.hintColor,
      ),
      child: imageWidget,
    );
  }
}
