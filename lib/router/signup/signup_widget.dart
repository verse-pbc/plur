import 'dart:math';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nostr_sdk/client_utils/keys.dart';

import '../../generated/l10n.dart';
import '../../theme/app_colors.dart';
import '../../util/dirtywords_util.dart';
import '../../widget/material_icon_fix.dart';

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
    // Return the private key and nickname to the login screen
    Map<String, String> result = {
      'privateKey': _privateKey,
      'userName': _nicknameController.text.trim(),
    };
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    localization = S.of(context);
    
    // Get colors from theme
    final colors = context.colors;
    final accentColor = colors.accent;
    final buttonTextColor = colors.buttonText;
    
    // Calculate responsive width values
    var screenWidth = MediaQuery.of(context).size.width;
    bool isTablet = screenWidth >= 600;
    bool isDesktop = screenWidth >= 900;
    double mainWidth = isDesktop ? 600 : (isTablet ? 600 : double.infinity);
    double buttonMaxWidth = isDesktop ? 400 : (isTablet ? 500 : double.infinity);

    // Determine which step to display
    Widget stepContent;
    switch (_currentStep) {
      case 0:
        stepContent = _buildAgeVerificationStep(buttonMaxWidth);
        break;
      case 1:
        stepContent = _buildNicknameStep(buttonMaxWidth);
        break;
      case 2:
        stepContent = _buildEmailStep(buttonMaxWidth);
        break;
      case 3:
        stepContent = _buildFinalStep(buttonMaxWidth);
        break;
      default:
        stepContent = _buildAgeVerificationStep(buttonMaxWidth);
    }

    return Scaffold(
      backgroundColor: colors.loginBackground,
      body: SafeArea(
        child: Stack(
          children: [
            // Back button
            if (_currentStep > 0)
              Positioned(
                top: 16,
                left: 16,
                child: GestureDetector(
                  onTap: _previousStep,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: buttonTextColor.withAlpha((255 * 0.1).round()),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: FixedIcon(
                      Icons.chevron_left,
                      color: buttonTextColor,
                      size: 24,
                    ),
                  ),
                ),
              ),
              
            // Progress indicator
            if (_currentStep < 3) // Don't show dots on final screen
              Positioned(
                top: 32,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
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
                            : colors.secondaryText.withAlpha((0.3 * 255).round()),
                      ),
                    ),
                  ),
                ),
              ),
              
            // Main content container
            SizedBox(
              width: double.maxFinite,
              height: double.maxFinite,
              child: Center(
                child: SizedBox(
                  width: mainWidth,
                  child: stepContent,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }


  /// Builds the age verification screen (Step 0)
  Widget _buildAgeVerificationStep(double buttonMaxWidth) {
    final colors = context.colors;
    final accentColor = colors.accent;
    final buttonTextColor = colors.buttonText;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Driver's license icon or calendar icon
          Image.asset(
            'assets/imgs/drivers-licence.png',
            width: 80,
            height: 80,
            errorBuilder: (context, error, stackTrace) {
              // Fallback icon if image fails to load
              return Icon(
                Icons.calendar_month_rounded,
                size: 80,
                color: buttonTextColor,
              );
            },
          ),
      
          const SizedBox(height: 32),
          
          // Title
          Text(
            "Age Verification",
            key: const Key('age_verification_title'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'SF Pro Rounded',
              color: colors.titleText,
              fontSize: 32,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Description
          Text(
            "You must be at least 16 years old to use this app.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'SF Pro Rounded',
              color: colors.secondaryText,
              fontSize: 17,
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
          ),
          
          const SizedBox(height: 48),
          
          // Age verification checkbox
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: buttonMaxWidth),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isAgeVerified = !_isAgeVerified;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: buttonTextColor.withAlpha((255 * 0.05).round()),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _isAgeVerified
                          ? accentColor
                          : colors.secondaryText.withAlpha((255 * 0.3).round()),
                      width: 2,
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: _isAgeVerified ? accentColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: _isAgeVerified
                                ? accentColor
                                : colors.secondaryText.withAlpha((255 * 0.5).round()),
                            width: 2,
                          ),
                        ),
                        child: _isAgeVerified
                            ? Icon(
                                Icons.check,
                                color: buttonTextColor,
                                size: 18,
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          "I confirm that I am 16 years of age or older",
                          style: TextStyle(
                            fontFamily: 'SF Pro Rounded',
                            color: colors.primaryText,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 48),
          
          // Continue button
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: buttonMaxWidth),
              child: SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: _isAgeVerified ? _nextStep : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: _isAgeVerified 
                        ? accentColor
                        : accentColor.withAlpha((255 * 0.4).round()),
                      borderRadius: BorderRadius.circular(32),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "Continue",
                      style: TextStyle(
                        fontFamily: 'SF Pro Rounded',
                        color: _isAgeVerified
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
          ),
        ],
      ),
    );
  }

  /// Builds the nickname input screen (Step 1)
  Widget _buildNicknameStep(double buttonMaxWidth) {
    final colors = context.colors;
    final accentColor = colors.accent;
    final buttonTextColor = colors.buttonText;
    final secondaryTextColor = colors.secondaryText;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Person icon
          Image.asset(
            'assets/imgs/profile.png',
            width: 80,
            height: 80,
            errorBuilder: (context, error, stackTrace) {
              // Fallback icon if image fails to load
              return Icon(
                Icons.person_rounded,
                size: 80,
                color: buttonTextColor,
              );
            },
          ),
      
          const SizedBox(height: 32),
          
          // Title
          Text(
            "Choose a Nickname",
            key: const Key('nickname_input_title'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'SF Pro Rounded',
              color: colors.titleText,
              fontSize: 32,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Description
          Text(
            "This is how you'll appear to others.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'SF Pro Rounded',
              color: colors.secondaryText,
              fontSize: 17,
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
          ),
          
          const SizedBox(height: 48),
          
          // Nickname input field
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: buttonMaxWidth),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF2E4052),
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: TextField(
                    controller: _nicknameController,
                    autofocus: true,
                    style: TextStyle(
                      fontFamily: 'SF Pro Rounded',
                      color: buttonTextColor,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF11171F),
                      hintText: "Enter nickname (min. 3 characters)",
                      hintStyle: TextStyle(
                        fontFamily: 'SF Pro Rounded',
                        color: secondaryTextColor,
                        fontSize: 16,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                      errorText: _nicknameController.text.isNotEmpty && !_isNicknameValid
                        ? "Nickname must be at least 3 characters and appropriate"
                        : null,
                      errorStyle: const TextStyle(
                        fontFamily: 'SF Pro Rounded',
                        color: Colors.red,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 48),
          
          // Continue button
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: buttonMaxWidth),
              child: SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: _isNicknameValid ? _nextStep : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: _isNicknameValid 
                        ? accentColor
                        : accentColor.withAlpha((255 * 0.4).round()),
                      borderRadius: BorderRadius.circular(32),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "Continue",
                      style: TextStyle(
                        fontFamily: 'SF Pro Rounded',
                        color: _isNicknameValid
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
          ),
        ],
      ),
    );
  }

  /// Builds the email input screen (Step 2)
  Widget _buildEmailStep(double buttonMaxWidth) {
    final colors = context.colors;
    final accentColor = colors.accent;
    final buttonTextColor = colors.buttonText;
    final secondaryTextColor = colors.secondaryText;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Email icon
          Image.asset(
            'assets/imgs/email.png',
            width: 80,
            height: 80,
            errorBuilder: (context, error, stackTrace) {
              // Fallback icon if image fails to load
              return Icon(
                Icons.email_rounded,
                size: 80,
                color: buttonTextColor,
              );
            },
          ),
      
          const SizedBox(height: 32),
          
          // Title
          Text(
            "Email (Optional)",
            key: const Key('email_input_title'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'SF Pro Rounded',
              color: colors.titleText,
              fontSize: 32,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Description
          Text(
            "Add your email address for account recovery (optional).",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'SF Pro Rounded',
              color: colors.secondaryText,
              fontSize: 17,
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
          ),
          
          const SizedBox(height: 48),
          
          // Email input field
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: buttonMaxWidth),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF2E4052),
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofocus: true,
                    style: TextStyle(
                      fontFamily: 'SF Pro Rounded',
                      color: buttonTextColor,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF11171F),
                      hintText: "Enter email address (optional)",
                      hintStyle: TextStyle(
                        fontFamily: 'SF Pro Rounded',
                        color: secondaryTextColor,
                        fontSize: 16,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                      errorText: !_isEmailValid ? "Please enter a valid email address" : null,
                      errorStyle: const TextStyle(
                        fontFamily: 'SF Pro Rounded',
                        color: Colors.red,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 48),
          
          // Continue button
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: buttonMaxWidth),
              child: SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: _isEmailValid ? _nextStep : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: _isEmailValid 
                        ? accentColor
                        : accentColor.withAlpha((255 * 0.4).round()),
                      borderRadius: BorderRadius.circular(32),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _emailController.text.isEmpty ? "Skip" : "Continue",
                      style: TextStyle(
                        fontFamily: 'SF Pro Rounded',
                        color: _isEmailValid
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
          ),
        ],
      ),
    );
  }

  /// Builds the final welcome screen (Step 3)
  Widget _buildFinalStep(double buttonMaxWidth) {
    final colors = context.colors;
    final accentColor = colors.accent;
    final buttonTextColor = colors.buttonText;
    final secondaryTextColor = colors.secondaryText;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Key icon
          Image.asset(
            'assets/imgs/key.png',
            width: 80,
            height: 80,
            errorBuilder: (context, error, stackTrace) {
              // Fallback icon if image fails to load
              return Transform.flip(
                flipX: true,
                child: Transform.rotate(
                  angle: 45 * 3.14 / 180,
                  child: Icon(
                    Icons.key,
                    color: accentColor,
                    size: 80,
                  ),
                ),
              );
            },
          ),
      
          const SizedBox(height: 32),
          
          // Title
          Text(
            localization.thisIsTheKeyToYourAccount,
            key: const Key('private_key_title'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'SF Pro Rounded',
              color: colors.titleText,
              fontSize: 32,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Description
          Text(
            "Save it somewhere safe. You'll need it to log in again.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'SF Pro Rounded',
              color: colors.secondaryText,
              fontSize: 17,
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
          ),
          
          const SizedBox(height: 48),
          
          // Private key display
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: buttonMaxWidth),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF2E4052),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        _isTextObscured ? "*" * min(_privateKey.length, 40) : _privateKey,
                        style: TextStyle(
                          fontFamily: "monospace",
                          fontSize: 15,
                          letterSpacing: 1.0,
                          color: secondaryTextColor,
                        ),
                      ),
                    ),
                    const Divider(
                      height: 1,
                      color: Color(0xFF2E4052),
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
                        color: secondaryTextColor,
                        size: 20,
                      ),
                      label: Text(
                        localization.viewKey,
                        style: TextStyle(
                          fontFamily: 'SF Pro Rounded',
                          color: secondaryTextColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        alignment: Alignment.centerLeft,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Key security acknowledgment checkbox
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: buttonMaxWidth),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isDoneButtonEnabled = !_isDoneButtonEnabled;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: buttonTextColor.withAlpha((255 * 0.05).round()),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _isDoneButtonEnabled
                          ? accentColor
                          : colors.secondaryText.withAlpha((255 * 0.3).round()),
                      width: 2,
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: _isDoneButtonEnabled ? accentColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: _isDoneButtonEnabled
                                ? accentColor
                                : colors.secondaryText.withAlpha((255 * 0.5).round()),
                            width: 2,
                          ),
                        ),
                        child: _isDoneButtonEnabled
                            ? Icon(
                                Icons.check,
                                color: buttonTextColor,
                                size: 18,
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          localization.iUnderstandIShouldntShareThisKey,
                          style: TextStyle(
                            fontFamily: 'SF Pro Rounded',
                            color: colors.primaryText,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 48),
          
          // Copy and complete button
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: buttonMaxWidth),
              child: SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: _isDoneButtonEnabled ? _copyAndContinue : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: _isDoneButtonEnabled 
                        ? accentColor
                        : accentColor.withAlpha((255 * 0.4).round()),
                      borderRadius: BorderRadius.circular(32),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      localization.copyAndContinue,
                      style: TextStyle(
                        fontFamily: 'SF Pro Rounded',
                        color: _isDoneButtonEnabled
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
          ),
        ],
      ),
    );
  }
}