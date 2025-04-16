import 'dart:developer';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';

import '../../consts/base.dart';
import '../../generated/l10n.dart';

class ZapGoalInputController {
  TextEditingController goalAmountController = TextEditingController();

  void clear() {
    goalAmountController.clear();
  }

  List<List<dynamic>> getTags() {
    List<List<dynamic>> tags = [];
    if (StringUtil.isNotBlank(goalAmountController.text)) {
      tags.add(["amount", goalAmountController.text]);
    }

    return tags;
  }

  bool checkInput(BuildContext context) {
    log("goal input called");
    final localization = S.of(context);
    if (StringUtil.isBlank(goalAmountController.text)) {
      log("checked input is blank!");
      BotToast.showText(text: localization.inputCanNotBeNull);
      return false;
    }
    if (StringUtil.isNotBlank(goalAmountController.text)) {
      var num = int.tryParse(goalAmountController.text);
      if (num == null) {
        BotToast.showText(text: localization.numberParseError);
        return false;
      }
    }

    return true;
  }
}

class ZapGoalInputWidget extends StatefulWidget {
  final ZapGoalInputController zapGoalInputController;

  const ZapGoalInputWidget({super.key, required this.zapGoalInputController});

  @override
  State<StatefulWidget> createState() {
    return _ZapGoalInputWidgetState();
  }
}

class _ZapGoalInputWidgetState extends State<ZapGoalInputWidget> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final localization = S.of(context);
    List<Widget> list = [];

    Widget inputWidget = TextField(
      controller: widget.zapGoalInputController.goalAmountController,
      decoration: InputDecoration(
        hintText: localization.goalAmountInSats,
      ),
    );

    list.add(Container(
      child: inputWidget,
    ));

    return Container(
      padding: const EdgeInsets.only(
        left: Base.basePadding,
        right: Base.basePadding,
        bottom: Base.basePadding,
      ),
      width: double.maxFinite,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: list,
      ),
    );
  }
}
