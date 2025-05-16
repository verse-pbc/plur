# Color System Consolidation Plan

## Overview
This document outlines the plan to consolidate all color variables into a single, maintainable file that properly supports light and dark mode theming in the Plur app.

## Current State Analysis
The app currently has colors scattered across multiple files:
- `lib/util/theme_util.dart` - Contains `CustomColors` theme extension with light/dark variants
- `lib/consts/plur_colors.dart` - Contains static color definitions and theme-aware getters
- `lib/consts/colors.dart` - Contains color lists used for themes
- Main theme definitions in `lib/main.dart`

## Proposed Architecture

### 1. Single Color System File: `lib/theme/app_colors.dart`

This file will contain:
- All color constants
- Light and dark mode color schemes
- Semantic color getters
- A unified color system that's easy to maintain

```dart
// lib/theme/app_colors.dart
import 'package:flutter/material.dart';

/// Core color palette - These are the base colors used throughout the app
abstract class AppColorPalette {
  // Brand colors
  static const Color primaryPurple = Color(0xFF7445FE);
  static const Color accentOrange = Color(0xFFFF5F44);
  
  // Dark mode base colors
  static const Color darkBackground = Color(0xFF150F23);
  static const Color darkSurface = Color(0xFF190F28);
  static const Color darkSurfaceVariant = Color(0xFF231F32);
  static const Color darkDivider = Color(0xFF27193D);
  
  // Light mode base colors
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF5F2FF);
  static const Color lightDivider = Color(0xFFE5DBFF);
  
  // Text colors
  static const Color darkPrimaryText = Color(0xFFB6A0E1);
  static const Color darkSecondaryText = Color(0xFF6352BE);
  static const Color darkHighlightText = Color(0xFFECE2FD);
  
  static const Color lightPrimaryText = Color(0xFF4B3997);
  static const Color lightSecondaryText = Color(0xFF837AA0);
  static const Color lightHighlightText = Color(0xFF231F32);
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
  });
  
  /// Light theme colors
  static const AppColors light = AppColors._(
    primary: AppColorPalette.primaryPurple,
    accent: AppColorPalette.primaryPurple,
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
  );
  
  /// Dark theme colors
  static const AppColors dark = AppColors._(
    primary: AppColorPalette.primaryPurple,
    accent: AppColorPalette.accentOrange,
    background: AppColorPalette.darkBackground,
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
  );
  
  @override
  ThemeExtension<AppColors> copyWith({/* implementation */}) {...}
  
  @override
  ThemeExtension<AppColors> lerp(ThemeExtension<AppColors>? other, double t) {...}
}

/// Extension for easy access to colors
extension AppColorsExtension on BuildContext {
  AppColors get colors {
    return Theme.of(this).extension<AppColors>() ?? AppColors.light;
  }
  
  // Convenience getters
  Color get primaryColor => colors.primary;
  Color get backgroundColor => colors.background;
  Color get surfaceColor => colors.surface;
  Color get primaryTextColor => colors.primaryText;
  Color get secondaryTextColor => colors.secondaryText;
}
```

### 2. Theme Configuration File: `lib/theme/app_theme.dart`

```dart
// lib/theme/app_theme.dart
class AppTheme {
  static ThemeData lightTheme({required double fontSize}) {
    return ThemeData(
      extensions: const [AppColors.light],
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.light.primary,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.light.background,
      // ... other theme properties
    );
  }
  
  static ThemeData darkTheme({required double fontSize}) {
    return ThemeData(
      extensions: const [AppColors.dark],
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.dark.primary,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: AppColors.dark.background,
      // ... other theme properties
    );
  }
}
```

## Implementation Checklist

### Phase 1: Create New Color System
- [ ] Create directory `lib/theme/`
- [ ] Create `lib/theme/app_colors.dart` with complete color system
- [ ] Document each color with its purpose
- [ ] Implement `ThemeExtension` interface properly
- [ ] Add `copyWith` and `lerp` methods for smooth theme transitions

### Phase 2: Create Theme Configuration
- [ ] Create `lib/theme/app_theme.dart`
- [ ] Implement `lightTheme` method
- [ ] Implement `darkTheme` method
- [ ] Configure all Material theme properties
- [ ] Test theme generation

### Phase 3: Migration
- [ ] Update `main.dart` to use new theme system
- [ ] Replace `Theme.of(context).customColors` with `context.colors`
- [ ] Update all widgets using `PlurColors` to use new system
- [ ] Update all widgets using `CustomColors` to use new system
- [ ] Update all hardcoded colors to use theme colors
- [ ] Remove color references from `theme_util.dart`
- [ ] Remove color references from `plur_colors.dart`
- [ ] Remove color references from `colors.dart`

### Phase 4: Testing and Verification
- [ ] Test theme switching between light and dark modes
- [ ] Verify all screens render correctly in light mode
- [ ] Verify all screens render correctly in dark mode
- [ ] Check color contrast for accessibility
- [ ] Test on different screen sizes
- [ ] Verify no hardcoded colors remain

### Phase 5: Cleanup
- [ ] Remove old color files (`plur_colors.dart`, `colors.dart`)
- [ ] Update `theme_util.dart` to only contain utility functions
- [ ] Update documentation
- [ ] Create color usage guide for developers

## Benefits

1. **Single Source of Truth**: All colors defined in one location
2. **Type Safety**: ThemeExtension provides compile-time safety
3. **Easy Maintenance**: Adding/modifying colors is straightforward
4. **Better DX**: Simple `context.colors.primary` syntax
5. **Proper Theme Support**: Automatic switching between themes
6. **Documentation**: Clear naming and purpose for each color
7. **Consistency**: Enforced color usage across the app

## Migration Examples

### Before:
```dart
// Old way
color: PlurColors.primaryText
color: Theme.of(context).customColors.primaryForegroundColor
color: ColorList.allColor[0]
```

### After:
```dart
// New way
color: context.colors.primaryText
color: context.primaryTextColor  // convenience getter
```

## Notes

- The new system should maintain all existing color values to ensure visual consistency
- Special attention needed for the dark mode login background color (`#161E27`)
- Consider adding more semantic colors (error, success, warning) for better UX
- Future enhancement: Add color variants (primary.light, primary.dark) if needed

## Resources

- [Flutter ThemeExtensions Documentation](https://api.flutter.dev/flutter/material/ThemeExtension-class.html)
- [Material Design Color System](https://m3.material.io/styles/color/overview)
- Current color documentation in `doc/screenshots/colors_right.png`