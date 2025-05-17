import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Custom input field that is used to take input from the user.
class InputFieldWidget extends StatelessWidget {
  /// The hint text to display when the input field is empty.
  final String? hintText;

  /// The controller for the input field.
  final TextEditingController controller;

  /// The key for the input field.
  final Key? textFieldKey;
  
  /// Whether the app is in dark mode.
  final bool? isDarkMode;

  const InputFieldWidget({
    super.key,
    this.hintText,
    required this.controller,
    this.textFieldKey = const Key('input'),
    this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    // Get colors from the theme
    final colors = context.colors;
    
    // If isDarkMode is not provided, determine it from the context
    final inDarkMode = isDarkMode ?? Theme.of(context).brightness == Brightness.dark;
    
    return SizedBox(
      height: 48,
      child: TextField(
        controller: controller,
        key: textFieldKey,
        decoration: InputDecoration(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          hintText: hintText,
          hintStyle: TextStyle(
            fontFamily: 'SF Pro Rounded',
            color: colors.secondaryText,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
          filled: true,
          fillColor: inDarkMode 
              ? colors.surfaceVariant 
              : colors.surface,
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: colors.divider,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: colors.primary,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        cursorColor: colors.primary,
        style: TextStyle(
          fontFamily: 'SF Pro Rounded',
          color: colors.primaryText,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}