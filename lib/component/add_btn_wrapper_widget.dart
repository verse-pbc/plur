import 'package:flutter/material.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:star_menu/star_menu.dart';

import '../consts/colors.dart';
import '../router/edit/editor_screen.dart';

class AddBtnWrapperWidget extends StatefulWidget {
  Widget child;

  AddBtnWrapperWidget({
    super.key,
    required this.child,
  });

  @override
  State<StatefulWidget> createState() {
    return _AddBtnWrapperWidgetState();
  }
}

class _AddBtnWrapperWidgetState extends State<AddBtnWrapperWidget> {
  StarMenuController starMenuController = StarMenuController();

  void closeMenu() {
    if (starMenuController.closeMenu != null) {
      starMenuController.closeMenu!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    var cardColor = themeData.cardColor;
    var iconSize = themeData.textTheme.bodyMedium!.fontSize;

    List<Widget> entries = [];
    var index = 0;

    entries.add(AddBtnStartItemButton(
      iconData: Icons.note,
      iconBackgroundColor: ColorList.ALL_COLOR[++index],
      iconSize: iconSize,
      name: "Note",
      backgroundColor: cardColor,
      onTap: () {
        closeMenu();
        EditorWidget.open(context);
      },
    ));
    entries.add(AddBtnStartItemButton(
      iconData: Icons.article,
      iconBackgroundColor: ColorList.ALL_COLOR[++index],
      iconSize: iconSize,
      name: "Article",
      backgroundColor: cardColor,
      onTap: () {
        closeMenu();
        EditorWidget.open(context, isLongForm: true);
      },
    ));
    entries.add(AddBtnStartItemButton(
      iconData: Icons.image,
      iconBackgroundColor: ColorList.ALL_COLOR[++index],
      iconSize: iconSize,
      name: "Media (NIP-94)",
      backgroundColor: cardColor,
      onTap: () {
        closeMenu();
      },
    ));
    entries.add(AddBtnStartItemButton(
      iconData: Icons.poll,
      iconBackgroundColor: ColorList.ALL_COLOR[++index],
      iconSize: iconSize,
      name: "Poll",
      backgroundColor: cardColor,
      onTap: () {
        closeMenu();
        EditorWidget.open(context, isPoll: true);
      },
    ));
    entries.add(AddBtnStartItemButton(
      iconData: Icons.trending_up,
      iconBackgroundColor: ColorList.ALL_COLOR[++index],
      iconSize: iconSize,
      name: "Zap Goal",
      backgroundColor: cardColor,
      onTap: () {
        closeMenu();
        EditorWidget.open(context, isZapGoal: true);
      },
    ));

    return StarMenu(
      params: const StarMenuParameters(
        shape: MenuShape.linear,
        linearShapeParams: LinearShapeParams(
          alignment: LinearAlignment.left,
          space: Base.basePadding,
        ),
      ),
      controller: starMenuController,
      items: entries,
      child: widget.child,
    );
  }
}

class AddBtnStartItemButton extends StatelessWidget {
  IconData iconData;

  Color iconBackgroundColor;

  double? iconSize;

  String name;

  Color backgroundColor;

  Function onTap;

  AddBtnStartItemButton({
    super.key,
    required this.iconData,
    required this.iconBackgroundColor,
    this.iconSize,
    required this.name,
    required this.backgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> list = [];
    list.add(Container(
      margin: const EdgeInsets.only(right: Base.basePaddingHalf),
      decoration: BoxDecoration(
        color: iconBackgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(4),
      child: Icon(
        iconData,
        color: Colors.white,
        size: iconSize,
      ),
    ));
    list.add(Text(name));

    return GestureDetector(
      onTap: () {
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.only(
          top: Base.basePaddingHalf,
          bottom: Base.basePaddingHalf,
          left: Base.basePadding,
          right: Base.basePadding,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              offset: const Offset(2, 5),
              blurRadius: 10,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: list,
        ),
      ),
    );
  }
}
