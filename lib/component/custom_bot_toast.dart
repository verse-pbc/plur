import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:nostrmo/util/theme_util.dart';

/// Customized toast widget that uses BotToast to show a toast message.
class CustomBotToast {
  static void show(BuildContext context, {required String text}) {
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

    if (context is StatefulElement && !context.state.mounted) return;
    showToast();
  }
}
