import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nostrmo/component/emoji_picker_widget.dart';

import '../consts/base.dart';
import '../generated/l10n.dart';
import '../router/index/index_drawer_content.dart';
import '../util/router_util.dart';
import '../util/theme_util.dart';

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
        top: Base.basePaddingHalf,
        bottom: Base.basePaddingHalf,
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
