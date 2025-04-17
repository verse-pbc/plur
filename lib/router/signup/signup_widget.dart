import 'dart:math';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nostr_sdk/client_utils/keys.dart';

import '../../consts/base.dart';
import '../../generated/l10n.dart';
import '../../main.dart';
import '../../util/table_mode_util.dart';
import '../../util/theme_util.dart';
import '../../util/dirtywords_util.dart';

/// A widget for user sign-up with multi-step onboarding.
///
/// Implements a 4-step onboarding process:
/// 1. Age verification
/// 2. Nickname input
/// 3. Email input (optional)
/// 4. Private key generation and display
class SignupWidget extends StatefulWidget {
  /// Creates an instance of [SignupWidget].
  const SignupWidget({super.key});

  @override
  State<StatefulWidget> createState() => _SignupWidgetState();
}

/// The state class for [SignupWidget].
class _SignupWidgetState extends State<SignupWidget> {
  /// Current step in the onboarding process (0-based index)
  /// We start with the age verification step (step 0) since welcome screen is now in login screen
  int _currentStep = 0;

  /// The user's private key.
  /// Generated dynamically when the sign-up process begins.
  final String _privateKey = generatePrivateKey();

  /// Controls the visibility of the generated private key.
  bool _isTextObscured = true;

  /// Tracks whether the user has acknowledged the risks of sharing the private key.
  bool _isDoneButtonEnabled = false;

  /// Tracks whether the user has confirmed being 16 or older
  bool _isAgeVerified = false;

  /// Nickname input controller
  final TextEditingController _nicknameController = TextEditingController();

  /// Email input controller
  final TextEditingController _emailController = TextEditingController();

  /// Validation state for nickname
  bool _isNicknameValid = false;

  /// Validation state for email
  bool _isEmailValid = true; // Default true because email is optional

  /// Localization object for handling translated text.
  late S localization;

