import 'package:flutter/material.dart';
import 'package:nostrmo/util/theme_util.dart';

import '../../component/user/user_pic_widget.dart';
import '../../consts/base.dart';
import '../../main.dart';
import '../../util/table_mode_util.dart';

/// A custom app bar widget for the main/home page of the application that includes
/// a user profile picture, optional center and right widgets, and adapts to tablet mode.
///
/// The app bar has a fixed height of 56 logical pixels (excluding status bar padding)
/// and includes:
/// * Left: User profile picture (or empty space in tablet mode)
/// * Center: Optional center widget
/// * Right: Optional right widget
class IndexAppBar extends StatefulWidget {
  static const double height = 56;

  final Widget? center;
  final Widget? right;

  const IndexAppBar({super.key, this.center, this.right});

  @override
  State<StatefulWidget> createState() {
    return _IndexAppBar();
  }
}

class _IndexAppBar extends State<IndexAppBar> {
  // Height/width of the user profile picture
  final double picHeight = 30;

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final paddingTop = mediaDataCache.padding.top;
    final appBarBackgroundColor = themeData.appBarTheme.backgroundColor;

    // Configure user profile picture based on device mode
    Widget? userPicWidget;
    if (!TableModeUtil.isTableMode()) {
      // In phone mode, show clickable user profile picture that opens drawer
      userPicWidget = GestureDetector(
        onTap: () {
          Scaffold.of(context).openDrawer();
        },
        child: UserPicWidget(
          pubkey: nostr!.publicKey,
          width: picHeight,
        ),
      );
    } else {
      // In tablet mode, maintain spacing but hide profile picture
      userPicWidget = Container(
        width: picHeight,
      );
    }

    // Use provided widgets or fallback to empty containers
    final center = widget.center ?? Container();
    final right = widget.right ?? Container();

    return Container(
      padding: EdgeInsets.only(
        top: paddingTop, // Account for status bar
        left: Base.basePadding,
        right: Base.basePadding,
      ),
      height: paddingTop + IndexAppBar.height,
      decoration: BoxDecoration(
        color: appBarBackgroundColor,
        border: Border(
          bottom: BorderSide(
            width: 1,
            color: themeData.customColors.separatorColor,
          ),
        ),
      ),
      child: Row(children: [
        // Left section - User profile picture
        Container(
          child: userPicWidget,
        ),
        // Center section - Flexible to take remaining space
        Expanded(
          child: Container(
            child: center,
          ),
        ),
        // Right section
        Container(
          child: right,
        )
      ]),
    );
  }
}
