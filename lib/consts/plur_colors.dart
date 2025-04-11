import 'package:flutter/material.dart';

/// Plur theme colors based on the design documents.
class PlurColors {
  // Main color palette
  static const Color primaryPurple = Color(0xFF7445FE);
  static const Color primaryDark = Color(0xFF191B27);
  
  // Text colors from feed_m_styles
  static const Color primaryText = Color(0xFFB5A0E1);   // Primary text content
  static const Color secondaryText = Color(0xFF63518E); // Secondary text elements like usernames, timestamps
  static const Color highlightText = Color(0xFFECE2FD); // Highlighted elements like hashtags, links

  // Background colors
  static const Color cardBackground = Color(0xFF231F32);
  static const Color appBackground = Color(0xFF191B27);
  
  // UI Elements
  static const Color separator = Color(0xFF362E4E);
  static const Color buttonBackground = Color(0xFF7445FE);
  static const Color buttonText = Color(0xFFFFFFFF);
  
  // Helper methods for text styles based on design docs
  static TextStyle get usernameStyle => const TextStyle(
    color: highlightText,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.29,
    letterSpacing: 0.68,
  );
  
  static TextStyle get handleStyle => const TextStyle(
    color: secondaryText,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 1.33,
    letterSpacing: 0.60,
  );
  
  static TextStyle get timestampStyle => const TextStyle(
    color: secondaryText,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 1.33,
    letterSpacing: 0.60,
  );
  
  static TextStyle get contentStyle => const TextStyle(
    color: primaryText,
    fontSize: 17,
    fontWeight: FontWeight.w400,
    height: 1.35,
    letterSpacing: 0.34,
  );
  
  static TextStyle get highlightContentStyle => const TextStyle(
    color: highlightText,
    fontSize: 17,
    fontWeight: FontWeight.w500,
    height: 1.35,
    letterSpacing: 0.34,
  );
}