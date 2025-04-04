import 'package:flutter/material.dart';

import '../consts/base.dart';
import '../consts/base_consts.dart';
import '../util/router_util.dart';

class EnumSelectorWidget extends StatelessWidget {
  final List<EnumObj> list;

  final Widget Function(BuildContext, EnumObj)? enumItemBuild;

  const EnumSelectorWidget({
    super.key, 
    required this.list,
    this.enumItemBuild,
  });

  static Future<EnumObj?> show(BuildContext context, List<EnumObj> list) async {
    return await showDialog<EnumObj?>(
      context: context,
      useRootNavigator: false,
      builder: (context) {
        return EnumSelectorWidget(
          list: list,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    Color cardColor = themeData.cardColor;
    var maxHeight = MediaQuery.of(context).size.height;

    List<Widget> widgets = [];
    for (var i = 0; i < list.length; i++) {
      var enumObj = list[i];
      if (enumItemBuild != null) {
        widgets.add(enumItemBuild!(context, enumObj));
      } else {
        widgets.add(EnumSelectorItemWidget(
          enumObj: enumObj,
          isLast: i == list.length - 1,
        ));
      }
    }

    Widget main = Container(
      width: double.infinity,
      padding: const EdgeInsets.only(
        left: Base.basePadding,
        right: Base.basePadding,
        top: Base.basePaddingHalf,
        bottom: Base.basePaddingHalf,
      ),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(15)),
        color: cardColor,
      ),
      constraints: BoxConstraints(
        maxHeight: maxHeight * 0.8,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: widgets,
        ),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.2),
      body: FocusScope(
        // autofocus: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            RouterUtil.back(context);
          },
          child: Container(
            width: double.infinity,
            height: double.infinity,
            padding: const EdgeInsets.only(
              left: Base.basePadding,
              right: Base.basePadding,
            ),
            alignment: Alignment.center,
            child: GestureDetector(
              onTap: () {},
              child: main,
            ),
          ),
        ),
      ),
    );
  }
}

class EnumSelectorItemWidget extends StatelessWidget {
  static const double height = 44;

  final EnumObj enumObj;

  final bool isLast;

  final Function(EnumObj)? onTap;

  final Color? color;

  const EnumSelectorItemWidget({
    super.key, 
    required this.enumObj,
    this.isLast = false,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    var dividerColor = themeData.dividerColor;

    Widget main = Container(
      padding: const EdgeInsets.only(
          left: Base.basePadding + 5, right: Base.basePadding + 5),
      child: Text(enumObj.name),
    );

    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          onTap!(enumObj);
        } else {
          RouterUtil.back(context, enumObj);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: color,
          border:
              isLast ? null : Border(bottom: BorderSide(color: dividerColor)),
        ),
        alignment: Alignment.center,
        height: height,
        child: main,
      ),
    );
  }
}
