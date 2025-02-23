import 'package:flutter/material.dart';

import '../util/router_util.dart';
import '../util/theme_util.dart';

class Appbar4Stack extends StatefulWidget {
  static double height = 46;

  Widget? title;

  Color? textColor;

  Color? backgroundColor;

  Widget? action;

  Appbar4Stack({
    this.title,
    this.textColor,
    this.backgroundColor,
    this.action,
  });

  @override
  State<StatefulWidget> createState() {
    return _Appbar4Stack();
  }
}

class _Appbar4Stack extends State<Appbar4Stack> {
  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    var backgroundColor = widget.backgroundColor;
    backgroundColor ??= themeData.appBarTheme.backgroundColor;

    List<Widget> list = [
      GestureDetector(
        child: Container(
          alignment: Alignment.center,
          width: Appbar4Stack.height,
          child: Icon(
            Icons.arrow_back_ios_new,
            color: widget.textColor,
          ),
        ),
        onTap: () {
          RouterUtil.back(context);
        },
      )
    ];

    if (widget.title != null) {
      list.add(Expanded(child: widget.title!));
    } else {
      list.add(Expanded(child: Container()));
    }

    if (widget.action != null) {
      list.add(Container(
        child: widget.action,
      ));
    } else {
      list.add(Container(
        width: Appbar4Stack.height,
      ));
    }

    return Container(
      height: Appbar4Stack.height,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          bottom: BorderSide(
            color: themeData.customColors.separatorColor,
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: list,
      ),
    );
  }
}
