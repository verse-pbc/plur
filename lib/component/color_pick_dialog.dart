import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../consts/base.dart';
import '../generated/l10n.dart';
import '../util/router_util.dart';
import '../util/theme_util.dart';

class ColorPickDialog extends StatefulWidget {
  final Color? defaultColor;

  const ColorPickDialog(this.defaultColor, {super.key});
  
  @override
  State<ColorPickDialog> createState() => _ColorPickDialogState();

  static Future<Color?> show(BuildContext context, Color? color) async {
    return await showDialog<Color>(
      context: context,
      useRootNavigator: false,
      builder: (context) {
        return ColorPickDialog(color);
      },
    );
  }

}

class _ColorPickDialogState extends State<ColorPickDialog> {
  Color? selectedColor;
  
  void onColorChanged(Color color) {
    selectedColor = color;
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    var mainColor = themeData.primaryColor;

    List<Widget> list = [];
    list.add(HueRingPicker(
      pickerColor: widget.defaultColor != null ? widget.defaultColor! : Colors.black,
      onColorChanged: onColorChanged,
      enableAlpha: true,
      displayThumbColor: false,
    ));

    list.add(Container(
      margin: const EdgeInsets.only(
        top: Base.basePadding,
      ),
      child: Ink(
        decoration: BoxDecoration(color: mainColor),
        child: InkWell(
          onTap: () {
            RouterUtil.back(context, selectedColor);
          },
          highlightColor: mainColor.withOpacity(0.2),
          child: Container(
            color: mainColor,
            height: 40,
            alignment: Alignment.center,
            child: Text(
              S.of(context).Confirm,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    ));

    Widget main = Container(
      color: themeData.cardColor,
      padding: const EdgeInsets.all(Base.basePadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: list,
      ),
    );

    return Scaffold(
      backgroundColor: ThemeUtil.getDialogCoverColor(themeData),
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
