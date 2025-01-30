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
        .withOpacity(0.2);
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
  final Color loginBgColor;
  final Color navBgColor;
  final Color notesBgColor;
  final Color primaryForegroundColor;
  final Color secondaryForegroundColor;
  final Color separatorColor;
  final Color tabsBgColor;
  final Color tooltipText;
  final Color tooltipBackground;

  /// Light theme values
  static const CustomColors light = CustomColors(
    accentColor: Color(0xFFFF5F44),
    appBgColor: Color(0xFFFDF6F5),
    buttonTextColor: Color(0xFFFFFFFF),
    cardBgColor: Color(0xFFFFFFFF),
    dimmedColor: Color(0xFFA68782),
    loginBgColor: Color(0xFFFDF6F5),
    navBgColor: Color(0xFFFFFFFF),
    notesBgColor: Color(0xFFFFFFFF),
    primaryForegroundColor: Color(0xFF594946),
    secondaryForegroundColor: Color(0xFFA68782),
    separatorColor: Color(0xFFF2E7E6),
    tabsBgColor: Color(0xFFFFFFFF),
    tooltipText: Color(0xFFF5EFF7),
    tooltipBackground: Color(0xFF594946),
  );

  /// Dark theme values
  static const CustomColors dark = CustomColors(
    accentColor: Color(0xFFFF5F44),
    appBgColor: Color(0xFF160F24),
    buttonTextColor: Color(0xFFFFFFFF),
    cardBgColor: Color(0xFF160F24),
    dimmedColor: Color(0xFF8D7EAB),
    loginBgColor: Color(0xFF160F24),
    navBgColor: Color(0xFF160F24),
    notesBgColor: Color(0xFF160F24),
    primaryForegroundColor: Color(0xFFFFFFFF),
    secondaryForegroundColor: Color(0xFF8D7EAB),
    separatorColor: Color(0xFF2A1F3F),
    tabsBgColor: Color(0xFF160F24),
    tooltipText: Color(0xFFFFFFFF),
    tooltipBackground: Color(0xFF8D7EAB),
  );

  /// Copy with optional overrides
  @override
  CustomColors copyWith({
    Color? accentColor,
    Color? appBgColor,
    Color? buttonTextColor,
    Color? cardBgColor,
    Color? dimmedColor,
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
