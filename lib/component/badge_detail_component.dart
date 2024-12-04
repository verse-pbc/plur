import 'package:flutter/material.dart';
import 'package:nostr_sdk/nip58/badge_definition.dart';
import 'package:nostr_sdk/utils/string_util.dart';
import 'package:nostrmo/component/image_component.dart';
import 'package:nostrmo/component/user/name_component.dart';
import 'package:nostrmo/component/user/simple_name_component.dart';
import 'package:nostrmo/component/user/user_pic_component.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostrmo/util/router_util.dart';

import '../generated/l10n.dart';

class BadgeDetailWidget extends StatefulWidget {
  BadgeDefinition badgeDefinition;

  BadgeDetailWidget({
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
    var themeData = Theme.of(context);
    var cardColor = themeData.cardColor;
    var titleFontSize = themeData.textTheme.bodyLarge!.fontSize;
    var s = S.of(context);

    List<Widget> list = [];

    if (StringUtil.isNotBlank(widget.badgeDefinition.image)) {
      list.add(Container(
        padding: const EdgeInsets.only(
          top: Base.BASE_PADDING,
          left: Base.BASE_PADDING,
          right: Base.BASE_PADDING,
        ),
        child: ImageWidget(imageUrl: widget.badgeDefinition.image!),
      ));
    }

    if (StringUtil.isNotBlank(widget.badgeDefinition.name)) {
      list.add(Container(
        margin: EdgeInsets.only(top: Base.BASE_PADDING),
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
        margin: EdgeInsets.only(top: Base.BASE_PADDING),
        child: Text(
          widget.badgeDefinition.description!,
          textAlign: TextAlign.center,
        ),
      ));
    }

    if (StringUtil.isNotBlank(widget.badgeDefinition.pubkey)) {
      list.add(Container(
        margin: EdgeInsets.only(top: Base.BASE_PADDING),
        child: Row(
          children: [
            Expanded(child: Text(s.Creator)),
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
                    margin: EdgeInsets.only(left: Base.BASE_PADDING_HALF),
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
      padding: EdgeInsets.all(Base.BASE_PADDING * 2),
      color: cardColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: list,
      ),
    );
  }
}
