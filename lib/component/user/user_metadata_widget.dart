import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/component/content/content_widget.dart';

import '../../consts/base.dart';
import '../../data/user.dart';
import 'user_top_widget.dart';
import 'user_badges_widget.dart';

class UserMetadataWidget extends StatefulWidget {
  String pubkey;

  User? user;

  bool jumpable;

  bool showBadges;

  bool userPicturePreview;

  UserMetadataWidget({super.key,
    required this.pubkey,
    this.user,
    this.jumpable = false,
    this.showBadges = false,
    this.userPicturePreview = false,
  });

  @override
  State<StatefulWidget> createState() {
    return _MetadataWidgetState();
  }
}

class _MetadataWidgetState extends State<UserMetadataWidget> {
  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    List<Widget> mainList = [];

    mainList.add(UserTopWidget(
      pubkey: widget.pubkey,
      user: widget.user,
      jumpable: widget.jumpable,
      userPicturePreview: widget.userPicturePreview,
    ));

    if (widget.showBadges) {
      mainList.add(UserBadgesWidget(
        key: Key("ubc_${widget.pubkey}"),
        pubkey: widget.pubkey,
      ));
    }

    if (widget.user != null &&
        StringUtil.isNotBlank(widget.user!.about)) {
      mainList.add(
        Container(
          width: double.maxFinite,
          padding: const EdgeInsets.only(
            top: Base.basePaddingHalf,
            left: Base.basePadding,
            right: Base.basePadding,
            bottom: Base.basePaddingHalf,
          ),
          // child: Text(widget.metadata!.about!),
          child: SizedBox(
            width: double.maxFinite,
            child: ContentWidget(
              content: widget.user!.about,
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
