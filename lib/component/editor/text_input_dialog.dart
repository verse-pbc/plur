import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';

import '../../consts/base.dart';
import '../../util/router_util.dart';
import '../../util/theme_util.dart';
import 'text_input_dialog_inner_widget.dart';

class TextInputDialog extends StatefulWidget {
  final String title;

  final String? hintText;

  final String? value;

  final bool Function(BuildContext, String)? valueCheck;

  const TextInputDialog(
    this.title, {super.key, 
    this.hintText,
    this.value,
    this.valueCheck,
  });

  @override
  State<StatefulWidget> createState() {
    return _TextInputDialog();
  }

  static Future<String?> show(BuildContext context, String title,
      {String? value,
      String? hintText,
      bool Function(BuildContext, String)? valueCheck}) async {
    return await showDialog<String>(
        context: context,
        useRootNavigator: false,
        builder: (context) {
          return TextInputDialog(
            StringUtil.breakWord(title),
            hintText: hintText,
            value: value,
            valueCheck: valueCheck,
          );
        });
  }
}

class _TextInputDialog extends State<TextInputDialog> {
  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    var main = TextInputDialogInnerWidget(
      widget.title,
      hintText: widget.hintText,
      value: widget.value,
      valueCheck: widget.valueCheck,
    );

    return Scaffold(
      backgroundColor: ThemeUtil.getDialogCoverColor(themeData),
      body: FocusScope(
        autofocus: true,
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
