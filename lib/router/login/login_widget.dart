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
import 'package:nostr_sdk/utils/string_util.dart';
import 'package:nostrmo/component/webview_widget.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:styled_text/styled_text.dart';

import '../../consts/base.dart';
import '../../consts/colors.dart';
import '../../generated/l10n.dart';
import '../../main.dart';
import '../../util/table_mode_util.dart';
import '../index/account_manager_widget.dart';

/// A stateful widget that manages the Login (or Landing) screen.
class LoginSignupWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _LoginSignupState();
  }
}

/// Manages the state for the `LoginSignupWidget`.
class _LoginSignupState extends State<LoginSignupWidget> {
  // Boolean flag to show/hide the text in the text field.
  bool _isTextObscured = true;

  /// Controller for the TextField to track text changes.
  TextEditingController _controller = TextEditingController();

  /// Boolean flag to enable/disable the Login button.
  bool _isLoginButtonEnabled = false;

  bool existAndroidNostrSigner = false;

  bool existWebNostrSigner = false;

  bool backAfterLogin = false;

  late S localization;

  @override
  void initState() {
    super.initState();
    if (PlatformUtil.isAndroid()) {
      AndroidPlugin.existAndroidNostrSigner().then((exist) {
        if (exist == true) {
          setState(() {
            existAndroidNostrSigner = true;
          });
        }
      });
    } else if (PlatformUtil.isWeb()) {
      if (NIP07Signer.support()) {
        setState(() {
          existWebNostrSigner = true;
        });
      }
    }
    // Add a listener to track text changes in the TextField.
    _controller.addListener(_updateLoginButtonState);
  }

  /// Updates the state of the button based on the text field's content.
  void _updateLoginButtonState() {
    setState(() {
      _isLoginButtonEnabled = _controller.text.isNotEmpty;
    });
  }

  @override
  void dispose() {
    // Remove the listener to avoid memory leaks.
    _controller.removeListener(_updateLoginButtonState);
    _controller.dispose();
    super.dispose();
  }

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

    var arg = RouterUtil.routerArgs(context);
    if (arg != null && arg is bool) {
      backAfterLogin = arg;
    }

    List<Widget> mainList = [];

    // Adds an expandable empty space to `mainList`, filling available space
    // in a flex container.
    mainList.add(Expanded(child: Container()));

    // Adds a logo image to `mainList` for branding.
    mainList.add(Image.asset(
      "assets/imgs/landing/logo.png",
      width: 162,
      height: 82,
    ));

