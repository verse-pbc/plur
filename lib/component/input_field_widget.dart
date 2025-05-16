import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
    // If isDarkMode is not provided, determine it from the context
    final inDarkMode = isDarkMode ?? Theme.of(context).brightness == Brightness.dark;
    
    // Get colors from theme
    final colors = context.colors;
    final fillColor = colors.surface;
    final borderColor = colors.divider;
    final hintColor = colors.secondaryText;
    final textColor = colors.primaryText;
    
    return SizedBox(
      height: 48,
      child: TextField(
        controller: controller,
        key: textFieldKey,
        decoration: InputDecoration(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          hintText: hintText,
          hintStyle: GoogleFonts.nunito(
            textStyle: TextStyle(
              color: hintColor,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
          filled: true,
          fillColor: fillColor,
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: borderColor,
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
        style: GoogleFonts.nunito(
          textStyle: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
