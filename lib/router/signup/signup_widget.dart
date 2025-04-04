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

/// A widget for user sign-up.
///
/// Handles the registration process by generating a private key and
/// returning it to the previous page (typically the login screen).
class SignupWidget extends StatefulWidget {
  /// Creates an instance of [SignupWidget].
  const SignupWidget({super.key});

  @override
  State<StatefulWidget> createState() => _SignupWidgetState();
}

/// The state class for [SignupWidget].
class _SignupWidgetState extends State<SignupWidget> {
  /// Tracks whether the user has acknowledged the risks of sharing the private
  /// key.
  ///
  /// Defaults to `false`. The button remains disabled until the user confirms
  /// understanding.
  bool _isDoneButtonEnabled = false;

  /// Controls the visibility of the generated private key.
  ///
  /// When `true`, the private key is hidden from view for security purposes.
  bool _isTextObscured = true;

  /// A string that holds the user's private key.
  ///
  /// This key is generated dynamically when the sign-up process begins.
  final String _privateKey = generatePrivateKey();

  /// Localization object for handling translated text.
  ///
  /// This variable provides access to localized strings for UI components.
  late S localization;

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

    final maxWidth = mediaDataCache.size.width;
    var mainWidth = maxWidth * 0.8;
    if (TableModeUtil.isTableMode()) {
      mainWidth = min(mainWidth, 550);
    }

    List<Widget> mainList = [
      // Adds an expandable empty space to `mainList`, filling available space
      // in a flex container.
      Expanded(flex: 2, child: Container()),

      // Adds a flipped and rotated key icon to visually represent the user's
      // private key and a text explaining the importance of the private key.
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
          const SizedBox(height: 10),
          Text(
            localization.This_is_the_key_to_your_account,
            style: TextStyle(
              color: primaryForegroundColor,
              fontSize: 31.26,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.8,
              height: kTextHeightNone,
            ),
          )
        ],
      ),

      // Adds a fixed space.
      const SizedBox(height: 40),

      // Displays the private key inside a styled container. The key is
      // initially obscured and can be toggled visible using a button.
      Container(
        decoration: BoxDecoration(
          border: Border.all(color: dimmedColor, width: 2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Displays the private key as a masked or unmasked string.
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
            // A button to toggle the visibility of the private key.
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
                localization.view_key,
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

      // Adds an expandable empty space, filling available space in a
      // flex container.
      Expanded(flex: 2, child: Container()),

      // Adds a checkbox list tile for user acknowledgment. The user must
      // confirm they understand the risks of sharing their private key before
      // proceeding.
      // This enables the "Copy & Continue" button.
      ListTileTheme(
        data: const ListTileThemeData(
          titleAlignment: ListTileTitleAlignment.top,
          contentPadding: EdgeInsets.zero,
        ),
        child: CheckboxListTile(
          key: const Key('acknowledgement_checkbox'),
          title: Text(
            localization.I_understand_I_shouldnt_share_this_key,
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

      // Adds a full-width Done button to `mainList`.
      SizedBox(
        width: double.infinity,
        child: FilledButton(
          key: const Key('done_button'),
          // Calls the `_copyAndContinue` function when enabled; otherwise, it
          // remains disabled.
          onPressed: _isDoneButtonEnabled ? _copyAndContinue : null,
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
            localization.Copy_and_Continue,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),

      // Adds an expandable empty space, filling available space in a flex
      // container.
      Expanded(flex: 1, child: Container()),
    ];

    return Scaffold(
      // Sets the background color for the login screen.
      backgroundColor: appBgColor,
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

  /// Copies the private key to the clipboard and navigates back.
  ///
  /// This function ensures that the private key is copied safely and displays a
  /// confirmation message to the user. After copying, the user is navigated
  /// back to the previous screen with the private key as a parameter.
  void _copyAndContinue() async {
    Clipboard.setData(ClipboardData(text: _privateKey)).then((_) {
      BotToast.showText(text: localization.key_has_been_copy);
    });
    Navigator.of(context).pop(_privateKey);
  }
}
