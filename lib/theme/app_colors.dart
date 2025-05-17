import 'package:flutter/material.dart';

/// Core color palette - These are the base colors used throughout the app
abstract class AppColorPalette {
  // Brand colors
  static const Color primaryPurple = Color(0xFF7445FE);
  static const Color accentTeal = Color(0xFF009994);
  
  // Dark mode base colors
  static const Color darkBackground = Color(0xFF161E27); // Updated to match login
  static const Color darkSurface = Color(0xFF161E27); // Updated to match login
  static const Color darkSurfaceVariant = Color(0xFF1C242D); // Slightly lighter
  static const Color darkDivider = Color(0xFF27193D);
  
  // Light mode base colors
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF5F2FF);
  static const Color lightDivider = Color(0xFFE5DBFF);
  
  // Text colors
  static const Color darkPrimaryText = Color(0xFFB6A0E1);
  static const Color darkSecondaryText = Color(0xFF93A5B7);
  static const Color darkHighlightText = Color(0xFFECE2FD);
  
  static const Color lightPrimaryText = Color(0xFF4B3997);
  static const Color lightSecondaryText = Color(0xFF837AA0);
  static const Color lightHighlightText = Color(0xFF231F32);
  
  // Neutral colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  
  // Additional colors from the original system
  static const Color dimmedDark = Color(0xFF27193D);
  static const Color dimmedLight = Color(0xFF837AA0);
  static const Color disabledDark = Color(0xFF514A66);
  static const Color disabledLight = Color(0xFFA7A7A7);
}

/// Semantic color scheme for the app
class AppColors extends ThemeExtension<AppColors> {
  final Color primary;
  final Color accent;
  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color divider;
  final Color primaryText;
  final Color secondaryText;
  final Color highlightText;
  final Color error;
  final Color success;
  final Color warning;
  final Color loginBackground;
  final Color cardBackground;
  final Color navBackground;
  final Color feedBackground;
  final Color notesBackground;
  final Color tabsBackground;
  final Color dimmed;
  final Color disabled;
  final Color tooltipText;
  final Color tooltipBackground;
  final Color buttonText;
  final Color modalBackground;
  final Color titleText;
  
  const AppColors._({
    required this.primary,
    required this.accent,
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.divider,
    required this.primaryText,
    required this.secondaryText,
    required this.highlightText,
    required this.error,
    required this.success,
    required this.warning,
    required this.loginBackground,
    required this.cardBackground,
    required this.navBackground,
    required this.feedBackground,
    required this.notesBackground,
    required this.tabsBackground,
    required this.dimmed,
    required this.disabled,
    required this.tooltipText,
    required this.tooltipBackground,
    required this.buttonText,
    required this.modalBackground,
    required this.titleText,
  });
  
  /// Light theme colors
  static const AppColors light = AppColors._(
    primary: AppColorPalette.primaryPurple,
    accent: AppColorPalette.accentTeal,
    background: AppColorPalette.lightBackground,
    surface: AppColorPalette.lightSurface,
    surfaceVariant: AppColorPalette.lightSurface,
    divider: AppColorPalette.lightDivider,
    primaryText: AppColorPalette.lightPrimaryText,
    secondaryText: AppColorPalette.lightSecondaryText,
    highlightText: AppColorPalette.lightHighlightText,
    error: Color(0xFFD32F2F),
    success: Color(0xFF388E3C),
    warning: Color(0xFFF57C00),
    loginBackground: AppColorPalette.lightBackground,
    cardBackground: AppColorPalette.lightSurface,
    navBackground: AppColorPalette.lightBackground,
    feedBackground: AppColorPalette.lightBackground,
    notesBackground: AppColorPalette.lightSurface,
    tabsBackground: AppColorPalette.lightBackground,
    dimmed: AppColorPalette.dimmedLight,
    disabled: AppColorPalette.disabledLight,
    tooltipText: AppColorPalette.white,
    tooltipBackground: AppColorPalette.primaryPurple,
    buttonText: AppColorPalette.white,
    modalBackground: AppColorPalette.lightBackground,
    titleText: Color(0xFF161E27),
  );
  
  /// Dark theme colors
  static const AppColors dark = AppColors._(
    primary: AppColorPalette.primaryPurple,
    accent: AppColorPalette.accentTeal,
    background: Color(0xFF161E27), // Using login background as default
    surface: AppColorPalette.darkSurface,
    surfaceVariant: AppColorPalette.darkSurfaceVariant,
    divider: AppColorPalette.darkDivider,
    primaryText: AppColorPalette.darkPrimaryText,
    secondaryText: AppColorPalette.darkSecondaryText,
    highlightText: AppColorPalette.darkHighlightText,
    error: Color(0xFFFF5252),
    success: Color(0xFF66BB6A),
    warning: Color(0xFFFFA726),
    loginBackground: Color(0xFF161E27), // Custom dark login background
    cardBackground: AppColorPalette.darkSurface,
    navBackground: AppColorPalette.darkSurface,
    feedBackground: Color(0xFF161E27), // Using login background
    notesBackground: AppColorPalette.darkSurface,
    tabsBackground: AppColorPalette.darkSurface,
    dimmed: AppColorPalette.dimmedDark,
    disabled: AppColorPalette.disabledDark,
    tooltipText: AppColorPalette.darkHighlightText,
    tooltipBackground: AppColorPalette.darkDivider,
    buttonText: AppColorPalette.white,
    modalBackground: Color(0xFF161E27), // Using login background
    titleText: AppColorPalette.white,
  );
  
