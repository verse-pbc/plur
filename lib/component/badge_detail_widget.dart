import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/component/image_widget.dart';
import 'package:nostrmo/component/user/name_widget.dart';
import 'package:nostrmo/component/user/user_pic_widget.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostrmo/util/router_util.dart';

import '../generated/l10n.dart';

class BadgeDetailWidget extends StatefulWidget {
  final BadgeDefinition badgeDefinition;

  const BadgeDetailWidget({
    super.key,
    required this.badgeDefinition,
  });

  @override
  State<StatefulWidget> createState() {
    return _BadgeDetailWidgetState();
  }
}

class _BadgeDetailWidgetState extends State<BadgeDetailWidget> {
  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    var cardColor = themeData.cardColor;
    var titleFontSize = themeData.textTheme.bodyLarge!.fontSize;
    final localization = S.of(context);

    List<Widget> list = [];

    if (StringUtil.isNotBlank(widget.badgeDefinition.image)) {
      list.add(Container(
        padding: const EdgeInsets.only(
          top: Base.basePadding,
          left: Base.basePadding,
          right: Base.basePadding,
        ),
        child: ImageWidget(imageUrl: widget.badgeDefinition.image!),
      ));
    }

    if (StringUtil.isNotBlank(widget.badgeDefinition.name)) {
      list.add(Container(
        margin: const EdgeInsets.only(top: Base.basePadding),
        child: Text(
          widget.badgeDefinition.name!,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: titleFontSize,
          ),
          textAlign: TextAlign.center,
        ),
      ));
    }

    if (StringUtil.isNotBlank(widget.badgeDefinition.description)) {
      list.add(Container(
        margin: const EdgeInsets.only(top: Base.basePadding),
        child: Text(
          widget.badgeDefinition.description!,
          textAlign: TextAlign.center,
        ),
      ));
    }

    if (StringUtil.isNotBlank(widget.badgeDefinition.pubkey)) {
      list.add(Container(
        margin: const EdgeInsets.only(top: Base.basePadding),
        child: Row(
          children: [
            Expanded(child: Text(localization.Creator)),
            GestureDetector(
              onTap: () {
                RouterUtil.router(
                    context, RouterPath.USER, widget.badgeDefinition.pubkey);
              },
              behavior: HitTestBehavior.translucent,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  UserPicWidget(
                      pubkey: widget.badgeDefinition.pubkey, width: 26),
                  Container(
                    margin: const EdgeInsets.only(left: Base.basePaddingHalf),
                    child: NameWidget(pubkey: widget.badgeDefinition.pubkey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ));
    }

    return Container(
      padding: const EdgeInsets.all(Base.basePadding * 2),
      color: cardColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: list,
      ),
    );
  }
}
