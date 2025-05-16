import 'dart:developer';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/component/webview_widget.dart';
import 'package:nostrmo/data/join_group_parameters.dart';
import 'package:nostrmo/util/router_util.dart';
// Sentry has been removed
import 'package:styled_text/styled_text.dart';

import '../../consts/base.dart';
import '../../consts/router_path.dart';
import '../../generated/l10n.dart';
import '../../main.dart';
import '../../util/table_mode_util.dart';
import '../index/account_manager_widget.dart';
import '../../component/styled_bot_toast.dart';
import '../../theme/app_colors.dart';

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
  
  /// Auto-joins the test group for new users when running in local/development environment
  // This method was previously auto-joining users to a test group
  // We've disabled it to avoid confusing new users with automatic navigation
  void _joinTestGroupIfDev() {
    // Disabled automatic test group joining
    // Users can explicitly join groups through the UI if desired
  }

  /// Boolean flag to enable/disable the Login button.
  bool _isLoginButtonEnabled = false;

  bool existAndroidNostrSigner = false;

  bool existWebNostrSigner = false;

  bool backAfterLogin = false;

  // Added to track if we're showing the login form
  bool _showingLoginForm = false;

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
    final colors = context.colors;
    final dimmedColor = colors.dimmed;
    final buttonTextColor = colors.buttonText;
    final accentColor = colors.accent;
    final primaryForegroundColor = colors.primaryText;

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

    // Top spacing
    mainList.add(Expanded(flex: 1, child: Container()));

    // Main title
    mainList.add(Container(
      margin: const EdgeInsets.only(bottom: 40),
      child: Text(
        "Bring your people together",
        style: TextStyle(
          color: buttonTextColor,
          fontSize: 48,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
        textAlign: TextAlign.center,
      ),
    ));

    // Subtitle message
    mainList.add(Container(
      margin: const EdgeInsets.only(bottom: 80),
      child: Text(
        "Start meaningful exchanges with people you trust. Holis is communities built for depth, not noise.",
        style: TextStyle(
          color: colors.secondaryText,
          fontSize: 18,
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),
        textAlign: TextAlign.center,
      ),
    ));

    if (!_showingLoginForm) {
      // Show main landing page with two options
      
      // Create a Profile button (primary action)
      mainList.add(SizedBox(
        width: double.infinity,
        child: GestureDetector(
          onTap: _navigateToSignup,
          child: Container(
            key: const Key('signup_button'),
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(32),
            ),
            alignment: Alignment.center,
            child: Text(
              "Create a Profile",
              style: GoogleFonts.nunito(
                textStyle: TextStyle(
                  color: buttonTextColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ),
      ));

      mainList.add(const SizedBox(height: 16));

      // Login with Bluesky button (secondary action) 
      mainList.add(SizedBox(
        width: double.infinity,
        child: GestureDetector(
          onTap: () {
            setState(() {
              _showingLoginForm = true;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: buttonTextColor.withAlpha((255 * 0.3).round()),
                width: 2,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              "Login with Bluesky",
              style: GoogleFonts.nunito(
                textStyle: TextStyle(
                  color: buttonTextColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ),
      ));
    } else {
      // Show login form
      
      // Back button
      mainList.add(Container(
        alignment: Alignment.centerLeft,
        margin: const EdgeInsets.only(bottom: 20),
        child: TextButton.icon(
          onPressed: () {
            setState(() {
              _showingLoginForm = false;
              _controller.clear();
            });
          },
          icon: Icon(Icons.arrow_back, color: primaryForegroundColor),
          label: Text(
            "Back",
            style: TextStyle(
              color: primaryForegroundColor,
              fontSize: 16,
            ),
          ),
        ),
      ));

      // Login form title
      mainList.add(Container(
        alignment: Alignment.centerLeft,
        margin: const EdgeInsets.only(bottom: 10),
        child: Text(
          "Login with Existing Account",
          style: TextStyle(
            color: primaryForegroundColor,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ));
      
      // Login options explainer
      mainList.add(Container(
        alignment: Alignment.centerLeft,
        margin: const EdgeInsets.only(bottom: 20),
        child: Text(
          "Enter your nsec private key or nsecBunker URL. For identities like user@nsec.app, you must set up a bunker URL in your NIP-05 metadata. Read-only access is not supported.",
          style: TextStyle(
            // Using primaryForegroundColor with opacity instead of dimmedColor for better readability
            color: primaryForegroundColor.withAlpha((255 * 0.8).round()),
            fontSize: 14,
          ),
        ),
      ));

      // Private key input field
      OutlineInputBorder textFieldBorder = OutlineInputBorder(
        borderSide: BorderSide(color: primaryForegroundColor.withAlpha((255 * 0.4).round())),
      );
      
      mainList.add(TextField(
        controller: _controller,
        decoration: InputDecoration(
          focusedBorder: textFieldBorder,
          enabledBorder: textFieldBorder,
          hintText: "nsec... / bunker:// URL / user@domain",
          hintStyle: TextStyle(color: primaryForegroundColor.withAlpha((255 * 0.5).round()), fontSize: 16),
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          // Adds an eye icon as a suffix to toggle password visibility
          suffixIcon: GestureDetector(
            onTap: () {
              setState(() {
                _isTextObscured = !_isTextObscured;
              });
            },
            child: Icon(
              _isTextObscured ? Icons.visibility : Icons.visibility_off,
              color: primaryForegroundColor.withAlpha((255 * 0.7).round()),
            ),
          ),
        ),
        style: TextStyle(
          color: primaryForegroundColor,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        obscureText: _isTextObscured,
      ));

      // Login button
      mainList.add(Container(
        margin: const EdgeInsets.only(top: 20, bottom: 20),
        width: double.infinity,
        child: FilledButton(
          onPressed: _isLoginButtonEnabled ? _doLogin : null,
          style: FilledButton.styleFrom(
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            backgroundColor: accentColor,
            disabledBackgroundColor: accentColor.withAlpha((255 * 0.4).round()),
            foregroundColor: buttonTextColor,
            disabledForegroundColor: buttonTextColor.withAlpha((255 * 0.4).round()),
          ),
          child: const Text(
            "Login to Account",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ));

      // External signer options
      if (PlatformUtil.isAndroid() && existAndroidNostrSigner) {
        mainList.add(Container(
          margin: const EdgeInsets.only(bottom: 10),
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _loginByAndroidSigner,
            style: OutlinedButton.styleFrom(
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              side: BorderSide(color: dimmedColor),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text(
              localization.loginWithAndroidSigner,
              style: TextStyle(
                color: primaryForegroundColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ));
      } else if (PlatformUtil.isWeb() && existWebNostrSigner) {
        mainList.add(Container(
          margin: const EdgeInsets.only(bottom: 10),
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _loginWithWebSigner,
            style: OutlinedButton.styleFrom(
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              side: BorderSide(color: dimmedColor),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text(
              localization.loginWithNIP07Extension,
              style: TextStyle(
                color: primaryForegroundColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ));
      }
    }

    // Bottom spacing and terms
    mainList.add(Expanded(flex: 1, child: Container()));
    
    // Terms of service
    mainList.add(GestureDetector(
      onTap: () {
        WebViewWidget.open(context, Base.privacyLink);
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 40),
        child: StyledText(
          text: "By continuing, you accept our <accent>Terms of Service</accent>",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.secondaryText,
            fontSize: 16,
            height: 1.5,
          ),
          tags: {
            'accent': StyledTextTag(
              style: TextStyle(
                decoration: TextDecoration.underline,
                decorationColor: accentColor,
                color: accentColor,
              ),
            ),
          },
        ),
      ),
    ));

    return Scaffold(
      // Sets the background color for the login screen.
      backgroundColor: colors.loginBackground,
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
            if (backAfterLogin)
              SafeArea(
                child: Stack(
                  children: [
                    Positioned(
                      top: 4,
                      left: 4,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          textStyle: const TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.w500,
                          ),
                          foregroundColor: accentColor,
                        ),
                        child: Text(localization.cancel),
                      ),
                    ),
                  ],
                ),
              ),
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

  /// Navigates to the Signup screen.
  Future<void> _navigateToSignup() async {
    final userData = await Navigator.of(context).pushNamed(RouterPath.onboarding);
    if (userData != null && userData is Map<String, String>) {
      final privateKey = userData['privateKey'];
      final userName = userData['userName'];
      
      if (privateKey != null && privateKey.isNotEmpty) {
        _doPreLogin();

        // Show loading indicator
        var cancelLoading = BotToast.showLoading();
        
        try {
          // Store the private key and generate Nostr instance
          settingsProvider.addAndChangePrivateKey(privateKey, updateUI: false);
          nostr = await relayProvider.genNostrWithKey(privateKey);
          
          // Set the user's name/nickname in metadata if provided
          if (userName != null && userName.isNotEmpty && nostr != null) {
            try {
              // We'll update the user metadata after login through the userProvider
              // This just stores the name for now
              userProvider.userName = userName;
            } catch (e) {
              // Silently handle any errors
              debugPrint("Error storing initial username: $e");
            }
          }

          if (backAfterLogin && mounted) {
            RouterUtil.back(context);
          }

          // Update UI and mark as first login to properly download contact data
          settingsProvider.notifyListeners();
          firstLogin = true;
          indexProvider.setCurrentTap(0);
          
          // Auto join testing group for dev/local builds
          _joinTestGroupIfDev();
        } catch (e, stackTrace) {
          // Show error message
          StyledBotToast.show(context, text: "Account creation failed: ${e.toString()}");
          log("Login exception: $e\n$stackTrace");
        } finally {
          // Hide loading indicator
          cancelLoading.call();
        }
      }
    }
  }

  /// Asynchronous function to handle login when the button is pressed
  Future<void> _doLogin() async {
    var pk = _controller.text;
    if (pk.isEmpty) {
      if (!mounted) return;
      StyledBotToast.show(context, text: S.of(context).inputCanNotBeNull);
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
          log("Login exception: $exception\n$stackTrace");
        } finally {
          cancelFunc.call();
        }
      }

      if (StringUtil.isBlank(pubkey)) {
        if (!mounted) return;
        StyledBotToast.show(context,
            text: "${localization.pubkey} ${localization.notFound}");
        return;
      }

      // If we have a NIP-05 identifier, try to check if it has a bunker URL
      if (pk.indexOf("@") > 0) {
        // Try to find a bunker URL from NIP-05 metadata
        try {
          // First check if we can find a bunker URL in NIP-05 metadata
          var cancelFunc = BotToast.showLoading();
          try {
            var metadata = await Nip05Validator.getJson(pk);
            if (metadata != null && 
                metadata["bunker"] != null && 
                metadata["bunker"].toString().startsWith("bunker://")) {
              // Found a bunker URL - use it instead!
              String bunkerUrl = metadata["bunker"].toString();
              
              // Use the bunker URL for login
              var info = NostrRemoteSignerInfo.parseBunkerUrl(bunkerUrl);
              if (info != null) {
                var bunkerLink = info.toString();
                _doPreLogin();
                nostr = await relayProvider.genNostrWithKey(bunkerLink);
                if (nostr != null && nostr!.nostrSigner is NostrRemoteSigner) {
                  bunkerLink = (nostr!.nostrSigner as NostrRemoteSigner).info.toString();
                }
                settingsProvider.addAndChangePrivateKey(bunkerLink, updateUI: false);
                
                if (backAfterLogin && mounted) {
                  RouterUtil.back(context);
                }
                
                settingsProvider.notifyListeners();
                firstLogin = true;
                indexProvider.setCurrentTap(0);
                return;
              }
            }
          } catch (e) {
            // Failed to get metadata, will fall back to read-only mode
          } finally {
            cancelFunc.call();
          }
        } catch (e) {
          // Ignore any errors in this extra check
        }
        
        // If we reach here, nsec.app or similar didn't provide a private key or bunker URL
        if (!mounted) return;
        StyledBotToast.show(context,
            text: "Login failed: Read-only mode is not supported. Please use your nsec private key or a nsecBunker URL. For identities like user@nsec.app, make sure you have a bunker URL set in your NIP-05 metadata.");
        return;
      }

      // Don't allow read-only accounts
      if (!mounted) return;
      StyledBotToast.show(context,
          text: "Login failed: Read-only mode is not supported. Please use your nsec private key or a nsecBunker URL. For identities like user@nsec.app, make sure you have a bunker URL set in your NIP-05 metadata.");
      return;
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
        settingsProvider.addAndChangePrivateKey(bunkerLink, updateUI: false);
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
            text: S.of(context).wrongPrivateKeyFormat);
        return;
      }

      _doPreLogin();

      settingsProvider.addAndChangePrivateKey(pk, updateUI: false);
      nostr = await relayProvider.genNostrWithKey(pk);
    }

    if (backAfterLogin && mounted) {
      RouterUtil.back(context);
    }

    settingsProvider.notifyListeners();
    firstLogin = true;
    indexProvider.setCurrentTap(0);
    
    // Auto join testing group for dev/local builds
    _joinTestGroupIfDev();
  }

  Future<void> _loginByAndroidSigner() async {
    var androidNostrSigner = AndroidNostrSigner();
    var pubkey = await androidNostrSigner.getPublicKey();
    if (StringUtil.isBlank(pubkey)) {
      if (!mounted) return;
      StyledBotToast.show(context, text: localization.loginFail);
      return;
    }

    _doPreLogin();

    var key = "${AndroidNostrSigner.uriPre}:$pubkey";
    if (StringUtil.isNotBlank(androidNostrSigner.getPackage())) {
      key = "$key?package=${androidNostrSigner.getPackage()}";
    }
    settingsProvider.addAndChangePrivateKey(key, updateUI: false);
    nostr = await relayProvider.genNostr(androidNostrSigner);

    if (backAfterLogin && mounted) {
      RouterUtil.back(context);
    }

    settingsProvider.notifyListeners();
    firstLogin = true;
    indexProvider.setCurrentTap(0);
    
    // Auto join testing group for dev/local builds
    _joinTestGroupIfDev();
  }

  Future<void> _loginWithWebSigner() async {
    var signer = NIP07Signer();
    var pubkey = await signer.getPublicKey();
    if (StringUtil.isBlank(pubkey)) {
      if (!mounted) return;
      StyledBotToast.show(context, text: localization.loginFail);
      return;
    }

    _doPreLogin();

    var key = "${NIP07Signer.uriPre}:$pubkey";
    settingsProvider.addAndChangePrivateKey(key, updateUI: false);
    nostr = await relayProvider.genNostr(signer);

    if (backAfterLogin && mounted) {
      RouterUtil.back(context);
    }

    settingsProvider.notifyListeners();
    firstLogin = true;
    indexProvider.setCurrentTap(0);
    
    // Auto join testing group for dev/local builds
    _joinTestGroupIfDev();
  }

  void _doPreLogin() {
    if (backAfterLogin) {
      AccountManagerWidgetState.clearCurrentMemInfo();
      nostr!.close();
      nostr = null;
    }
  }
}
