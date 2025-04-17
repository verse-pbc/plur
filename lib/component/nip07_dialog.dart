import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/main.dart';

import '../consts/base.dart';
import '../generated/l10n.dart';
import '../util/router_util.dart';
import '../util/theme_util.dart';

class NIP07Dialog extends StatefulWidget {
  final String method;

  final String? content;

  const NIP07Dialog({super.key,
    required this.method,
    this.content,
  });

  static Future<bool?> show(BuildContext context, String method,
      {String? content}) async {
    return await showDialog<bool>(
      context: context,
      useRootNavigator: false,
      builder: (context) {
        return NIP07Dialog(
          method: method,
          content: content,
        );
      },
    );
  }

  @override
  State<StatefulWidget> createState() {
    return _NIP07Dialog();
  }
}

class _NIP07Dialog extends State<NIP07Dialog> {
  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    var titleFontSize = themeData.textTheme.bodyLarge!.fontSize;
    Color cardColor = themeData.cardColor;
    var hintColor = themeData.hintColor;

    final localization = S.of(context);

    List<Widget> list = [];
    list.add(Text(
      "NIP-07 ${localization.confirm}",
      style: TextStyle(
        fontSize: titleFontSize! + 4,
        fontWeight: FontWeight.bold,
      ),
    ));

    list.add(const Divider());

    list.add(Container(
      margin: const EdgeInsets.only(bottom: Base.basePaddingHalf),
      child: Row(
        children: [
          Text("${localization.method}:  "),
          Text(widget.method),
        ],
      ),
    ));

    String methodDesc = localization.nip07GetPublicKey;
    if (widget.method == NIP07Methods.getRelays) {
      methodDesc = localization.nip07GetRelays;
    } else if (widget.method == NIP07Methods.nip04Encrypt) {
      methodDesc = localization.nip07Encrypt;
    } else if (widget.method == NIP07Methods.nip04Decrypt) {
      methodDesc = localization.nip07Decrypt;
    } else if (widget.method == NIP07Methods.signEvent) {
      methodDesc = localization.nip07SignEvent;
      try {
        if (StringUtil.isNotBlank(widget.content)) {
          var jsonObj = jsonDecode(widget.content!);
          var eventKind = jsonObj["kind"];
          var kindDesc = KindDescriptions.getDes(eventKind);
          methodDesc += ": $kindDesc";
        }
      } catch (_) {}
    } else if (widget.method == NIP07Methods.lightning) {
      methodDesc = localization.nip07Lightning;
    }
    list.add(Container(
      margin: const EdgeInsets.only(bottom: Base.basePaddingHalf),
      child: Row(
        children: [
          Text(methodDesc),
        ],
      ),
    ));

    if (StringUtil.isNotBlank(widget.content)) {
      list.add(Text("${localization.content}:"));
      list.add(Container(
        width: double.maxFinite,
        padding: const EdgeInsets.all(Base.basePaddingHalf),
        decoration: BoxDecoration(
          color: hintColor.withAlpha(76),
          borderRadius: BorderRadius.circular(6),
        ),
        margin: const EdgeInsets.only(
          bottom: Base.basePaddingHalf,
          top: Base.basePaddingHalf,
        ),
        child: SelectableText(widget.content!),
      ));
    }

    list.add(Container(
      margin: const EdgeInsets.only(top: Base.basePaddingHalf),
      child: Row(children: [
        Expanded(
            child: InkWell(
          onTap: () {
            RouterUtil.back(context, false);
          },
          child: Container(
            height: 36,
            color: hintColor.withAlpha(76),
            alignment: Alignment.center,
            child: Text(
              localization.cancel,
              style: TextStyle(
                fontSize: titleFontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        )),
        Container(
          width: Base.basePadding,
        ),
        Expanded(
            child: InkWell(
          onTap: () {
            RouterUtil.back(context, true);
          },
          child: Container(
            height: 36,
            color: hintColor.withAlpha(76),
            alignment: Alignment.center,
            child: Text(
              localization.confirm,
              style: TextStyle(
                fontSize: titleFontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        )),
      ]),
    ));

    var main = Container(
      padding: const EdgeInsets.all(20),
      constraints: BoxConstraints(maxHeight: mediaDataCache.size.height * 0.85),
      decoration: BoxDecoration(
        color: cardColor,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: list,
        ),
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
