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
    var indexProvider = Provider.of<IndexProvider>(context);
    var currentTap = indexProvider.currentTap;

    List<Widget> list = [];

    // Communities icon - for groups/communities tab
    list.add(Expanded(
      child: IndexBottomBarButton(
        iconData: Icons.group_rounded,
        index: 0, // Using absolute index instead of counter for stability
        selected: 0 == currentTap,
        label: S.of(context).communities,
        onDoubleTap: () {
          indexProvider.followScrollToTop();
        },
      ),
    ));

    // Messages icon (DMs)
    list.add(Expanded(
      child: IndexBottomBarButton(
        iconData: Icons.message_rounded,
        index: 1, // Using absolute index instead of counter
        selected: 1 == currentTap,
        label: S.of(context).messages,
      ),
    ));
    
    // Search icon
    list.add(Expanded(
      child: IndexBottomBarButton(
        iconData: Icons.search_rounded,
        index: 2, // Using absolute index
        selected: 2 == currentTap,
        label: S.of(context).search,
      ),
    ));

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
  final Function(int)? onTap;
  final bool bigFont;
  final Function? onDoubleTap;
  final String? label; // Added label for text under the icon

  const IndexBottomBarButton({
    super.key, 
    required this.iconData,
    required this.index,
    required this.selected,
    this.onTap,
    this.onDoubleTap,
    this.bigFont = false,
    this.label,
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
              size: bigFont ? 32 : 24,
            ),
            if (label != null)
              Text(
                label!,
                style: TextStyle(
                  fontSize: 10,
                  color: selected ? selectedColor : themeData.textTheme.bodyMedium?.color,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
