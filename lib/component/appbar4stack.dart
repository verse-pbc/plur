import 'package:flutter/material.dart';

import '../util/router_util.dart';
import '../util/theme_util.dart';

class Appbar4Stack extends StatefulWidget {
  static double height = 46;

  final Widget? title;

  final Color? textColor;

  final Color? backgroundColor;

  final Widget? action;
  
  /// List of action widgets to display on the right side of the app bar
  final List<Widget>? actions;

  const Appbar4Stack({
    super.key, 
    this.title,
    this.textColor,
    this.backgroundColor,
    this.action,
    this.actions,
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

    // Handle actions - either a single action or a list of actions
    if (widget.actions != null && widget.actions!.isNotEmpty) {
      // Add multiple actions as a row
      list.add(Row(
        mainAxisSize: MainAxisSize.min,
        children: widget.actions!,
      ));
    } else if (widget.action != null) {
      // For backward compatibility - single action
      list.add(Container(
        child: widget.action,
      ));
    } else {
      // No actions - add empty space
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