    // Adds a title text "Communities" inside a `Container` with bottom margin.
    mainList.add(Container(
      margin: const EdgeInsets.only(
        bottom: 40,
      ),
      child: Text(
        localization.Communities,
        style: TextStyle(
          color: ColorList.primaryForeground,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    ));

    // Adds a tappable "Signup" button to `mainList`.
    mainList.add(SizedBox(
      width: double.infinity,
      child: FilledButton(
        // Calls `_generatePK` when tapped.
        onPressed: _generatePK,
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          backgroundColor: ColorList.accent,
        ),
        child: Text(
          localization.Signup,
          style: TextStyle(
            color: ColorList.buttonText,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ));

    // Adds an expandable empty space to `mainList`, filling available space
    // in a flex container.
    mainList.add(Expanded(child: Container()));

    // Define a re-usable text field border to be used in enabled and focused
    // states.
    OutlineInputBorder textFieldBorder = OutlineInputBorder(
      borderSide: BorderSide(color: ColorList.dimmed),
    );

    // Adds a `TextField` to the `mainList`, allowing the user to input a
    // private key securely.
    mainList.add(TextField(
      controller: _controller,
      decoration: InputDecoration(
        focusedBorder: textFieldBorder,
        enabledBorder: textFieldBorder,
        hintText: localization.Your_private_key,
        hintStyle: TextStyle(
          color: ColorList.dimmed,
          fontSize: 16,
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 8),
        // Adds an eye icon as a suffix to toggle password visibility
        suffixIcon: GestureDetector(
          onTap: () {
            setState(() {
              _isTextObscured = !_isTextObscured;
            });
          },
          child: Icon(
            _isTextObscured ? Icons.visibility : Icons.visibility_off,
            color: ColorList.dimmed,
          ),
        ),
      ),
      style: TextStyle(
        color: ColorList.dimmed,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
      obscureText: _isTextObscured,
    ));

    // Adds a 10px tall space between the text field and the button.
    mainList.add(SizedBox(height: 10));

    // Adds a full-width "Login" button to `mainList`.
    mainList.add(SizedBox(
      width: double.infinity,
      child: FilledButton(
        // Calls the `_doLogin` function when enabled; otherwise, it remains
        // disabled.
        onPressed: _isLoginButtonEnabled ? _doLogin : null,
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          backgroundColor: ColorList.dimmed,
          disabledBackgroundColor: ColorList.dimmed.withOpacity(0.4),
          foregroundColor: ColorList.buttonText,
          disabledForegroundColor: ColorList.buttonText.withOpacity(0.4),
        ),
        child: Text(
          localization.Login,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ));

    if (PlatformUtil.isAndroid() && existAndroidNostrSigner) {
      mainList.add(Text(localization.or));
      mainList.add(Container(
        child: InkWell(
          onTap: loginByAndroidSigner,
          child: Container(
            height: 36,
            color: mainColor,
            alignment: Alignment.center,
            child: Text(
              localization.Login_With_Android_Signer,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ));
    } else if (PlatformUtil.isWeb() && existWebNostrSigner) {
      mainList.add(Text(localization.or));
      mainList.add(Container(
        child: InkWell(
          onTap: loginWithWebSigner,
          child: Container(
            height: 36,
            color: mainColor,
            alignment: Alignment.center,
            child: Text(
              localization.Login_With_NIP07_Extension,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ));
    }

    // Adds an expandable section with a centered terms-of-service link to
    // `mainList`.
    mainList.add(Expanded(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        GestureDetector(
          onTap: () {
            WebViewWidget.open(context, Base.PRIVACY_LINK);
          },
          child: StyledText(
              text: localization.Accept_terms_of_service,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ColorList.primaryForeground,
                fontSize: 15,
              ),
              tags: {
                'accent': StyledTextTag(
                  style: TextStyle(
                      decoration: TextDecoration.underline,
                      decorationColor: ColorList.accent,
                      color: ColorList.accent),
                )
              }),
        )
      ]),
    ));

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
                  children: mainList,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  /// Generates a new private key and updates the UI accordingly.
  void _generatePK() {
    // Generates a new private key.
    var pk = generatePrivateKey();
    // Updates the text field with the newly generated private key.
    _controller.text = pk;
    // Marks the user as new, so they will see follow suggestions after login.
    newUser = true;
    // Displays a toast notification informing the user that a new private key
    // was generated.
    BotToast.showText(
      text: "A new private key has been generated for your account.",
    );
  }

  /// Asynchronous function to handle login when the button is pressed
  Future<void> _doLogin() async {
    var pk = _controller.text;
    if (pk.isEmpty) {
      BotToast.showText(text: S.of(context).Input_can_not_be_null);
      return;
    }

    if (Nip19.isPubkey(pk) || pk.indexOf("@") > 0) {
      String? pubkey;
      if (Nip19.isPubkey(pk)) {
        pubkey = Nip19.decode(pk);
      } else if (pk.indexOf("@") > 0) {
        // try to find pubkey first.
        var cancelFunc = BotToast.showLoading();
        try {
          pubkey = await Nip05Validor.getPubkey(pk);
        } catch (e) {
          print("doLogin error ${e.toString()}");
        } finally {
          cancelFunc.call();
        }
      }

      if (StringUtil.isBlank(pubkey)) {
        BotToast.showText(
            text: "${localization.Pubkey} ${localization.not_found}");
        return;
      }

      doPreLogin();

      var npubKey = Nip19.encodePubKey(pubkey!);
      settingProvider.addAndChangePrivateKey(npubKey, updateUI: false);

      var pubkeyOnlySigner = PubkeyOnlyNostrSigner(pubkey);
      nostr = await relayProvider.genNostr(pubkeyOnlySigner);
      BotToast.showText(text: localization.Readonly_login_tip);
    } else if (NostrRemoteSignerInfo.isBunkerUrl(pk)) {
      var cancel = BotToast.showLoading();
      try {
        var info = NostrRemoteSignerInfo.parseBunkerUrl(pk);
        if (info == null) {
          return;
        }

        var bunkerLink = info.toString();
        settingProvider.addAndChangePrivateKey(bunkerLink, updateUI: false);

        nostr = await relayProvider.genNostrWithKey(bunkerLink);
      } finally {
        cancel.call();
      }
    } else {
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
    }

    if (backAfterLogin) {
      RouterUtil.back(context);
    }

    settingProvider.notifyListeners();
    firstLogin = true;
    indexProvider.setCurrentTap(0);
  }

  Future<void> loginByAndroidSigner() async {
    var androidNostrSigner = AndroidNostrSigner();
    var pubkey = await androidNostrSigner.getPublicKey();
    if (StringUtil.isBlank(pubkey)) {
      BotToast.showText(text: localization.Login_fail);
      return;
    }

    doPreLogin();

    var key = "${AndroidNostrSigner.URI_PRE}:$pubkey";
    if (StringUtil.isNotBlank(androidNostrSigner.getPackage())) {
      key = "$key?package=${androidNostrSigner.getPackage()}";
    }
    settingProvider.addAndChangePrivateKey(key, updateUI: false);
    nostr = await relayProvider.genNostr(androidNostrSigner);

    if (backAfterLogin) {
      RouterUtil.back(context);
    }

    settingProvider.notifyListeners();
    firstLogin = true;
    indexProvider.setCurrentTap(0);
  }

  Future<void> loginWithWebSigner() async {
    var signer = NIP07Signer();
    var pubkey = await signer.getPublicKey();
    if (StringUtil.isBlank(pubkey)) {
      BotToast.showText(text: localization.Login_fail);
      return;
    }

    doPreLogin();

    var key = "${NIP07Signer.URI_PRE}:$pubkey";
    settingProvider.addAndChangePrivateKey(key, updateUI: false);
    nostr = await relayProvider.genNostr(signer);

    if (backAfterLogin) {
      RouterUtil.back(context);
    }

    settingProvider.notifyListeners();
    firstLogin = true;
    indexProvider.setCurrentTap(0);
  }

  void doPreLogin() {
    if (backAfterLogin) {
      AccountManagerWidgetState.clearCurrentMemInfo();
      nostr!.close();
      nostr = null;
    }
  }
}
