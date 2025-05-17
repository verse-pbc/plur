import 'dart:developer';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/component/webview_widget.dart';
import 'package:nostrmo/util/router_util.dart';
// Sentry has been removed
import 'package:styled_text/styled_text.dart';

import '../../consts/base.dart';
import '../../consts/router_path.dart';
import '../../generated/l10n.dart';
import '../../main.dart';
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
    final buttonTextColor = colors.buttonText;
    final accentColor = colors.accent;

    var screenWidth = mediaDataCache.size.width;
    bool isTablet = screenWidth >= 600;
    bool isDesktop = screenWidth >= 900;
    
    // Responsive content width - match age verification screen
    double mainWidth = isDesktop ? 600 : (isTablet ? 600 : double.infinity);

    var arg = RouterUtil.routerArgs(context);
    if (arg != null && arg is bool) {
      backAfterLogin = arg;
    }

    List<Widget> mainList = [];

    // Responsive button width
    double maxButtonWidth = isDesktop ? 400 : (isTablet ? 500 : double.infinity);

    // Top spacing
    mainList.add(Expanded(flex: 1, child: Container()));

    // Main title
    mainList.add(Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxButtonWidth),
        child: Container(
          margin: const EdgeInsets.only(bottom: 40),
          child: Text(
            "Bring your people together",
            style: TextStyle(
              fontFamily: 'SF Pro Rounded',
              color: buttonTextColor,
              fontSize: 46,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ));

    // Subtitle message
    mainList.add(Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxButtonWidth),
        child: Container(
          margin: const EdgeInsets.only(bottom: 80),
          child: Text(
            "Start meaningful exchanges with people you trust.\nHolis is communities built for depth, not noise.",
            style: TextStyle(
              fontFamily: 'SF Pro Rounded',
              color: colors.secondaryText,
              fontSize: 17,
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ));
    
    // Button wrapper for responsive width
    Widget createButton(Widget button) {
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxButtonWidth),
          child: button,
        ),
      );
    }

    // Create a Profile button (primary action)
    mainList.add(createButton(
      SizedBox(
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/imgs/profile.png',
                    width: 20,
                    height: 20,
                    // Removed color to show original image
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback icon if image fails to load
                      return Icon(
                        Icons.person_rounded,
                        size: 20,
                        color: buttonTextColor,
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      "Create a Profile",
                      style: TextStyle(
                        fontFamily: 'SF Pro Rounded',
                        color: buttonTextColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ));

    mainList.add(const SizedBox(height: 16));

    // Login with Nostr button (secondary action) 
    mainList.add(createButton(
      SizedBox(
        width: double.infinity,
        child: GestureDetector(
          onTap: _showLoginSheet,
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/imgs/nostrich.png',
                    width: 20,
                    height: 20,
                    // Removed color to show original image
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback icon if image fails to load
                      return Icon(
                        Icons.bolt_rounded,
                        size: 20,
                        color: buttonTextColor,
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      "Login with Nostr",
                      style: TextStyle(
                        fontFamily: 'SF Pro Rounded',
                        color: buttonTextColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ));

    // Bottom spacing and terms
    mainList.add(Expanded(flex: 1, child: Container()));
    
    // Terms of service
    mainList.add(GestureDetector(
      onTap: () {
        _showTermsSheet();
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 40),
        child: StyledText(
          text: "By continuing, you accept our\n<accent>Terms of Service</accent>",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'SF Pro Rounded',
            color: colors.secondaryText,
            fontSize: 16,
            height: 1.5,
          ),
          tags: {
            'accent': StyledTextTag(
              style: TextStyle(
                fontFamily: 'SF Pro Rounded',
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
                            fontFamily: 'SF Pro Rounded',
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
                  horizontal: 40,
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

  /// Shows the login sheet
  void _showLoginSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withAlpha((255 * 0.5).round()),
      enableDrag: true,
      isDismissible: true,
      builder: (BuildContext context) {
        // Get responsive width values
        var screenWidth = MediaQuery.of(context).size.width;
        bool isTablet = screenWidth >= 600;
        bool isDesktop = screenWidth >= 900;
        double sheetMaxWidth = isDesktop ? 600 : (isTablet ? 600 : double.infinity);
        
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
              },
              child: Container(
                color: Colors.transparent,
                height: 100,  // Touch area above sheet
              ),
            ),
            AnimatedPadding(
              padding: MediaQuery.of(context).viewInsets,
              duration: const Duration(milliseconds: 100),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: sheetMaxWidth),
                  child: Container(
                    decoration: BoxDecoration(
                      color: context.colors.loginBackground,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: SafeArea(
                      top: false,
                      bottom: true,
                      child: _buildLoginSheet(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Builds the login sheet content
  Widget _buildLoginSheet() {
    final colors = context.colors;
    Color accentColor = colors.accent;
    Color buttonTextColor = colors.buttonText;
    
    // Get screen width for responsive design
    var screenWidth = MediaQuery.of(context).size.width;
    bool isTablet = screenWidth >= 600;
    bool isDesktop = screenWidth >= 900;

    // Wrapper function for responsive elements
    Widget wrapResponsive(Widget child) {
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isDesktop ? 400 : 500),
          child: child,
        ),
      );
    }
    
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setSheetState) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(40, 32, 40, 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Close button
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: buttonTextColor.withAlpha((255 * 0.1).round()),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close,
                      color: buttonTextColor,
                      size: 20,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Nostrich icon above title
              Center(
                child: Image.asset(
                  'assets/imgs/nostrich.png',
                  width: 80,
                  height: 80,
                  // No color tinting to show the original image
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback icon if image fails to load
                    return Icon(
                      Icons.bolt_rounded,
                      size: 80,
                      color: buttonTextColor,
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Login form title
              wrapResponsive(
                Center(
                  child: Text(
                    "Login with Nostr",
                    style: TextStyle(
                      fontFamily: 'SF Pro Rounded',
                      color: buttonTextColor,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Login options explainer
              wrapResponsive(
                Text(
                  "Enter your nsec private key or nsecBunker URL. For identities like user@nsec.app, you must set up a bunker URL in your NIP-05 metadata. Read-only access is not supported.",
                  style: TextStyle(
                    fontFamily: 'SF Pro Rounded',
                    color: colors.secondaryText,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
                
                // Private key input field
                wrapResponsive(
                  CustomInputField(
                    controller: _controller,
                    isObscured: _isTextObscured,
                    accentColor: accentColor,
                    secondaryTextColor: colors.secondaryText,
                    onToggleObscure: () {
                      setSheetState(() {
                        _isTextObscured = !_isTextObscured;
                      });
                    },
                    onChanged: (value) {
                      setSheetState(() {
                        _isLoginButtonEnabled = value.isNotEmpty;
                      });
                    },
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Login button
                wrapResponsive(
                  SizedBox(
                    width: double.infinity,
                    child: GestureDetector(
                      onTap: _isLoginButtonEnabled ? _doLogin : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          color: _isLoginButtonEnabled 
                            ? accentColor
                            : accentColor.withAlpha((255 * 0.4).round()),
                          borderRadius: BorderRadius.circular(32),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "Login",
                          style: TextStyle(
                            fontFamily: 'SF Pro Rounded',
                            color: _isLoginButtonEnabled
                              ? buttonTextColor
                              : buttonTextColor.withAlpha((255 * 0.4).round()),
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                
                // External signer options
                if (PlatformUtil.isAndroid() && existAndroidNostrSigner) ...[
                  const SizedBox(height: 16),
                  wrapResponsive(
                    SizedBox(
                      width: double.infinity,
                      child: GestureDetector(
                        onTap: _loginByAndroidSigner,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            border: Border.all(
                              color: colors.secondaryText.withAlpha((255 * 0.3).round()),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(32),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            localization.loginWithAndroidSigner,
                            style: TextStyle(
                              fontFamily: 'SF Pro Rounded',
                              color: buttonTextColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                
                if (PlatformUtil.isWeb() && existWebNostrSigner) ...[
                  const SizedBox(height: 16),
                  wrapResponsive(
                    SizedBox(
                      width: double.infinity,
                      child: GestureDetector(
                        onTap: _loginWithWebSigner,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            border: Border.all(
                              color: colors.secondaryText.withAlpha((255 * 0.3).round()),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(32),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            localization.loginWithNIP07Extension,
                            style: TextStyle(
                              fontFamily: 'SF Pro Rounded',
                              color: buttonTextColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
            ],
          ),
        );
      },
    );
  }

  /// Asynchronous function to handle login when the button is pressed
  Future<void> _doLogin() async {
    var pk = _controller.text;
    if (pk.isEmpty) {
      if (!mounted) return;
      StyledBotToast.show(context, text: S.of(context).inputCanNotBeNull);
      return;
    }
    
    // Store whether we're in a modal sheet by checking if Navigator can pop
    bool wasInSheet = Navigator.of(context).canPop();

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
                
                // Dismiss sheet if we're in one
                if (wasInSheet && mounted) {
                  Navigator.of(context).pop();
                }
                
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

    // Dismiss sheet if we're in one
    if (wasInSheet && mounted) {
      Navigator.of(context).pop();
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
    // Store whether we're in a modal sheet
    bool wasInSheet = Navigator.of(context).canPop();
    
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

    // Dismiss sheet if we're in one
    if (wasInSheet && mounted) {
      Navigator.of(context).pop();
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

  Future<void> _loginWithWebSigner() async {
    // Store whether we're in a modal sheet
    bool wasInSheet = Navigator.of(context).canPop();
    
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

    // Dismiss sheet if we're in one
    if (wasInSheet && mounted) {
      Navigator.of(context).pop();
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

  void _doPreLogin() {
    if (backAfterLogin) {
      AccountManagerWidgetState.clearCurrentMemInfo();
      nostr!.close();
      nostr = null;
    }
  }

  /// Shows the Terms of Service sheet
  void _showTermsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withAlpha((255 * 0.5).round()),
      enableDrag: true,
      isDismissible: true,
      builder: (BuildContext context) {
        // Get responsive width values
        var screenWidth = MediaQuery.of(context).size.width;
        bool isTablet = screenWidth >= 600;
        bool isDesktop = screenWidth >= 900;
        double sheetMaxWidth = isDesktop ? 600 : (isTablet ? 600 : double.infinity);
        
        return GestureDetector(
          onTap: () {
            // Dismiss the sheet when tapping outside
            Navigator.of(context).pop();
          },
          child: Container(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: () {}, // Prevent dismissal when tapping on the sheet itself
              child: Align(
                alignment: Alignment.bottomCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: sheetMaxWidth),
                  child: DraggableScrollableSheet(
                    initialChildSize: 0.9,
                    minChildSize: 0.5,
                    maxChildSize: 0.95,
                    builder: (_, scrollController) {
                      return Container(
                        decoration: BoxDecoration(
                          color: context.colors.loginBackground,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(24),
                            topRight: Radius.circular(24),
                          ),
                        ),
                        child: Column(
                          children: [
                            // Drag handle and close button
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Terms of Service",
                                    style: TextStyle(
                                      fontFamily: 'SF Pro Rounded',
                                      color: context.colors.titleText,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => Navigator.pop(context),
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: context.colors.buttonText.withAlpha((255 * 0.1).round()),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.close,
                                        color: context.colors.buttonText,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Divider(
                              color: context.colors.divider,
                              height: 1,
                            ),
                            // WebView content
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: WebViewWidget(
                                  url: Base.privacyLink,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Custom input field with hover and focus border color changes
class CustomInputField extends StatefulWidget {
  final TextEditingController controller;
  final bool isObscured;
  final Color accentColor;
  final Color secondaryTextColor;
  final VoidCallback onToggleObscure;
  final ValueChanged<String>? onChanged;
  
  const CustomInputField({
    super.key,
    required this.controller,
    required this.isObscured,
    required this.accentColor,
    required this.secondaryTextColor,
    required this.onToggleObscure,
    this.onChanged,
  });
  
  @override
  State<CustomInputField> createState() => _CustomInputFieldState();
}

class _CustomInputFieldState extends State<CustomInputField> {
  bool _isHovered = false;
  bool _isFocused = false;
  final FocusNode _focusNode = FocusNode();
  
  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }
  
  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    // Determine border color based on state
    Color borderColor = _isFocused || _isHovered 
        ? widget.accentColor
        : const Color(0xFF2E4052);
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: borderColor,
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            autofocus: true,
            onChanged: widget.onChanged,
            style: TextStyle(
              fontFamily: 'SF Pro Rounded',
              color: Colors.white,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF11171F),
              hintText: 'nsec',
              hintStyle: TextStyle(
                fontFamily: 'SF Pro Rounded',
                color: widget.secondaryTextColor,
                fontSize: 16,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              hoverColor: Colors.transparent,
              contentPadding: const EdgeInsets.all(16),
              suffixIcon: IconButton(
                icon: Icon(
                  widget.isObscured ? Icons.visibility : Icons.visibility_off,
                  color: widget.secondaryTextColor,
                ),
                onPressed: widget.onToggleObscure,
                hoverColor: Colors.transparent,
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
              ),
            ),
            obscureText: widget.isObscured,
          ),
        ),
      ),
    );
  }
}