  @override
  ThemeExtension<AppColors> copyWith({
    Color? primary,
    Color? accent,
    Color? background,
    Color? surface,
    Color? surfaceVariant,
    Color? divider,
    Color? primaryText,
    Color? secondaryText,
    Color? highlightText,
    Color? error,
    Color? success,
    Color? warning,
    Color? loginBackground,
    Color? cardBackground,
    Color? navBackground,
    Color? feedBackground,
    Color? notesBackground,
    Color? tabsBackground,
    Color? dimmed,
    Color? disabled,
    Color? tooltipText,
    Color? tooltipBackground,
    Color? buttonText,
    Color? modalBackground,
    Color? titleText,
  }) {
    return AppColors._(
      primary: primary ?? this.primary,
      accent: accent ?? this.accent,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      divider: divider ?? this.divider,
      primaryText: primaryText ?? this.primaryText,
      secondaryText: secondaryText ?? this.secondaryText,
      highlightText: highlightText ?? this.highlightText,
      error: error ?? this.error,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      loginBackground: loginBackground ?? this.loginBackground,
      cardBackground: cardBackground ?? this.cardBackground,
      navBackground: navBackground ?? this.navBackground,
      feedBackground: feedBackground ?? this.feedBackground,
      notesBackground: notesBackground ?? this.notesBackground,
      tabsBackground: tabsBackground ?? this.tabsBackground,
      dimmed: dimmed ?? this.dimmed,
      disabled: disabled ?? this.disabled,
      tooltipText: tooltipText ?? this.tooltipText,
      tooltipBackground: tooltipBackground ?? this.tooltipBackground,
      buttonText: buttonText ?? this.buttonText,
      modalBackground: modalBackground ?? this.modalBackground,
      titleText: titleText ?? this.titleText,
    );
  }
  
  @override
  ThemeExtension<AppColors> lerp(covariant ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) {
      return this;
    }
    return AppColors._(
      primary: Color.lerp(primary, other.primary, t) ?? primary,
      accent: Color.lerp(accent, other.accent, t) ?? accent,
      background: Color.lerp(background, other.background, t) ?? background,
      surface: Color.lerp(surface, other.surface, t) ?? surface,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t) ?? surfaceVariant,
      divider: Color.lerp(divider, other.divider, t) ?? divider,
      primaryText: Color.lerp(primaryText, other.primaryText, t) ?? primaryText,
      secondaryText: Color.lerp(secondaryText, other.secondaryText, t) ?? secondaryText,
      highlightText: Color.lerp(highlightText, other.highlightText, t) ?? highlightText,
      error: Color.lerp(error, other.error, t) ?? error,
      success: Color.lerp(success, other.success, t) ?? success,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      loginBackground: Color.lerp(loginBackground, other.loginBackground, t) ?? loginBackground,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t) ?? cardBackground,
      navBackground: Color.lerp(navBackground, other.navBackground, t) ?? navBackground,
      feedBackground: Color.lerp(feedBackground, other.feedBackground, t) ?? feedBackground,
      notesBackground: Color.lerp(notesBackground, other.notesBackground, t) ?? notesBackground,
      tabsBackground: Color.lerp(tabsBackground, other.tabsBackground, t) ?? tabsBackground,
      dimmed: Color.lerp(dimmed, other.dimmed, t) ?? dimmed,
      disabled: Color.lerp(disabled, other.disabled, t) ?? disabled,
      tooltipText: Color.lerp(tooltipText, other.tooltipText, t) ?? tooltipText,
      tooltipBackground: Color.lerp(tooltipBackground, other.tooltipBackground, t) ?? tooltipBackground,
      buttonText: Color.lerp(buttonText, other.buttonText, t) ?? buttonText,
      modalBackground: Color.lerp(modalBackground, other.modalBackground, t) ?? modalBackground,
      titleText: Color.lerp(titleText, other.titleText, t) ?? titleText,
    );
  }
}

/// Extension for easy access to colors
extension AppColorsExtension on BuildContext {
  AppColors get colors {
    return Theme.of(this).extension<AppColors>() ?? AppColors.light;
  }
  
  // Convenience getters
  Color get primaryColor => colors.primary;
  Color get accentColor => colors.accent;
  Color get backgroundColor => colors.background;
  Color get surfaceColor => colors.surface;
  Color get primaryTextColor => colors.primaryText;
  Color get secondaryTextColor => colors.secondaryText;
  Color get highlightTextColor => colors.highlightText;
  Color get dividerColor => colors.divider;
  Color get errorColor => colors.error;
  Color get successColor => colors.success;
  Color get warningColor => colors.warning;
}