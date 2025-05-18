import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData lightTheme({required double fontSize}) {
    const colors = AppColors.light;
    
    final textTheme = _createTextTheme(
      baseFontSize: fontSize,
      foregroundColor: colors.primaryText,
    );
    
    return ThemeData(
      extensions: const [AppColors.light],
      brightness: Brightness.light,
      primaryColor: colors.primary,
      scaffoldBackgroundColor: colors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: colors.primary,
        brightness: Brightness.light,
        error: colors.error,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.navBackground,
        foregroundColor: colors.primaryText,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: 'SF Pro Rounded',
          color: colors.primaryText,
          fontSize: fontSize + 4,
          fontWeight: FontWeight.bold,
          height: 1.2,
        ),
      ),
      dividerColor: colors.divider,
      dividerTheme: DividerThemeData(
        color: colors.divider,
        thickness: 1,
      ),
      cardColor: colors.cardBackground,
      cardTheme: CardThemeData(
        color: colors.cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      textTheme: textTheme,
      hintColor: colors.dimmed,
      shadowColor: Colors.black.withAlpha((255 * 0.1).round()),
      tabBarTheme: TabBarThemeData(
        labelColor: colors.primary,
        unselectedLabelColor: colors.secondaryText,
        indicatorColor: colors.primary,
      ),
      iconTheme: IconThemeData(
        color: colors.primaryText,
        size: 24,
      ),
      // Override primary icon theme to ensure proper font
      primaryIconTheme: IconThemeData(
        color: colors.primaryText,
        size: 24,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.buttonText,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
        filled: true,
        fillColor: colors.surface,
        hintStyle: TextStyle(
          fontFamily: 'SF Pro Rounded',
          
          color: colors.secondaryText,
        ),
      ),
    );
  }
  
  static ThemeData darkTheme({required double fontSize}) {
    const colors = AppColors.dark;
    
    final textTheme = _createTextTheme(
      baseFontSize: fontSize,
      foregroundColor: colors.primaryText,
    );
    
    return ThemeData(
      extensions: const [AppColors.dark],
      brightness: Brightness.dark,
      primaryColor: colors.primary,
      scaffoldBackgroundColor: colors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: colors.primary,
        brightness: Brightness.dark,
        error: colors.error,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.navBackground,
        foregroundColor: colors.primaryText,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: 'SF Pro Rounded',
          color: colors.primaryText,
          fontSize: fontSize + 4,
          fontWeight: FontWeight.bold,
          height: 1.2,
        ),
      ),
      dividerColor: colors.divider,
      dividerTheme: DividerThemeData(
        color: colors.divider,
        thickness: 1,
      ),
      cardColor: colors.cardBackground,
      cardTheme: CardThemeData(
        color: colors.cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      textTheme: textTheme,
      hintColor: colors.dimmed,
      shadowColor: Colors.white.withAlpha((255 * 0.1).round()),
      tabBarTheme: TabBarThemeData(
        labelColor: colors.accent,
        unselectedLabelColor: colors.secondaryText,
        indicatorColor: colors.accent,
      ),
      canvasColor: colors.feedBackground,
      iconTheme: IconThemeData(
        color: colors.primaryText,
        size: 24,
      ),
      // Override primary icon theme to ensure proper font
      primaryIconTheme: IconThemeData(
        color: colors.primaryText,
        size: 24,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.accent,
          foregroundColor: colors.buttonText,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors.accent, width: 2),
        ),
        filled: true,
        fillColor: colors.surface,
        hintStyle: TextStyle(
          fontFamily: 'SF Pro Rounded',
          
          color: colors.secondaryText,
        ),
      ),
    );
  }
  
  static TextTheme _createTextTheme({
    required double baseFontSize,
    required Color foregroundColor,
  }) {
    return TextTheme(
      displayLarge: TextStyle(
        fontFamily: 'SF Pro Rounded',
        fontSize: baseFontSize + 12,
        fontWeight: FontWeight.bold,
        color: foregroundColor,
        height: 1.2,
      ),
      displayMedium: TextStyle(
        fontFamily: 'SF Pro Rounded',
        
        fontSize: baseFontSize + 8,
        fontWeight: FontWeight.bold,
        color: foregroundColor,
        height: 1.2,
      ),
      displaySmall: TextStyle(
        fontFamily: 'SF Pro Rounded',
        
        fontSize: baseFontSize + 6,
        fontWeight: FontWeight.bold,
        color: foregroundColor,
        height: 1.2,
      ),
      headlineLarge: TextStyle(
        fontFamily: 'SF Pro Rounded',
        
        fontSize: baseFontSize + 6,
        fontWeight: FontWeight.bold,
        color: foregroundColor,
        height: 1.2,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'SF Pro Rounded',
        
        fontSize: baseFontSize + 4,
        fontWeight: FontWeight.bold,
        color: foregroundColor,
        height: 1.2,
      ),
      headlineSmall: TextStyle(
        fontFamily: 'SF Pro Rounded',
        
        fontSize: baseFontSize + 2,
        fontWeight: FontWeight.bold,
        color: foregroundColor,
        height: 1.2,
      ),
      titleLarge: TextStyle(
        fontFamily: 'SF Pro Rounded',
        
        fontSize: baseFontSize + 4,
        fontWeight: FontWeight.bold,
        color: foregroundColor,
        height: 1.2,
      ),
      titleMedium: TextStyle(
        fontFamily: 'SF Pro Rounded',
        
        fontSize: baseFontSize + 2,
        fontWeight: FontWeight.bold,
        color: foregroundColor,
        height: 1.2,
      ),
      titleSmall: TextStyle(
        fontFamily: 'SF Pro Rounded',
        
        fontSize: baseFontSize,
        fontWeight: FontWeight.bold,
        color: foregroundColor,
        height: 1.2,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'SF Pro Rounded',
        
        fontSize: baseFontSize + 2,
        color: foregroundColor,
        height: 1.4,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'SF Pro Rounded',
        
        fontSize: baseFontSize,
        color: foregroundColor,
        height: 1.4,
      ),
      bodySmall: TextStyle(
        fontFamily: 'SF Pro Rounded',
        
        fontSize: baseFontSize - 2,
        color: foregroundColor,
        height: 1.4,
      ),
      labelLarge: TextStyle(
        fontFamily: 'SF Pro Rounded',
        
        fontSize: baseFontSize,
        fontWeight: FontWeight.w500,
        color: foregroundColor,
        height: 1.4,
      ),
      labelMedium: TextStyle(
        fontFamily: 'SF Pro Rounded',
        
        fontSize: baseFontSize - 1,
        fontWeight: FontWeight.w500,
        color: foregroundColor,
        height: 1.4,
      ),
      labelSmall: TextStyle(
        fontFamily: 'SF Pro Rounded',
        
        fontSize: baseFontSize - 2,
        fontWeight: FontWeight.w500,
        color: foregroundColor,
        height: 1.4,
      ),
    );
  }
}