import 'package:flutter/material.dart';

class ZapSplitIconWidget extends StatelessWidget {
  final double fontSize;

  final Color? color;

  const ZapSplitIconWidget(this.fontSize, {super.key, this.color = Colors.orange});

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final theColor = color ?? themeData.iconTheme.color;

    List<Widget> list = [];
    list.add(Positioned(
      left: 0,
      child: Icon(
        Icons.bolt,
        size: fontSize + 2,
        color: theColor,
      ),
    ));
    list.add(Positioned(
      right: 2,
      top: 1,
      child: Text(
        ">",
        style: TextStyle(
          fontSize: fontSize - 2,
          fontWeight: FontWeight.bold,
          color: theColor,
        ),
      ),
    ));

    return SizedBox(
      width: fontSize + 8,
      height: fontSize + 8,
      child: Stack(
        alignment: Alignment.center,
        children: list,
      ),
    );
  }
}
