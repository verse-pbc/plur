import 'package:flutter/material.dart';
import 'package:nostrmo/nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/component/user/follow_btn_widget.dart';
import 'package:nostrmo/component/user/name_widget.dart';
import 'package:nostrmo/component/user/user_pic_widget.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/data/metadata.dart';
import 'package:nostrmo/provider/metadata_provider.dart';
import 'package:provider/provider.dart';

import '../image_widget.dart';

class SimpleMetadataWidget extends StatefulWidget {
  String pubkey;

  Metadata? metadata;

  bool showFollow;

  SimpleMetadataWidget({
    super.key,
    required this.pubkey,
    this.metadata,
    this.showFollow = false,
  });

  @override
  State<StatefulWidget> createState() {
    return _SimpleMetadataWidgetState();
  }
}

class _SimpleMetadataWidgetState extends State<SimpleMetadataWidget> {
  static const double IMAGE_WIDTH = 50;

  static const double HEIGHT = 64;

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    if (widget.metadata != null) {
      return buildWidget(themeData, widget.metadata!);
    }

    return Selector<MetadataProvider, Metadata?>(
        builder: (context, metadata, child) {
      if (metadata == null) {
        return Container(
          height: HEIGHT,
          color: themeData.hintColor,
        );
      }

      return buildWidget(themeData, metadata);
    }, selector: (context, provider) {
      return provider.getMetadata(widget.pubkey);
    });
  }

  Widget buildWidget(ThemeData themeData, Metadata metadata) {
    var cardColor = themeData.cardColor;

    Widget? bannerImage;
    if (StringUtil.isNotBlank(metadata.banner)) {
      bannerImage = ImageWidget(
        imageUrl: metadata.banner!,
        width: double.maxFinite,
        height: HEIGHT,
        fit: BoxFit.fitWidth,
      );
    } else {
      bannerImage = Container();
    }

    Widget userImageWidget = Container(
      margin: const EdgeInsets.only(
        right: Base.BASE_PADDING,
      ),
      child: UserPicWidget(
        pubkey: widget.pubkey,
        width: IMAGE_WIDTH,
        metadata: metadata,
      ),
    );

    List<Widget> list = [
      bannerImage,
      Container(
        height: HEIGHT,
        color: cardColor.withOpacity(0.4),
      ),
      Container(
        padding: const EdgeInsets.only(left: Base.BASE_PADDING),
        child: Row(
          children: [
            userImageWidget,
            NameWidget(
              pubkey: metadata.pubkey!,
              metadata: metadata,
            ),
          ],
        ),
      ),
    ];

    if (widget.showFollow) {
      list.add(Positioned(
        right: Base.BASE_PADDING,
        child: FollowBtnWidget(
          pubkey: widget.pubkey,
          followedBorderColor: themeData.primaryColor,
        ),
      ));
    }

    return SizedBox(
      height: HEIGHT,
      child: Stack(
        alignment: Alignment.center,
        children: list,
      ),
    );
  }
}
