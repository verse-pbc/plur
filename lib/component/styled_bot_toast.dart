import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:nostrmo/util/theme_util.dart';

/// Styled toast widget that uses BotToast to show a toast message.
class StyledBotToast {
  static void show(BuildContext context, {required String text}) {
    if (context is StatefulElement && !context.state.mounted) return;
    final themeData = Theme.of(context).customColors;

    void showToast() {
      BotToast.showText(
        text: text,
        contentColor: themeData.secondaryForegroundColor,
        textStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
        ),
        borderRadius: BorderRadius.circular(8),
        duration: const Duration(seconds: 2),
      );
    }

    showToast();
  }
}
