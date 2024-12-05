import 'package:flutter/material.dart';
import 'package:nostr_sdk/nip172/community_info.dart';
import 'package:nostr_sdk/utils/string_util.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/provider/contact_list_provider.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import 'content/content_widget.dart';
import 'image_widget.dart';

class CommunityInfoWidget extends StatefulWidget {
  CommunityInfo info;

  CommunityInfoWidget({super.key, required this.info});

  @override
  State<StatefulWidget> createState() {
    return _CommunityInfoWidgetState();
  }
}

class _CommunityInfoWidgetState extends State<CommunityInfoWidget> {
  static const double IMAGE_WIDTH = 40;

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    var cardColor = themeData.cardColor;

    Widget? imageWidget;
    if (StringUtil.isNotBlank(widget.info.image)) {
      imageWidget = ImageWidget(
        imageUrl: widget.info.image!,
        width: IMAGE_WIDTH,
        height: IMAGE_WIDTH,
        fit: BoxFit.cover,
        placeholder: (context, url) => const CircularProgressIndicator(),
      );
    }

    Widget followBtn =
        Selector<ContactListProvider, bool>(builder: (context, exist, child) {
      IconData iconData = Icons.star_border;
      Color? color;
      if (exist) {
        iconData = Icons.star;
        color = Colors.yellow;
      }

      return GestureDetector(
        onTap: () {
          if (exist) {
            contactListProvider.removeCommunity(widget.info.aId.toAString());
          } else {
            contactListProvider.addCommunity(widget.info.aId.toAString());
          }
        },
        child: Container(
          margin: const EdgeInsets.only(
            left: Base.BASE_PADDING_HALF,
            right: Base.BASE_PADDING_HALF,
          ),
          child: Icon(
            iconData,
            color: color,
          ),
        ),
      );
    }, selector: (_, provider) {
      return provider.containCommunity(widget.info.aId.toAString());
    });

    List<Widget> list = [
      Container(
        margin: EdgeInsets.only(bottom: Base.BASE_PADDING_HALF),
        child: Row(
          children: [
            Container(
              alignment: Alignment.center,
              height: IMAGE_WIDTH,
              width: IMAGE_WIDTH,
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(IMAGE_WIDTH / 2),
                color: themeData.hintColor,
              ),
              child: imageWidget,
            ),
            Container(
              margin: const EdgeInsets.only(
                left: Base.BASE_PADDING,
              ),
              child: Text(
                widget.info.aId.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            followBtn,
          ],
        ),
      ),
    ];

    list.add(ContentWidget(
      content: widget.info.description,
      event: widget.info.event,
    ));

    return Container(
      decoration: BoxDecoration(color: cardColor),
      padding: const EdgeInsets.all(Base.BASE_PADDING),
      margin: const EdgeInsets.only(bottom: Base.BASE_PADDING_HALF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: list,
      ),
    );
  }
}
