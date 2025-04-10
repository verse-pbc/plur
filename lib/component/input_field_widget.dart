import 'package:flutter/material.dart';
import '../util/theme_util.dart';

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
    final themeData = Theme.of(context);

    return SizedBox(
      height: 37,
      child: TextField(
        controller: controller,
        key: textFieldKey,
        decoration: InputDecoration(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          hintText: hintText,
          hintStyle: TextStyle(
            color: themeData.customColors.dimmedColor,
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: themeData.customColors.dimmedColor,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: themeData.customColors.dimmedColor,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        style: TextStyle(
          color: themeData.customColors.primaryForegroundColor,
          fontSize: 16,
        ),
      ),
    );
  }
}
