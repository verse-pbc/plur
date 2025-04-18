import 'package:flutter/material.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/provider/contact_list_provider.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:provider/provider.dart';

import '../consts/base.dart';

class TagInfoWidget extends StatefulWidget {
  final String tag;

  final double height;

  final bool jumpable;

  const TagInfoWidget({
    super.key,
    required this.tag,
    this.height = 80,
    this.jumpable = false,
  });

  @override
  State<StatefulWidget> createState() {
    return _TagInfoWidgetState();
  }
}

class _TagInfoWidgetState extends State<TagInfoWidget> {
  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    var cardColor = themeData.cardColor;
    var bodyLargeFontSize = themeData.textTheme.bodyLarge!.fontSize;

    var main = Container(
      height: widget.height,
      color: cardColor,
      alignment: Alignment.center,
      margin: const EdgeInsets.only(bottom: Base.basePaddingHalf),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "#${widget.tag}",
            style: TextStyle(
              fontSize: bodyLargeFontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
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
                  contactListProvider.removeTag(widget.tag);
                } else {
                  contactListProvider.addTag(widget.tag);
                }
              },
              child: Container(
                margin: const EdgeInsets.only(left: Base.basePaddingHalf),
                child: Icon(
                  iconData,
                  color: color,
                ),
              ),
            );
          }, selector: (_, provider) {
            return provider.containTag(widget.tag);
          }),
        ],
      ),
    );

    if (widget.jumpable) {
      return GestureDetector(
        onTap: () {
          RouterUtil.router(context, RouterPath.tagDetail, widget.tag);
        },
        behavior: HitTestBehavior.translucent,
        child: main,
      );
    } else {
      return main;
    }
  }
}
