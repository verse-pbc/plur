/// Utilities and extensions for managing application theming.
///
/// This file contains:
/// * [ThemeUtil] - Static utility methods for theme-related operations
/// * [CustomColors] - Theme extension that defines custom colors for light/dark themes
/// * [CustomThemeColors] - Extension on [ThemeData] to easily access custom colors
///
////// Usage:
/// ```dart
/// final themeData = Theme.of(context);
/// Color bgColor = themeData.customColors.appBgColor;
/// ```
import 'package:flutter/material.dart';

class ThemeUtil {
  static Color getDialogCoverColor(ThemeData themeData) {
    return (themeData.textTheme.bodyMedium!.color ?? Colors.black)
        .withAlpha(51);
  }
}

@immutable
class CustomColors extends ThemeExtension<CustomColors> {
  const CustomColors({
    required this.accentColor,
    required this.appBgColor,
    required this.buttonTextColor,
    required this.cardBgColor,
    required this.dimmedColor,
    required this.feedBgColor,
    required this.loginBgColor,
    required this.navBgColor,
    required this.notesBgColor,
    required this.primaryForegroundColor,
    required this.secondaryForegroundColor,
    required this.separatorColor,
    required this.tabsBgColor,
    required this.tooltipText,
    required this.tooltipBackground,
  });

  final Color accentColor;
  final Color appBgColor;
  final Color buttonTextColor;
  final Color cardBgColor;
  final Color dimmedColor;
  final Color feedBgColor;
  final Color loginBgColor;
  final Color navBgColor;
  final Color notesBgColor;
  final Color primaryForegroundColor;
  final Color secondaryForegroundColor;
  final Color separatorColor;
  final Color tabsBgColor;
  final Color tooltipText;
  final Color tooltipBackground;

  /// Light theme values based on Plur design system
  static const CustomColors light = CustomColors(
    accentColor: Color(0xFF7445FE), // Changed to Plur primary purple
    appBgColor: Color(0xFFFFFFFF), // From PlurColors.lightAppBackground
    buttonTextColor: Color(0xFFFFFFFF),
    cardBgColor: Color(0xFFF5F2FF), // From PlurColors.lightCardBackground
    dimmedColor: Color(0xFF837AA0), // Secondary text color from PlurColors
    feedBgColor: Color(0xFFF5F2FF), // Light background
    loginBgColor: Color(0xFFFFFFFF),
    navBgColor: Color(0xFFFFFFFF),
    notesBgColor: Color(0xFFF5F2FF),
    primaryForegroundColor: Color(0xFF4B3997), // Primary text color from PlurColors
    secondaryForegroundColor: Color(0xFF837AA0), // Secondary text color from PlurColors
    separatorColor: Color(0xFFE5DBFF), // From PlurColors.lightSeparator
    tabsBgColor: Color(0xFFFFFFFF),
    tooltipText: Color(0xFFFFFFFF),
    tooltipBackground: Color(0xFF7445FE), // Plur purple for tooltips
  );

  /// Dark theme values based on design specs in doc/features/feed_m_styles
  static const CustomColors dark = CustomColors(
    accentColor: Color(0xFF7445FE), // Changed to Plur primary purple
    appBgColor: Color(0xFF191B27), // From PlurColors.primaryDark
    buttonTextColor: Color(0xFFFFFFFF),
    cardBgColor: Color(0xFF231F32), // From PlurColors.cardBackground
    dimmedColor: Color(0xFF63518E), // Secondary text color
    feedBgColor: Color(0xFF191B27), // Same as app background
    loginBgColor: Color(0xFF191B27),
    navBgColor: Color(0xFF231F32), // Same as card background
    notesBgColor: Color(0xFF231F32),
    primaryForegroundColor: Color(0xFFB5A0E1), // Primary text color
    secondaryForegroundColor: Color(0xFF63518E), // Secondary text color
    separatorColor: Color(0xFF362E4E), // From PlurColors.separator
    tabsBgColor: Color(0xFF231F32),
    tooltipText: Color(0xFFECE2FD), // Highlight text color
    tooltipBackground: Color(0xFF362E4E),
  );

