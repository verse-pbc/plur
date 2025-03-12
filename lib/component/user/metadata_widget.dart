import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:nostrmo/nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/component/content/content_widget.dart';

import '../../consts/base.dart';
import '../../data/metadata.dart';
import '../content/content_decoder.dart';
import 'metadata_top_widget.dart';
import 'user_badges_widget.dart';

class MetadataWidget extends StatefulWidget {
  String pubkey;

  Metadata? metadata;

  bool jumpable;

  bool showBadges;

  bool userPicturePreview;

  MetadataWidget({
    required this.pubkey,
    this.metadata,
    this.jumpable = false,
    this.showBadges = false,
    this.userPicturePreview = false,
  });

  @override
  State<StatefulWidget> createState() {
    return _MetadataWidgetState();
  }
}

class _MetadataWidgetState extends State<MetadataWidget> {
  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    List<Widget> mainList = [];

    mainList.add(MetadataTopWidget(
      pubkey: widget.pubkey,
      metadata: widget.metadata,
      jumpable: widget.jumpable,
      userPicturePreview: widget.userPicturePreview,
    ));

    if (widget.showBadges) {
      mainList.add(UserBadgesWidget(
        key: Key("ubc_${widget.pubkey}"),
        pubkey: widget.pubkey,
      ));
    }

    if (widget.metadata != null &&
        StringUtil.isNotBlank(widget.metadata!.about)) {
      mainList.add(
        Container(
          width: double.maxFinite,
          padding: const EdgeInsets.only(
            top: Base.BASE_PADDING_HALF,
            left: Base.basePadding,
            right: Base.basePadding,
            bottom: Base.BASE_PADDING_HALF,
          ),
          // child: Text(widget.metadata!.about!),
          child: Container(
            width: double.maxFinite,
            child: ContentWidget(
              content: widget.metadata!.about,
              // TODO this should add source event
              showLinkPreview: false,
            ),
            // child: Column(
            //   crossAxisAlignment: CrossAxisAlignment.start,
            //   mainAxisSize: MainAxisSize.min,
            //   children: ContentDecoder.decode(
            //     context,
            //     widget.metadata!.about!,
            //     null,
            //     showLinkPreview: false,
            //   ),
            // ),
          ),
        ),
      );
    }

    return Container(
      color: themeData.cardColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: mainList,
      ),
    );
  }
}
