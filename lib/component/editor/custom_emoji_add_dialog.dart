import 'dart:developer';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/data/custom_emoji.dart';

import '../../consts/base.dart';
import '../../generated/l10n.dart';
import '../../main.dart';
import '../../provider/uploader.dart';
import '../../util/router_util.dart';
import '../../util/theme_util.dart';
import '../content/content_custom_emoji_widget.dart';

class CustomEmojiAddDialog extends StatefulWidget {
  const CustomEmojiAddDialog({super.key});

  @override
  State<StatefulWidget> createState() {
    return _CustomEmojiAddDialog();
  }

  static Future<CustomEmoji?> show(BuildContext context) async {
    return await showDialog<CustomEmoji>(
      context: context,
      useRootNavigator: false,
      builder: (context) {
        return const CustomEmojiAddDialog();
      },
    );
  }
}

class _CustomEmojiAddDialog extends State<CustomEmojiAddDialog> {
  late TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    final localization = S.of(context);
    final themeData = Theme.of(context);
    Color cardColor = themeData.cardColor;
    var mainColor = themeData.primaryColor;
    var titleFontSize = themeData.textTheme.bodyLarge!.fontSize;

    List<Widget> list = [];

    list.add(Container(
      margin: const EdgeInsets.only(bottom: Base.basePadding),
      child: Text(
        localization.Add_Custom_Emoji,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: titleFontSize,
        ),
      ),
    ));

    list.add(Container(
      margin: const EdgeInsets.only(bottom: Base.basePadding),
      child: TextField(
        controller: controller,
        minLines: 1,
        maxLines: 1,
        autofocus: true,
        decoration: InputDecoration(
          hintText: localization.Input_Custom_Emoji_Name,
          border: const OutlineInputBorder(borderSide: BorderSide(width: 1)),
        ),
      ),
    ));

    List<Widget> imageWidgetList = [
      GestureDetector(
        onTap: pickPicture,
        child: const Icon(Icons.image),
      )
    ];
    if (StringUtil.isNotBlank(filepath)) {
      imageWidgetList.add(ContentCustomEmojiWidget(imagePath: filepath!));
    }

    list.add(Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: imageWidgetList,
    ));

    list.add(Container(
      margin: const EdgeInsets.only(
        top: Base.basePadding,
        bottom: 6,
      ),
      child: Ink(
        decoration: BoxDecoration(color: mainColor),
        child: InkWell(
          onTap: () {
            _onConfirm();
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

    var main = Container(
      padding: const EdgeInsets.all(Base.basePadding),
      decoration: BoxDecoration(
        color: cardColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
            // height: double.infinity,
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

  Future<void> pickPicture() async {
    filepath = await Uploader.pick(context);
    setState(() {});
  }

  static const _regExp = r"^[ZA-ZZa-z0-9_]+$";

  String? filepath;

  Future<void> _onConfirm() async {
    final localization = S.of(context);
    var text = controller.text;
    if (StringUtil.isBlank(text)) {
      BotToast.showText(text: localization.Input_can_not_be_null);
      return;
    }

    if (RegExp(_regExp).firstMatch(text) == null) {
      BotToast.showText(text: localization.Input_parse_error);
      return;
    }

    var cancel = BotToast.showLoading();
    try {
      var imagePath = await Uploader.upload(
        filepath!,
        imageService: settingsProvider.imageService,
      );
      log("$text $imagePath");

      if (StringUtil.isBlank(imagePath)) {
        BotToast.showText(text: localization.Upload_fail);
        return;
      }

      filepath = imagePath;
    } finally {
      cancel.call();
    }

    if (!mounted) return;
    RouterUtil.back(context, CustomEmoji(name: text, filepath: filepath));
  }
}
