import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A styled input field with hover and focus effects
/// based on the design of the Login with Nostr sheet.
///
/// Features:
/// - Dynamic border color on hover and focus
/// - Dark background
/// - Consistent styling across the app
/// - Optional eye icon for password fields
class StyledInputFieldWidget extends StatefulWidget {
  /// The controller for the input field
  final TextEditingController controller;

  /// The hint text to display when the input field is empty
  final String? hintText;

  /// Whether to obscure the text (for password fields)
  final bool obscureText;

  /// Called when the text changes
  final ValueChanged<String>? onChanged;

  /// Called when the user submits the input field
  final ValueChanged<String>? onSubmitted;

  /// Whether to auto-focus this input field
  final bool autofocus;

  /// Focus node for controlling focus
  final FocusNode? focusNode;

  /// Key for testing
  final Key? fieldKey;

  /// Optional prefix icon
  final Widget? prefixIcon;

  /// Optional suffix icon (only shown when not a password field)
  final Widget? suffixIcon;

  /// Optional callback to toggle password visibility
  final VoidCallback? onToggleObscure;

  const StyledInputFieldWidget({
    super.key,
    required this.controller,
    this.hintText,
    this.obscureText = false,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.focusNode,
    this.fieldKey,
    this.prefixIcon,
    this.suffixIcon,
    this.onToggleObscure,
  });

  @override
  State<StyledInputFieldWidget> createState() => _StyledInputFieldWidgetState();
}

class _StyledInputFieldWidgetState extends State<StyledInputFieldWidget> {
  bool _isHovered = false;
  bool _isFocused = false;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      // Only dispose the focus node if we created it
      _focusNode.removeListener(_onFocusChange);
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accentColor = colors.accent;
    final secondaryTextColor = colors.secondaryText;

    // Determine border color based on state
    Color borderColor = _isFocused || _isHovered 
        ? accentColor
        : const Color(0xFF2E4052);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: borderColor,
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: TextField(
            key: widget.fieldKey,
            controller: widget.controller,
            focusNode: _focusNode,
            autofocus: widget.autofocus,
            obscureText: widget.obscureText,
            style: const TextStyle(
              fontFamily: 'SF Pro Rounded',
              color: Colors.white,
              fontSize: 16,
            ),
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF11171F),
              hintText: widget.hintText,
              hintStyle: TextStyle(
                fontFamily: 'SF Pro Rounded',
                color: secondaryTextColor,
                fontSize: 16,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              hoverColor: Colors.transparent,
              contentPadding: const EdgeInsets.all(16),
              prefixIcon: widget.prefixIcon,
              suffixIcon: widget.obscureText && widget.onToggleObscure != null
                ? IconButton(
                    icon: Icon(
                      widget.obscureText ? Icons.visibility : Icons.visibility_off,
                      color: secondaryTextColor,
                    ),
                    onPressed: widget.onToggleObscure,
                    hoverColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                  )
                : widget.suffixIcon,
            ),
          ),
        ),
      ),
    );
  }
}