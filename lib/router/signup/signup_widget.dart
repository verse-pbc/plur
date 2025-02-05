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
  bool? checkTerms = false;

  /// A boolean variable to control the visibility of the text field.
  ///
  /// When `true`, the password field content is obscured (hidden).
  /// When `false`, the password field content is visible.
  bool obscureText = true;

  String privateKey = generatePrivateKey();

  TextEditingController controller = TextEditingController();

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

    generatePK();

    List<Widget> mainList = [];

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
              size: 48,
              semanticLabel: 'Text to announce in accessibility modes',
            ),
          ),
        ),
        Text(
          "Communities",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        )
      ],
    ));
    mainList.add(Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: ColorList.dimmed,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              obscureText ? "*" * privateKey.length : privateKey,
              style: TextStyle(
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
              icon: Icon(obscureText ? Icons.visibility : Icons.visibility_off),
              label: const Text(
                "view key",
                style: TextStyle(
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
    mainList.add(Container(
      margin: const EdgeInsets.all(Base.BASE_PADDING * 2),
      child: InkWell(
        onTap: doLogin,
        child: Container(
          height: 36,
          color: mainColor,
          alignment: Alignment.center,
          child: Text(
            localization.Login,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    ));

    mainList.add(Container(
      margin: const EdgeInsets.only(bottom: 25),
      child: InkWell(
        onTap: generatePK,
        child: Container(
          height: 36,
          alignment: Alignment.center,
          child: Text(
            "Sign Up",
            style: TextStyle(
              color: mainColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    ));

    var termsWiget = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
            value: checkTerms,
            onChanged: (val) {
              setState(() {
                checkTerms = val;
              });
            }),
        Text("${localization.I_accept_the} "),
        GestureDetector(
          onTap: () {
            WebViewWidget.open(context, Base.PRIVACY_LINK);
          },
          child: Text(
            "terms of service",
            style: TextStyle(
              color: mainColor,
              decoration: TextDecoration.underline,
              decorationColor: mainColor,
            ),
          ),
        ),
      ],
    );

    return Scaffold(
      body: SizedBox(
        width: double.maxFinite,
        height: double.maxFinite,
        child: Stack(
          alignment: AlignmentDirectional.center,
          children: [
            SizedBox(
              width: mainWidth,
              // color: Colors.red,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: mainList,
              ),
            ),
            Positioned(
              bottom: 20,
              child: termsWiget,
            ),
          ],
        ),
      ),
    );
  }

  void generatePK() {
    var pk = generatePrivateKey();
    controller.text = pk;

    // mark newUser and will show follow suggest after login.
    newUser = true;
  }

  Future<void> doLogin() async {
    if (checkTerms != true) {
      BotToast.showText(text: S.of(context).Please_accept_the_terms);
      return;
    }

    var pk = controller.text;
    if (StringUtil.isBlank(pk)) {
      BotToast.showText(text: S.of(context).Input_can_not_be_null);
      return;
    }

    if (Nip19.isPrivateKey(pk)) {
      pk = Nip19.decode(pk);
    }

    try {
      getPublicKey(pk);
    } catch (e) {
      // is not a private key
      BotToast.showText(text: S.of(context).Wrong_Private_Key_format);
      return;
    }

    doPreLogin();

    settingProvider.addAndChangePrivateKey(pk, updateUI: false);
    nostr = await relayProvider.genNostrWithKey(pk);

    settingProvider.notifyListeners();
    firstLogin = true;
    indexProvider.setCurrentTap(0);
  }

  void doPreLogin() {}
}
