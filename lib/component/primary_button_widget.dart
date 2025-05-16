import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Button used for primary actions throughout the app.
class PrimaryButtonWidget extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final bool enabled;
  final double height;
  final double borderRadius;
  
  const PrimaryButtonWidget({
    super.key,
    required this.text,
    this.onTap,
    this.enabled = true,
    this.height = 48,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        decoration: BoxDecoration(
          color: enabled ? context.colors.primary : context.colors.primary.withAlpha(128),
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: context.colors.primary.withAlpha(77),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        height: height,
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'SF Pro Rounded',
            color: enabled ? context.colors.buttonText : context.colors.buttonText.withAlpha(179),
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