  /// Copy with optional overrides
  @override
  CustomColors copyWith({
    Color? accentColor,
    Color? appBgColor,
    Color? buttonTextColor,
    Color? cardBgColor,
    Color? dimmedColor,
    Color? feedBgColor,
    Color? loginBgColor,
    Color? navBgColor,
    Color? notesBgColor,
    Color? primaryForegroundColor,
    Color? secondaryForegroundColor,
    Color? separatorColor,
    Color? tabsBgColor,
    Color? tooltipText,
    Color? tooltipBackground,
  }) {
    return CustomColors(
      accentColor: accentColor ?? this.accentColor,
      appBgColor: appBgColor ?? this.appBgColor,
      buttonTextColor: buttonTextColor ?? this.buttonTextColor,
      cardBgColor: cardBgColor ?? this.cardBgColor,
      dimmedColor: dimmedColor ?? this.dimmedColor,
      feedBgColor: feedBgColor ?? this.feedBgColor,
      loginBgColor: loginBgColor ?? this.loginBgColor,
      navBgColor: navBgColor ?? this.navBgColor,
      notesBgColor: notesBgColor ?? this.notesBgColor,
      primaryForegroundColor:
          primaryForegroundColor ?? this.primaryForegroundColor,
      secondaryForegroundColor:
          secondaryForegroundColor ?? this.secondaryForegroundColor,
      separatorColor: separatorColor ?? this.separatorColor,
      tabsBgColor: tabsBgColor ?? this.tabsBgColor,
      tooltipText: tooltipText ?? this.tooltipText,
      tooltipBackground: tooltipBackground ?? this.tooltipBackground,
    );
  }

  /// Lerp for smooth color transitions
  @override
  ThemeExtension<CustomColors> lerp(
      ThemeExtension<CustomColors>? other, double t) {
    if (other is! CustomColors) {
      return this;
    }
    return CustomColors(
      accentColor: Color.lerp(accentColor, other.accentColor, t) ?? accentColor,
      appBgColor: Color.lerp(appBgColor, other.appBgColor, t) ?? appBgColor,
      buttonTextColor: Color.lerp(buttonTextColor, other.buttonTextColor, t) ??
          buttonTextColor,
      cardBgColor: Color.lerp(cardBgColor, other.cardBgColor, t) ?? cardBgColor,
      dimmedColor: Color.lerp(dimmedColor, other.dimmedColor, t) ?? dimmedColor,
      feedBgColor: Color.lerp(feedBgColor, other.feedBgColor, t) ?? feedBgColor,
      loginBgColor:
          Color.lerp(loginBgColor, other.loginBgColor, t) ?? loginBgColor,
      navBgColor: Color.lerp(navBgColor, other.navBgColor, t) ?? navBgColor,
      notesBgColor:
          Color.lerp(notesBgColor, other.notesBgColor, t) ?? notesBgColor,
      primaryForegroundColor:
          Color.lerp(primaryForegroundColor, other.primaryForegroundColor, t) ??
              primaryForegroundColor,
      secondaryForegroundColor: Color.lerp(
              secondaryForegroundColor, other.secondaryForegroundColor, t) ??
          secondaryForegroundColor,
      separatorColor:
          Color.lerp(separatorColor, other.separatorColor, t) ?? separatorColor,
      tabsBgColor: Color.lerp(tabsBgColor, other.tabsBgColor, t) ?? tabsBgColor,
      tooltipText: Color.lerp(tooltipText, other.tooltipText, t) ?? tooltipText,
      tooltipBackground:
          Color.lerp(tooltipBackground, other.tooltipBackground, t) ??
              tooltipBackground,
    );
  }
}

extension CustomThemeColors on ThemeData {
  CustomColors get customColors {
    return extension<CustomColors>() ?? CustomColors.light;
  }
}