  /// Regex pattern for validating email addresses
  final RegExp _emailRegex = RegExp(
      r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$');

  @override
  void initState() {
    super.initState();
    // Add listeners to track text changes
    _nicknameController.addListener(_validateNickname);
    _emailController.addListener(_validateEmail);
  }

  @override
  void dispose() {
    _nicknameController.removeListener(_validateNickname);
    _emailController.removeListener(_validateEmail);
    _nicknameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  /// Validates the nickname input
  /// - Must be at least 3 characters long
  /// - Cannot contain profanity
  void _validateNickname() {
    final nickname = _nicknameController.text.trim();
    setState(() {
      // Check if nickname is at least 3 characters long
      if (nickname.length < 3) {
        _isNicknameValid = false;
        return;
      }

      // Check for profanity (implement or connect to existing profanity filter)
      final containsProfanity = TrieTree(TrieNode()).check(nickname.toLowerCase());
      _isNicknameValid = !containsProfanity && nickname.length >= 3;
    });
  }

  /// Validates the email input
  /// - Optional field (can be empty)
  /// - If provided, must be a valid email format
  void _validateEmail() {
    final email = _emailController.text.trim();
    setState(() {
      _isEmailValid = email.isEmpty || _emailRegex.hasMatch(email);
    });
  }

  /// Advances to the next step in the onboarding process
  void _nextStep() {
    setState(() {
      _currentStep++;
    });
  }

  /// Returns to the previous step in the onboarding process
  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }


  /// Copies the private key to the clipboard and completes the signup process
  void _copyAndContinue() async {
    Clipboard.setData(ClipboardData(text: _privateKey)).then((_) {
      BotToast.showText(text: localization.keyHasBeenCopy);
    });
    // Return the private key to the login screen
    Navigator.of(context).pop(_privateKey);
  }

  @override
  Widget build(BuildContext context) {
    localization = S.of(context);
    
    // Save some colors for later
    final themeData = Theme.of(context);
    final customColors = themeData.customColors;
    final dimmedColor = customColors.dimmedColor;
    final buttonTextColor = customColors.buttonTextColor;
    final accentColor = customColors.accentColor;
    final primaryForegroundColor = customColors.primaryForegroundColor;
    final appBgColor = customColors.appBgColor;

    // Calculate content width
    final maxWidth = mediaDataCache.size.width;
    var mainWidth = maxWidth * 0.8;
    if (TableModeUtil.isTableMode()) {
      mainWidth = min(mainWidth, 550);
    }

    // Determine which step to display
    Widget stepContent;
    switch (_currentStep) {
      case 0:
        stepContent = _buildAgeVerificationStep(
          primaryForegroundColor,
          dimmedColor,
          accentColor,
          buttonTextColor,
        );
        break;
      case 1:
        stepContent = _buildNicknameStep(
          primaryForegroundColor,
          dimmedColor,
          accentColor,
          buttonTextColor,
        );
        break;
      case 2:
        stepContent = _buildEmailStep(
          primaryForegroundColor,
          dimmedColor,
          accentColor,
          buttonTextColor,
        );
        break;
      case 3:
        stepContent = _buildFinalStep(
          primaryForegroundColor,
          dimmedColor,
          accentColor,
          buttonTextColor,
        );
        break;
      default:
        stepContent = _buildAgeVerificationStep(
          primaryForegroundColor,
          dimmedColor,
          accentColor,
          buttonTextColor,
        );
    }

    return Scaffold(
      // Sets the background color
      backgroundColor: appBgColor,
      // Back button
      appBar: _currentStep > 0
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: primaryForegroundColor),
                onPressed: _previousStep,
              ),
            )
          : null,
      body: SizedBox(
        width: double.maxFinite,
        height: double.maxFinite,
        child: Stack(
          alignment: AlignmentDirectional.center,
          children: [
            // Horizontal progress dots for step indication
            if (_currentStep < 3) // Don't show dots on final screen
              Positioned(
                top: 20,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    3, // Total number of steps (excluding final welcome screen)
                    (index) => Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index <= _currentStep
                            ? accentColor
                            : dimmedColor.withAlpha((0.3 * 255).round()),
                      ),
                    ),
                  ),
                ),
              ),
            SizedBox(
              width: mainWidth,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Base.basePadding * 2,
                ),
                child: stepContent,
              ),
            )
          ],
        ),
      ),
    );
  }


  /// Builds the age verification screen (Step 0)
  Widget _buildAgeVerificationStep(
    Color primaryForegroundColor,
    Color dimmedColor,
    Color accentColor,
    Color buttonTextColor,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: Container()),
        Icon(
          Icons.calendar_today,
          color: accentColor,
          size: 60,
        ),
        const SizedBox(height: 20),
        Text(
          "Age Verification",
          style: TextStyle(
            color: primaryForegroundColor,
            fontSize: 31.26,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.8,
            height: kTextHeightNone,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          "You must be at least 16 years old to use this app.",
          style: TextStyle(
            color: primaryForegroundColor,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
        Expanded(flex: 2, child: Container()),
        
        // Age verification checkbox
        ListTileTheme(
          data: const ListTileThemeData(
            titleAlignment: ListTileTitleAlignment.top,
            contentPadding: EdgeInsets.zero,
          ),
          child: CheckboxListTile(
            key: const Key('age_verification_checkbox'),
            title: Text(
              "I confirm that I am 16 years of age or older",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: primaryForegroundColor,
                letterSpacing: 0.7,
                height: kTextHeightNone,
              ),
            ),
            value: _isAgeVerified,
            onChanged: (bool? value) {
              setState(() {
                _isAgeVerified = value!;
              });
            },
            activeColor: accentColor,
            side: BorderSide(color: dimmedColor, width: 2),
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
            visualDensity: VisualDensity.compact,
          ),
        ),
        const SizedBox(height: 20),
        
        // Continue button
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _isAgeVerified ? _nextStep : null,
            style: FilledButton.styleFrom(
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
              backgroundColor: accentColor,
              disabledBackgroundColor: accentColor.withAlpha((0.4 * 255).round()),
              foregroundColor: buttonTextColor,
              disabledForegroundColor: buttonTextColor.withAlpha((0.4 * 255).round()),
            ),
            child: const Text(
              "Continue",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        Expanded(flex: 1, child: Container()),
      ],
    );
  }

  /// Builds the nickname input screen (Step 1)
  Widget _buildNicknameStep(
    Color primaryForegroundColor,
    Color dimmedColor,
    Color accentColor,
    Color buttonTextColor,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: Container()),
        Icon(
          Icons.person,
          color: accentColor,
          size: 60,
        ),
        const SizedBox(height: 20),
        Text(
          "Choose a Nickname",
          style: TextStyle(
            color: primaryForegroundColor,
            fontSize: 31.26,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.8,
            height: kTextHeightNone,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          "This is how you'll appear to others.",
          style: TextStyle(
            color: primaryForegroundColor,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 20),
        
        // Nickname input field
        TextField(
          controller: _nicknameController,
          decoration: InputDecoration(
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: dimmedColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: dimmedColor),
            ),
            errorBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.red),
            ),
            hintText: "Enter nickname (min. 3 characters)",
            hintStyle: TextStyle(color: dimmedColor, fontSize: 16),
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            errorText: _nicknameController.text.isNotEmpty && !_isNicknameValid
                ? "Nickname must be at least 3 characters and appropriate"
                : null,
          ),
          style: TextStyle(
            color: primaryForegroundColor,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
        Expanded(flex: 2, child: Container()),
        
        // Continue button
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _isNicknameValid ? _nextStep : null,
            style: FilledButton.styleFrom(
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
              backgroundColor: accentColor,
              disabledBackgroundColor: accentColor.withAlpha((0.4 * 255).round()),
              foregroundColor: buttonTextColor,
              disabledForegroundColor: buttonTextColor.withAlpha((0.4 * 255).round()),
            ),
            child: const Text(
              "Continue",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        Expanded(flex: 1, child: Container()),
      ],
    );
  }

  /// Builds the email input screen (Step 2)
  Widget _buildEmailStep(
    Color primaryForegroundColor,
    Color dimmedColor,
    Color accentColor,
    Color buttonTextColor,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: Container()),
        Icon(
          Icons.email,
          color: accentColor,
          size: 60,
        ),
        const SizedBox(height: 20),
        Text(
          "Email (Optional)",
          style: TextStyle(
            color: primaryForegroundColor,
            fontSize: 31.26,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.8,
            height: kTextHeightNone,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          "Add your email address for account recovery (optional).",
          style: TextStyle(
            color: primaryForegroundColor,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 20),
        
        // Email input field
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: dimmedColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: dimmedColor),
            ),
            errorBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.red),
            ),
            hintText: "Enter email address (optional)",
            hintStyle: TextStyle(color: dimmedColor, fontSize: 16),
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            errorText: !_isEmailValid ? "Please enter a valid email address" : null,
          ),
          style: TextStyle(
            color: primaryForegroundColor,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
        Expanded(flex: 2, child: Container()),
        
        // Continue button and skip button
        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: _isEmailValid ? _nextStep : null,
                style: FilledButton.styleFrom(
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  backgroundColor: accentColor,
                  disabledBackgroundColor: accentColor.withOpacity(0.4),
                  foregroundColor: buttonTextColor,
                  disabledForegroundColor: buttonTextColor.withOpacity(0.4),
                ),
                child: Text(
                  _emailController.text.isEmpty ? "Skip" : "Continue",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        Expanded(flex: 1, child: Container()),
      ],
    );
  }

  /// Builds the final welcome screen (Step 3)
  Widget _buildFinalStep(
    Color primaryForegroundColor,
    Color dimmedColor,
    Color accentColor,
    Color buttonTextColor,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: Container()),
        
        // Private key display
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Transform.flip(
              flipX: true,
              child: Transform.rotate(
                angle: 45 * 3.14 / 180,
                child: const Icon(
                  Icons.key,
                  color: Colors.yellow,
                  size: 60,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              localization.thisIsTheKeyToYourAccount,
              style: TextStyle(
                color: primaryForegroundColor,
                fontSize: 31.26,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.8,
                height: kTextHeightNone,
              ),
            ),
          ],
        ),
        const SizedBox(height: 40),
        
        // Private key container
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: dimmedColor, width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Private key display
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 16, right: 16),
                child: Text(
                  _isTextObscured ? "*" * _privateKey.length : _privateKey,
                  style: TextStyle(
                    fontFamily: "monospace",
                    fontFamilyFallback: const ["Courier"],
                    fontSize: 15.93,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.182,
                    color: dimmedColor,
                  ),
                ),
              ),
              // View key toggle button
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _isTextObscured = !_isTextObscured;
                  });
                },
                icon: Icon(
                  _isTextObscured ? Icons.visibility : Icons.visibility_off,
                  color: dimmedColor,
                ),
                label: Text(
                  localization.viewKey,
                  style: TextStyle(
                    color: dimmedColor,
                    fontSize: 15.93,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.182,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.only(left: 16, right: 16),
                  alignment: Alignment.centerLeft,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        
        // Key security acknowledgment checkbox
        ListTileTheme(
          data: const ListTileThemeData(
            titleAlignment: ListTileTitleAlignment.top,
            contentPadding: EdgeInsets.zero,
          ),
          child: CheckboxListTile(
            key: const Key('acknowledgement_checkbox'),
            title: Text(
              localization.iUnderstandIShouldntShareThisKey,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: primaryForegroundColor,
                letterSpacing: 0.7,
                height: kTextHeightNone,
              ),
            ),
            value: _isDoneButtonEnabled,
            onChanged: (bool? value) {
              setState(() {
                _isDoneButtonEnabled = value!;
              });
            },
            activeColor: accentColor,
            side: BorderSide(color: dimmedColor, width: 2),
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
            visualDensity: VisualDensity.compact,
          ),
        ),
        const SizedBox(height: 20),
        
        // Copy and complete button
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            key: const Key('done_button'),
            onPressed: _isDoneButtonEnabled ? _copyAndContinue : null,
            style: FilledButton.styleFrom(
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
              backgroundColor: accentColor,
              disabledBackgroundColor: accentColor.withAlpha((0.4 * 255).round()),
              foregroundColor: buttonTextColor,
              disabledForegroundColor: buttonTextColor.withAlpha((0.4 * 255).round()),
            ),
            child: Text(
              localization.copyAndContinue,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        Expanded(flex: 1, child: Container()),
      ],
    );
  }
}