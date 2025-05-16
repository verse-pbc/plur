/// Utilities for managing application theming.
///
/// This file contains utility methods for theme-related operations.
/// The color system has been moved to lib/theme/app_colors.dart
import 'package:flutter/material.dart';

class ThemeUtil {
  /// Gets the color for dialog overlays/covers based on the current theme
  static Color getDialogCoverColor(ThemeData themeData) {
    return (themeData.textTheme.bodyMedium!.color ?? Colors.black)
        .withAlpha(51);
  }
}