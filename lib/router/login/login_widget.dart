import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/component/webview_widget.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:styled_text/styled_text.dart';
import 'package:provider/provider.dart';

import '../../consts/base.dart';
import '../../consts/router_path.dart';
import '../../generated/l10n.dart';
import '../../main.dart';
import '../../util/table_mode_util.dart';
import '../index/account_manager_widget.dart';
import '../../component/styled_bot_toast.dart';
import '../../util/theme_util.dart';
import '../../provider/settings_provider.dart';
import '../../provider/relay_provider.dart';
import '../../provider/index_provider.dart';

/// A stateful widget that manages the Login (or Landing) screen.
class LoginSignupWidget extends StatefulWidget {
  /// Creates an instance of [LoginSignupWidget].
  const LoginSignupWidget({super.key});

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
  final TextEditingController _controller = TextEditingController();

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

    // Save some colors for later
    final themeData = Theme.of(context);
    final dimmedColor = themeData.customColors.dimmedColor;
    final buttonTextColor = themeData.customColors.buttonTextColor;

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
          color: themeData.customColors.primaryForegroundColor,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    ));

    // Adds a tappable "Signup" button to `mainList`.
    mainList.add(SizedBox(
      width: double.infinity,
      child: FilledButton(
        key: const Key('signup_button'),
        // Calls `_navigateToSignup` when tapped.
        onPressed: _navigateToOnboarding,
        style: FilledButton.styleFrom(
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          backgroundColor: themeData.customColors.accentColor,
        ),
        child: Text(
          localization.Signup,
          style: TextStyle(
            color: themeData.customColors.buttonTextColor,
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
      borderSide: BorderSide(color: dimmedColor),
    );

    // Adds a `TextField` to the `mainList`, allowing the user to input a
    // private key securely.
    mainList.add(TextField(
      controller: _controller,
      decoration: InputDecoration(
        focusedBorder: textFieldBorder,
        enabledBorder: textFieldBorder,
        hintText: localization.Your_private_key,
        hintStyle: TextStyle(color: dimmedColor, fontSize: 16),
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
        // Adds an eye icon as a suffix to toggle password visibility
        suffixIcon: GestureDetector(
          onTap: () {
            setState(() {
              _isTextObscured = !_isTextObscured;
            });
          },
          child: Icon(
            _isTextObscured ? Icons.visibility : Icons.visibility_off,
            color: dimmedColor,
          ),
        ),
      ),
      style: TextStyle(
        color: dimmedColor,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
      obscureText: _isTextObscured,
    ));

    // Adds a 10px tall space between the text field and the button.
    mainList.add(const SizedBox(height: 10));

    // Adds a full-width "Login" button to `mainList`.
    mainList.add(SizedBox(
      width: double.infinity,
      child: FilledButton(
        // Calls the `_doLogin` function when enabled; otherwise, it remains
        // disabled.
        onPressed: _isLoginButtonEnabled ? _doLogin : null,
        style: FilledButton.styleFrom(
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          backgroundColor: dimmedColor,
          disabledBackgroundColor: dimmedColor.withOpacity(0.4),
          foregroundColor: buttonTextColor,
          disabledForegroundColor: buttonTextColor.withOpacity(0.4),
        ),
        child: Text(
          localization.Login,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ));

    if (PlatformUtil.isAndroid() && existAndroidNostrSigner) {
      mainList.add(SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: _loginByAndroidSigner,
          style: FilledButton.styleFrom(
            shape:
                const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            backgroundColor: themeData.customColors.dimmedColor,
            disabledBackgroundColor:
                themeData.customColors.dimmedColor.withOpacity(0.4),
            foregroundColor: themeData.customColors.buttonTextColor,
            disabledForegroundColor:
                themeData.customColors.buttonTextColor.withOpacity(0.4),
          ),
          child: Text(
            localization.Login_With_Android_Signer,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ));
    } else if (PlatformUtil.isWeb() && existWebNostrSigner) {
      mainList.add(SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: _loginWithWebSigner,
          style: FilledButton.styleFrom(
            shape:
                const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            backgroundColor: themeData.customColors.dimmedColor,
            disabledBackgroundColor:
                themeData.customColors.dimmedColor.withOpacity(0.4),
            foregroundColor: themeData.customColors.buttonTextColor,
            disabledForegroundColor:
                themeData.customColors.buttonTextColor.withOpacity(0.4),
          ),
          child: Text(
            localization.Login_With_NIP07_Extension,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
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
            WebViewWidget.open(context, Base.privacyLink);
          },
          child: StyledText(
              text: localization.Accept_terms_of_service,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: themeData.customColors.primaryForegroundColor,
                fontSize: 15,
              ),
              tags: {
                'accent': StyledTextTag(
                  style: TextStyle(
                      decoration: TextDecoration.underline,
                      decorationColor: themeData.customColors.accentColor,
                      color: themeData.customColors.accentColor),
                )
              }),
        )
      ]),
    ));

    return Scaffold(
      // Sets the background color for the login screen.
      backgroundColor: themeData.customColors.loginBgColor,
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
                  horizontal: Base.basePadding * 2,
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

  /// Navigates to the Onboarding screen.
  Future<void> _navigateToOnboarding() async {
    final completed =
        await Navigator.of(context).pushNamed(RouterPath.onboarding);
    if (completed == true) {
      final privateKey = generatePrivateKey();
      await _completeSignup(privateKey);
    }
  }

  Future<void> _completeSignup(String privateKey) async {
    final settingsProvider =
        Provider.of<SettingsProvider>(context, listen: false);
    final relayProvider = Provider.of<RelayProvider>(context, listen: false);
    final indexProvider = Provider.of<IndexProvider>(context, listen: false);

    // Clear previously selected account data if any
    _doPreLogin();

    // Set up the private key and nostr client
    settingsProvider.addAndChangePrivateKey(privateKey, updateUI: true);
    nostr = await relayProvider.genNostrWithKey(privateKey);

    // Set first login flag and navigate
    firstLogin = true;
    // Set home tab and navigate to index
    if (mounted) {
      indexProvider.setCurrentTap(0); // Set the home tab
      RouterUtil.router(context, RouterPath.INDEX); // Navigate to home page
    }
  }

  /// Asynchronous function to handle login when the button is pressed
  Future<void> _doLogin() async {
    var pk = _controller.text;
    if (pk.isEmpty) {
      if (!mounted) return;
      StyledBotToast.show(context, text: S.of(context).Input_can_not_be_null);
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
          pubkey = await Nip05Validator.getPubkey(pk);
        } catch (exception, stackTrace) {
          await Sentry.captureException(exception, stackTrace: stackTrace);
        } finally {
          cancelFunc.call();
        }
      }

      if (StringUtil.isBlank(pubkey)) {
        if (!mounted) return;
        StyledBotToast.show(context,
            text: "${localization.Pubkey} ${localization.not_found}");
        return;
      }

      _doPreLogin();

      var npubKey = Nip19.encodePubKey(pubkey!);
      settingsProvider.addAndChangePrivateKey(npubKey, updateUI: true);

      var pubkeyOnlySigner = PubkeyOnlyNostrSigner(pubkey);
      nostr = await relayProvider.genNostr(pubkeyOnlySigner);
      if (!mounted) return;
      StyledBotToast.show(context, text: localization.Readonly_login_tip);
    } else if (NostrRemoteSignerInfo.isBunkerUrl(pk)) {
      var cancel = BotToast.showLoading();
      try {
        var info = NostrRemoteSignerInfo.parseBunkerUrl(pk);
        if (info == null) {
          return;
        }

        var bunkerLink = info.toString();

        _doPreLogin();

        nostr = await relayProvider.genNostrWithKey(bunkerLink);
        if (nostr != null && nostr!.nostrSigner is NostrRemoteSigner) {
          bunkerLink =
              (nostr!.nostrSigner as NostrRemoteSigner).info.toString();
        }
        settingsProvider.addAndChangePrivateKey(bunkerLink, updateUI: true);
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
        StyledBotToast.show(context,
            text: S.of(context).Wrong_Private_Key_format);
        return;
      }

      _doPreLogin();

      settingsProvider.addAndChangePrivateKey(pk, updateUI: true);
      nostr = await relayProvider.genNostrWithKey(pk);
    }

    if (backAfterLogin && mounted) {
      RouterUtil.back(context);
    }

    firstLogin = true;
    indexProvider.setCurrentTap(0);
  }

  Future<void> _loginByAndroidSigner() async {
    var androidNostrSigner = AndroidNostrSigner();
    var pubkey = await androidNostrSigner.getPublicKey();
    if (StringUtil.isBlank(pubkey)) {
      if (!mounted) return;
      StyledBotToast.show(context, text: localization.Login_fail);
      return;
    }

    _doPreLogin();

    var key = "${AndroidNostrSigner.URI_PRE}:$pubkey";
    if (StringUtil.isNotBlank(androidNostrSigner.getPackage())) {
      key = "$key?package=${androidNostrSigner.getPackage()}";
    }
    settingsProvider.addAndChangePrivateKey(key, updateUI: true);
    nostr = await relayProvider.genNostr(androidNostrSigner);

    if (backAfterLogin && mounted) {
      RouterUtil.back(context);
    }

    firstLogin = true;
    indexProvider.setCurrentTap(0);
  }

  Future<void> _loginWithWebSigner() async {
    var signer = NIP07Signer();
    var pubkey = await signer.getPublicKey();
    if (StringUtil.isBlank(pubkey)) {
      if (!mounted) return;
      StyledBotToast.show(context, text: localization.Login_fail);
      return;
    }

    _doPreLogin();

    var key = "${NIP07Signer.URI_PRE}:$pubkey";
    settingsProvider.addAndChangePrivateKey(key, updateUI: true);
    nostr = await relayProvider.genNostr(signer);

    if (backAfterLogin && mounted) {
      RouterUtil.back(context);
    }

    firstLogin = true;
    indexProvider.setCurrentTap(0);
  }

  void _doPreLogin() {
    if (backAfterLogin) {
      AccountManagerWidgetState.clearCurrentMemInfo();
      nostr!.close();
      nostr = null;
    }
  }
}
