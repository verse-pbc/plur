import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../consts/plur_colors.dart';

/// Custom input field that is used to take input from the user.
class InputFieldWidget extends StatelessWidget {
  /// The hint text to display when the input field is empty.
  final String? hintText;

  /// The controller for the input field.
  final TextEditingController controller;

  /// The key for the input field.
  final Key? textFieldKey;

  const InputFieldWidget({
    super.key,
    this.hintText,
    required this.controller,
    this.textFieldKey = const Key('input'),
  });

  @override
  Widget build(BuildContext context) {
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
            textStyle: const TextStyle(
              color: PlurColors.secondaryText,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
          filled: true,
          fillColor: PlurColors.primaryDark,
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(
              color: PlurColors.separator,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(
              color: PlurColors.primaryPurple,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        cursorColor: PlurColors.primaryPurple,
        style: GoogleFonts.nunito(
          textStyle: const TextStyle(
            color: PlurColors.primaryText,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
