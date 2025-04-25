import 'package:flutter/material.dart';
import 'package:nostrmo/provider/index_provider.dart';
import 'package:provider/provider.dart';

import '../../generated/l10n.dart';
import '../../main.dart';

class IndexBottomBar extends StatefulWidget {
  static const double height = 50;

  const IndexBottomBar({super.key});

  @override
  State<StatefulWidget> createState() {
    return _IndexBottomBar();
  }
}

class _IndexBottomBar extends State<IndexBottomBar> {
  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final localization = S.of(context);
    var indexProvider = Provider.of<IndexProvider>(context);
    var currentTap = indexProvider.currentTap;

    List<Widget> list = [];

    int current = 0;

    list.add(Expanded(
      child: IndexBottomBarButton(
        iconData: Icons.view_comfy_alt,
        index: current,
        selected: current == currentTap,
        title: localization.Communities,
        onDoubleTap: () {
          indexProvider.followScrollToTop();
        },
      ),
    ));
    current++;

    list.add(Expanded(
      child: IndexBottomBarButton(
        iconData: Icons.sms,
        index: current,
        selected: current == currentTap,
        title: localization.Messages,
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

  Future<void> onReady(BuildContext context) async {}
}

class IndexBottomBarButton extends StatelessWidget {
  final IconData iconData;
  final int index;
  final bool selected;
  final String? title;
  final Function(int)? onTap;
  final bool bigFont;
  final Function? onDoubleTap;

  const IndexBottomBarButton({
    super.key, 
    required this.iconData,
    required this.index,
    required this.selected,
    this.title,
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
      child: SizedBox(
        height: IndexBottomBar.height,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              iconData,
              color: selected ? selectedColor : null,
              size: bigFont ? 40 : null,
            ),
            if (title != null)
              Text(title!,
                  style: TextStyle(
                    color: selected ? selectedColor : null,
                    fontSize: 12,
                  ))
          ],
        ),
      ),
    );
  }
}
