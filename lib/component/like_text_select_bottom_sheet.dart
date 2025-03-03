import 'package:flutter/material.dart';
import 'package:nostrmo/component/emoji_picker_widget.dart';

import '../consts/base.dart';
import '../router/index/index_drawer_content.dart';
import '../util/router_util.dart';

class LikeTextSelectBottomSheet extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _LikeTextSelectBottomSheet();
  }
}

class _LikeTextSelectBottomSheet extends State<LikeTextSelectBottomSheet> {
  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    var hintColor = themeData.hintColor;

    List<Widget> list = [];
    list.add(Container(
      padding: const EdgeInsets.only(
        top: Base.BASE_PADDING_HALF,
        bottom: Base.BASE_PADDING_HALF,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            width: 1,
            color: hintColor,
          ),
        ),
      ),
      child: IndexDrawerItemWidget(
        iconData: Icons.emoji_emotions_outlined,
        name: "Emoji",
        onTap: () {},
      ),
    ));

    list.add(EmojiPickerWidget((emoji) {
      RouterUtil.back(context, emoji);
    }));

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: list,
    );
  }
}
