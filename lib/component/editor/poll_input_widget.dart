import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:nostrmo/nostr_sdk/nostr_sdk.dart';

import '../../consts/base.dart';
import '../../generated/l10n.dart';

class PollInputController {
  TextEditingController minValueController = TextEditingController();
  TextEditingController maxValueController = TextEditingController();
  List<TextEditingController> pollOptionControllers = [];

  void clear() {
    minValueController.clear();
    maxValueController.clear();
    pollOptionControllers = [];
  }

  List<List<dynamic>> getTags() {
    List<List<dynamic>> tags = [];
    var length = pollOptionControllers.length;
    for (var i = 0; i < length; i++) {
      var pollPotion = pollOptionControllers[i];
      tags.add(["poll_option", "$i", pollPotion.text]);
    }
    if (StringUtil.isNotBlank(maxValueController.text)) {
      tags.add(["value_maximum", maxValueController.text]);
    }
    if (StringUtil.isNotBlank(minValueController.text)) {
      tags.add(["value_minimum", minValueController.text]);
    }

    return tags;
  }

  bool checkInput(BuildContext context) {
    final localization = S.of(context);
    if (StringUtil.isNotBlank(maxValueController.text)) {
      var num = int.tryParse(maxValueController.text);
      if (num == null) {
        BotToast.showText(text: localization.Number_parse_error);
        return false;
      }
    }
    if (StringUtil.isNotBlank(minValueController.text)) {
      var num = int.tryParse(minValueController.text);
      if (num == null) {
        BotToast.showText(text: localization.Number_parse_error);
        return false;
      }
    }

    for (var pollOptionController in pollOptionControllers) {
      if (StringUtil.isBlank(pollOptionController.text)) {
        BotToast.showText(text: localization.Input_can_not_be_null);
        return false;
      }
    }

    return true;
  }
}

class PollInputWidget extends StatefulWidget {
  PollInputController pollInputController;

  PollInputWidget({super.key, required this.pollInputController});

  @override
  State<StatefulWidget> createState() {
    return _PollInputWidgetState();
  }
}

class _PollInputWidgetState extends State<PollInputWidget> {
  @override
  void initState() {
    super.initState();

    widget.pollInputController.pollOptionControllers
        .add(TextEditingController());
    widget.pollInputController.pollOptionControllers
        .add(TextEditingController());
  }

  @override
  Widget build(BuildContext context) {
    final localization = S.of(context);
    final themeData = Theme.of(context);
    var mainColor = themeData.primaryColor;
    List<Widget> list = [];

    bool delAble = false;
    if (widget.pollInputController.pollOptionControllers.length > 2) {
      delAble = true;
    }

    for (var controller in widget.pollInputController.pollOptionControllers) {
      Widget inputWidget = TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: localization.poll_option_info,
        ),
      );
      if (delAble) {
        inputWidget = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(child: inputWidget),
            IconButton(
                onPressed: () {
                  delPollOption(controller);
                },
                icon: const Icon(Icons.delete)),
          ],
        );
      }

      list.add(Container(
        child: inputWidget,
      ));
    }

    list.add(Container(
      margin: const EdgeInsets.only(top: Base.basePadding),
      child: InkWell(
        onTap: addPollOption,
        child: Container(
          height: 36,
          color: mainColor,
          alignment: Alignment.center,
          child: Text(
            localization.add_poll_option,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    ));

    list.add(Row(
      children: [
        Expanded(
            child: TextField(
          controller: widget.pollInputController.minValueController,
          decoration: InputDecoration(
            hintText: localization.min_zap_num,
          ),
          keyboardType: TextInputType.number,
        )),
        Container(
          width: Base.basePadding,
        ),
        Expanded(
            child: TextField(
          controller: widget.pollInputController.maxValueController,
          decoration: InputDecoration(
            hintText: localization.max_zap_num,
          ),
          keyboardType: TextInputType.number,
        )),
      ],
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

  void addPollOption() {
    widget.pollInputController.pollOptionControllers
        .add(TextEditingController());
    setState(() {});
  }

  void delPollOption(TextEditingController controller) {
    widget.pollInputController.pollOptionControllers.remove(controller);
    setState(() {});
  }
}
