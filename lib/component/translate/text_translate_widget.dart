import 'package:flutter/material.dart';
import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/consts/base_consts.dart';
import 'package:nostrmo/main.dart';

import '../cust_state.dart';

class TextTranslateWidget extends StatefulWidget {
  final String text;

  final Function? textOnTap;

  const TextTranslateWidget(this.text, {super.key, this.textOnTap});

  @override
  State<StatefulWidget> createState() {
    return _TextTranslateWidgetState();
  }
}

class _TextTranslateWidgetState extends CustState<TextTranslateWidget> {
  String? sourceText;

  static const double margin = 4;

  String? targetText;

  TranslateLanguage? sourceLanguage;

  TranslateLanguage? targetLanguage;

  bool showSource = false;

  @override
  Widget doBuild(BuildContext context) {
    if (isInited) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        checkAndTranslate();
      });
    }

    final themeData = Theme.of(context);
    var smallTextSize = themeData.textTheme.bodySmall!.fontSize;
    var fontSize = themeData.textTheme.bodyMedium!.fontSize;
    var iconWidgetWidth = fontSize! + 4;
    var hintColor = themeData.hintColor;

    List<InlineSpan> list = [TextSpan(text: targetText ?? widget.text)];
    if (targetLanguage != null &&
        sourceLanguage != null &&
        targetLanguage != null &&
        targetText != widget.text) {
      if (showSource) {
        list.add(
          WidgetSpan(
              child: Container(
            margin: const EdgeInsets.only(left: margin),
            child: Text(
              "<- ${targetLanguage!.bcpCode}",
              style: TextStyle(
                color: hintColor,
              ),
            ),
          )),
        );
      }

      var iconBtn = WidgetSpan(
        child: GestureDetector(
          onTap: () {
            setState(() {
              showSource = !showSource;
            });
          },
          child: Container(
            margin: const EdgeInsets.only(
              left: margin,
              right: margin,
            ),
            height: iconWidgetWidth,
            width: iconWidgetWidth,
            decoration: BoxDecoration(
              border: Border.all(width: 1, color: hintColor),
              borderRadius: BorderRadius.circular(iconWidgetWidth / 2),
            ),
            child: Icon(
              Icons.translate,
              size: smallTextSize,
              color: hintColor,
            ),
          ),
        ),
      );
      list.add(iconBtn);

      if (showSource) {
        list.add(
          WidgetSpan(
              child: Container(
            margin: const EdgeInsets.only(right: margin),
            child: Text(
              "${sourceLanguage!.bcpCode} ->",
              style: TextStyle(
                color: hintColor,
              ),
            ),
          )),
        );

        list.add(TextSpan(
            text: widget.text,
            style: TextStyle(
              color: hintColor,
            )));
      }
    }
    return SelectableText.rich(
      TextSpan(children: list),
      onTap: () {
        if (widget.textOnTap != null) {
          widget.textOnTap!();
        }
      },
    );
  }

  @override
  Future<void> onReady(BuildContext context) async {
    checkAndTranslate();
  }

  Future<void> checkAndTranslate() async {
    if (widget.text.length > 1000) {
      return;
    }

    if (settingsProvider.openTranslate != OpenStatus.open) {
      // is close
      if (targetText != null) {
        // set targetText to null
        setState(() {
          targetText = null;
        });
      }
      return;
    } else {
      // is open
      // check target
      if (targetText != null) {
        // targetText had bean translated
        if (targetLanguage != null &&
            targetLanguage!.bcpCode == settingsProvider.translateTarget &&
            widget.text == sourceText) {
          // and currentTargetLanguage = settingTranslate
          return;
        }
      }
    }

    var translateTarget = settingsProvider.translateTarget;
    if (StringUtil.isBlank(translateTarget)) {
      return;
    }
    targetLanguage = BCP47Code.fromRawValue(translateTarget!);
    if (targetLanguage == null) {
      return;
    }

    LanguageIdentifier? languageIdentifier;
    OnDeviceTranslator? onDeviceTranslator;

    try {
      languageIdentifier = LanguageIdentifier(confidenceThreshold: 0.5);
      final List<IdentifiedLanguage> possibleLanguages =
          await languageIdentifier.identifyPossibleLanguages(widget.text);

      if (possibleLanguages.isNotEmpty) {
        var pl = possibleLanguages[0];
        if (!settingsProvider.translateSourceArgsCheck(pl.languageTag)) {
          if (targetText != null) {
            // set targetText to null
            setState(() {
              targetText = null;
            });
          }
          return;
        }

        sourceLanguage = BCP47Code.fromRawValue(pl.languageTag);
      }

      if (sourceLanguage != null) {
        onDeviceTranslator = OnDeviceTranslator(
            sourceLanguage: sourceLanguage!, targetLanguage: targetLanguage!);

        var result = await onDeviceTranslator.translateText(widget.text);
        if (StringUtil.isNotBlank(result)) {
          setState(() {
            targetText = result;
            sourceText = widget.text;
          });
        }
      }
    } finally {
      if (languageIdentifier != null) {
        languageIdentifier.close();
      }
      if (onDeviceTranslator != null) {
        onDeviceTranslator.close();
      }
    }
  }
}
