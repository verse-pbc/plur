import 'package:flutter/material.dart';

import '../../consts/base.dart';
import '../../generated/l10n.dart';
import '../../util/router_util.dart';

class TextInputDialogInnerWidget extends StatefulWidget {
  String title;

  String? hintText;

  String? value;

  bool Function(BuildContext, String)? valueCheck;

  TextInputDialogInnerWidget(
    this.title, {super.key, 
    this.hintText,
    this.value,
    this.valueCheck,
  });

  @override
  State<StatefulWidget> createState() {
    return _TextInputDialogInnerWidgetState();
  }
}

class _TextInputDialogInnerWidgetState
    extends State<TextInputDialogInnerWidget> {
  late TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.value);
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    Color cardColor = themeData.cardColor;
    var mainColor = themeData.primaryColor;
    var titleFontSize = themeData.textTheme.bodyLarge!.fontSize;

    List<Widget> list = [];

    list.add(Container(
      margin: const EdgeInsets.only(bottom: Base.BASE_PADDING),
      child: Text(
        widget.title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: titleFontSize,
        ),
      ),
    ));

    list.add(TextField(
      controller: controller,
      minLines: 4,
      maxLines: 4,
      autofocus: true,
      decoration: InputDecoration(
        hintText: widget.hintText,
        border: const OutlineInputBorder(borderSide: BorderSide(width: 1)),
      ),
    ));

    list.add(Container(
      margin: const EdgeInsets.only(top: Base.BASE_PADDING),
      child: Ink(
        decoration: BoxDecoration(color: mainColor),
        child: InkWell(
          onTap: _onConfirm,
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

    var main = Container(
      padding: const EdgeInsets.all(Base.BASE_PADDING),
      decoration: BoxDecoration(
        color: cardColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: list,
      ),
    );

    return main;
  }

  void _onConfirm() {
    var value = controller.text;
    // if (StringUtil.isBlank(value)) {
    //   BotToast.showText(text: "Input can't be null");
    //   return;
    // }

    if (widget.valueCheck != null) {
      if (!widget.valueCheck!(context, value)) {
        return;
      }
    }
    return RouterUtil.back(context, value);
  }
}
