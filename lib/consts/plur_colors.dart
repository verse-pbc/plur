import 'package:flutter/material.dart';

/// Plur theme colors based on the design documents.
class PlurColors {
  // Main brand color - used in both dark and light modes
  static const Color primaryPurple = Color(0xFF7445FE);
  
  // ORIGINAL COLORS - keep for backward compatibility
  static const Color primaryDark = Color(0xFF191B27);
  static const Color primaryText = Color(0xFFB6A0E1); // Updated to match design
  static const Color secondaryText = Color(0xFF63518E);
  static const Color highlightText = Color(0xFFECE2FD);
  static const Color cardBackground = Color(0xFF231F32);
  static const Color appBackground = Color(0xFF191B27);
  static const Color separator = Color(0xFF362E4E);
  
  // Light mode variants
  static const Color lightPrimaryText = Color(0xFF4B3997);
  static const Color lightSecondaryText = Color(0xFF837AA0);
  static const Color lightHighlightText = Color(0xFF231F32);
  static const Color lightCardBackground = Color(0xFFF5F2FF);
  static const Color lightAppBackground = Color(0xFFFFFFFF);
  static const Color lightSeparator = Color(0xFFE5DBFF);
  
  // THEME-AWARE COLOR GETTERS
  
  // Text colors
  static Color getTextColor(Brightness brightness) {
    return brightness == Brightness.dark ? primaryText : lightPrimaryText;
  }
  
  static Color getSecondaryTextColor(Brightness brightness) {
    return brightness == Brightness.dark ? secondaryText : lightSecondaryText;
  }
  
  static Color getHighlightTextColor(Brightness brightness) {
    return brightness == Brightness.dark ? highlightText : lightHighlightText;
  }
  
  // Background colors
  static Color getCardBackgroundColor(Brightness brightness) {
    return brightness == Brightness.dark ? cardBackground : lightCardBackground;
  }
  
  static Color getAppBackgroundColor(Brightness brightness) {
    return brightness == Brightness.dark ? appBackground : lightAppBackground;
  }
  
  static Color getSeparatorColor(Brightness brightness) {
    return brightness == Brightness.dark ? separator : lightSeparator;
  }
  
  // CONTEXT-BASED COLOR HELPERS
  
  // Background colors
  static Color background(BuildContext context) {
    return getAppBackgroundColor(Theme.of(context).brightness);
  }
  
  static Color cardBg(BuildContext context) {
    return getCardBackgroundColor(Theme.of(context).brightness);
  }
  
  // Text colors
  static Color textColor(BuildContext context) {
    return getTextColor(Theme.of(context).brightness);
  }
  
  static Color secondaryTextColor(BuildContext context) {
    return getSecondaryTextColor(Theme.of(context).brightness);
  }
  
  static Color highlightTextColor(BuildContext context) {
    return getHighlightTextColor(Theme.of(context).brightness);
  }
  
  // UI elements
  static Color separatorColor(BuildContext context) {
    return getSeparatorColor(Theme.of(context).brightness);
  }
  
  // Always use primary color for buttons and active elements
  static const Color buttonBackground = primaryPurple;
  static const Color buttonText = Colors.white;
  
  // THEME-AWARE TEXT STYLES
  
  // Original style getters
  static TextStyle getUsernameStyle(Brightness brightness) => TextStyle(
    color: getHighlightTextColor(brightness),
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.29,
    letterSpacing: 0.68,
  );
  
  static TextStyle getHandleStyle(Brightness brightness) => TextStyle(
    color: getSecondaryTextColor(brightness),
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 1.33,
    letterSpacing: 0.60,
  );
  
  static TextStyle getTimestampStyle(Brightness brightness) => TextStyle(
    color: getSecondaryTextColor(brightness),
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 1.33,
    letterSpacing: 0.60,
  );
  
  static TextStyle getContentStyle(Brightness brightness) => TextStyle(
    color: getTextColor(brightness),
    fontSize: 17,
    fontWeight: FontWeight.w400,
    height: 1.35,
    letterSpacing: 0.34,
  );
  
  static TextStyle getHighlightContentStyle(Brightness brightness) => TextStyle(
    color: getHighlightTextColor(brightness),
    fontSize: 17,
    fontWeight: FontWeight.w500,
    height: 1.35,
    letterSpacing: 0.34,
  );
  
  // CONTEXT-BASED TEXT STYLES
  
  // Username style - prominent, used for display names
  static TextStyle usernameStyle(BuildContext context) {
    return getUsernameStyle(Theme.of(context).brightness);
  }
  
  // Handle style - less prominent, used for @handles
  static TextStyle handleStyle(BuildContext context) {
    return getHandleStyle(Theme.of(context).brightness);
  }
  
  // Timestamp style
  static TextStyle timestampStyle(BuildContext context) {
    return getTimestampStyle(Theme.of(context).brightness);
  }
  
  // Main content style
  static TextStyle contentStyle(BuildContext context) {
    return getContentStyle(Theme.of(context).brightness);
  }
  
  // Content highlight style - used for hashtags, links, etc.
  static TextStyle highlightStyle(BuildContext context) {
    return getHighlightContentStyle(Theme.of(context).brightness);
  }
  
  // Small text style
  static TextStyle smallTextStyle(BuildContext context) {
    return TextStyle(
      color: secondaryTextColor(context),
      fontSize: 14.0,
      fontWeight: FontWeight.w400,
    );
  }
}