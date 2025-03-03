import 'package:flutter/material.dart';
import 'package:nostrmo/provider/index_provider.dart';
import 'package:provider/provider.dart';

import '../../component/add_btn_wrapper_widget.dart';
import '../../main.dart';

class IndexBottomBar extends StatefulWidget {
  static const double height = 50;

  IndexBottomBar();

  @override
  State<StatefulWidget> createState() {
    return _IndexBottomBar();
  }
}

class _IndexBottomBar extends State<IndexBottomBar> {
  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    var indexProvider = Provider.of<IndexProvider>(context);
    var currentTap = indexProvider.currentTap;

    List<Widget> list = [];

    int current = 0;

    list.add(Expanded(
      child: IndexBottomBarButton(
        iconData: Icons.home_rounded,
        index: current,
        selected: current == currentTap,
        onDoubleTap: () {
          indexProvider.followScrollToTop();
        },
      ),
    ));
    current++;

    if (!nostr!.isReadOnly()) {
      list.add(Expanded(
        child: AddBtnWrapperWidget(
          child: IndexBottomBarButton(
            iconData: Icons.add_circle_outline_rounded, // notifications_active
            index: -1,
            selected: false,
            bigFont: true,
            onTap: (value) {
            },
          ),
        ),
      ));
    }

    list.add(Expanded(
      child: IndexBottomBarButton(
        iconData: Icons.mail_rounded,
        index: current,
        selected: current == currentTap,
      ),
    ));
    current++;

    return Container(
      decoration: BoxDecoration(
          border: Border(
        top: BorderSide(
          width: 1,
          color: themeData.scaffoldBackgroundColor,
        ),
      )),
      child: BottomAppBar(
        color: themeData.cardColor,
        surfaceTintColor: themeData.cardColor,
        shadowColor: themeData.shadowColor,
        height: IndexBottomBar.height,
        padding: EdgeInsets.zero,
        child: Container(
          color: Colors.transparent,
          width: double.infinity,
          child: Row(
            children: list,
          ),
        ),
      ),
    );
  }

  @override
  Future<void> onReady(BuildContext context) async {}
}

class IndexBottomBarButton extends StatelessWidget {
  final IconData iconData;
  final int index;
  final bool selected;
  final Function(int)? onTap;
  bool bigFont;
  Function? onDoubleTap;

  IndexBottomBarButton({
    required this.iconData,
    required this.index,
    required this.selected,
    this.onTap,
    this.onDoubleTap,
    this.bigFont = false,
  });

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    var mainColor = themeData.primaryColor;
    // var settingsProvider = Provider.of<SettingsProvider>(context);
    // var bottomIconColor = settingsProvider.bottomIconColor;

    Color? selectedColor = mainColor;

    return InkWell(
      onTap: () {
        if (onTap != null) {
          onTap!(index);
        } else {
          indexProvider.setCurrentTap(index);
        }
      },
      onDoubleTap: () {
        if (onDoubleTap != null) {
          onDoubleTap!();
        }
      },
      child: Container(
        height: IndexBottomBar.height,
        child: Icon(
          iconData,
          color: selected ? selectedColor : null,
          size: bigFont ? 40 : null,
        ),
      ),
    );
  }
}
