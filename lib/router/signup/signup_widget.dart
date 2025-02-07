import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:nostr_sdk/android_plugin/android_plugin.dart';
import 'package:nostr_sdk/client_utils/keys.dart';
import 'package:nostr_sdk/nip05/nip05_validor.dart';
import 'package:nostr_sdk/nip07/nip07_signer.dart';
import 'package:nostr_sdk/nip19/nip19.dart';
import 'package:nostr_sdk/nip46/nostr_remote_signer_info.dart';
import 'package:nostr_sdk/nip55/android_nostr_signer.dart';
import 'package:nostr_sdk/signer/pubkey_only_nostr_signer.dart';
import 'package:nostr_sdk/utils/platform_util.dart';
import 'package:nostrmo/component/webview_widget.dart';
import 'package:nostrmo/util/router_util.dart';

import '../../consts/base.dart';
import '../../consts/colors.dart';
import '../../generated/l10n.dart';
import '../../main.dart';
import 'package:nostr_sdk/utils/string_util.dart';

import '../../util/table_mode_util.dart';
import '../index/account_manager_widget.dart';

/// A widget that handles user sign-up.
class SignupWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _SignupState();
  }
}

/// The state class for [SignupWidget].
class _SignupState extends State<SignupWidget> {
  /// A boolean variable to track whether the user has accepted the terms.
  ///
  /// Defaults to `false` and can be toggled based on user interaction.
  /// Boolean flag to enable/disable the Copy & Continue button.
  bool _isCopyAndContinueButtonEnabled = false;

  /// A boolean variable to control the visibility of the text field.
  ///
  /// When `true`, the password field content is obscured (hidden).
  /// When `false`, the password field content is visible.
  bool obscureText = true;

  String privateKey = generatePrivateKey();

  late S localization;

  @override
  Widget build(BuildContext context) {
    localization = S.of(context);
    final themeData = Theme.of(context);
    var mainColor = themeData.primaryColor;
    var maxWidth = mediaDataCache.size.width;
    var mainWidth = maxWidth * 0.8;
    if (TableModeUtil.isTableMode()) {
      if (mainWidth > 550) {
        mainWidth = 550;
      }
    }
    
    List<Widget> mainList = [];

    // Adds an expandable empty space to `mainList`, filling available space
    // in a flex container.
    mainList.add(Expanded(flex: 2, child: Container()));

    mainList.add(Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Transform.flip(
          flipX: true,
          child: Transform.rotate(
            angle: 45 * 3.14 / 180,
            child: Icon(
              Icons.key,
              color: Colors.yellow,
              size: 60,
            ),
          ),
        ),
        SizedBox(height: 10),
        Text(
          localization.This_is_the_key_to_your_account,
          style: TextStyle(
            color: ColorList.primaryForeground,
            fontSize: 31.26,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.8,
            height: kTextHeightNone,
          ),
        )
      ],
    ));

    mainList.add(SizedBox(height: 40));

    mainList.add(Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: ColorList.dimmed,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: EdgeInsets.only(left: 16, top: 16, right: 16, bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              obscureText ? "*" * privateKey.length : privateKey,
              style: TextStyle(
                fontFamily: "monospace",
                fontFamilyFallback: ["Courier"],
                fontSize: 15.93,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.182,
                color: ColorList.dimmed,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  obscureText = !obscureText;
                });
              },
              icon: Icon(
                obscureText ? Icons.visibility : Icons.visibility_off,
                color: ColorList.dimmed,
              ),
              label: Text(
                "view key",
                style: TextStyle(
                  color: ColorList.dimmed,
                  fontSize: 15.93,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.182,
                ),
              ),
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
            ),
          ],
        ),
      ),
    ));

    // Adds an expandable empty space to `mainList`, filling available space
    // in a flex container.
    mainList.add(Expanded(flex: 2, child: Container()));

    mainList.add(
      ListTileTheme(
        data: const ListTileThemeData(
          titleAlignment: ListTileTitleAlignment.top,
          contentPadding: EdgeInsets.symmetric(horizontal: 0),
        ),
        child: CheckboxListTile(
          title: Text(
            localization.I_understand_I_shouldnt_share_this_key,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: ColorList.primaryForeground,
              letterSpacing: 0.7,
              height: kTextHeightNone,
            ),
          ),
          value: _isCopyAndContinueButtonEnabled,
          onChanged: (bool? value) {
            setState(() {
              _isCopyAndContinueButtonEnabled = value!;
            });
          },
          activeColor: ColorList.accent,
          side: BorderSide(color: ColorList.dimmed, width: 2),
          controlAffinity: ListTileControlAffinity.leading,
          dense: true,
          visualDensity: VisualDensity.compact,
        ),
      ),
    );

    // Adds a full-width "Copy & Continue" button to `mainList`.
    mainList.add(SizedBox(
      width: double.infinity,
      child: FilledButton(
        // Calls the `_doSignup` function when enabled; otherwise, it remains
        // disabled.
        onPressed: _isCopyAndContinueButtonEnabled ? _doSignup : null,
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          backgroundColor: ColorList.accent,
          disabledBackgroundColor: ColorList.accent.withOpacity(0.4),
          foregroundColor: ColorList.buttonText,
          disabledForegroundColor: ColorList.buttonText.withOpacity(0.4),
        ),
        child: Text(
          localization.Copy_and_Continue,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ));

    // Adds an expandable empty space to `mainList`, filling available space
    // in a flex container.
    mainList.add(Expanded(flex: 1, child: Container()));

    return Scaffold(
      // Sets the background color for the login screen.
      backgroundColor: ColorList.loginBG,
      body: SizedBox(
        // Expands to the full width of the screen.
        width: double.maxFinite,
        // Expands to the full height of the screen.
        height: double.maxFinite,
        // Uses a `Stack` to position elements, centering them within the
        // available space.
        child: Stack(
          alignment: AlignmentDirectional.center,
          children: [
            SizedBox(
              // A `SizedBox` that constrains the width of the content.
              width: mainWidth,
              // Adds padding to the content to ensure spacing on the sides.
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Base.BASE_PADDING * 2,
                ),
                // Column that holds the main content of the screen.
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: mainList,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _doSignup() async {
    if (Nip19.isPrivateKey(privateKey)) {
      privateKey = Nip19.decode(privateKey);
    }

    try {
      getPublicKey(privateKey);
    } catch (e) {
      // is not a private key
      BotToast.showText(text: S.of(context).Wrong_Private_Key_format);
      return;
    } 

    RouterUtil.back(context, privateKey);
  }
}
