import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../consts/plur_colors.dart';

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
          color: enabled ? PlurColors.buttonBackground : PlurColors.buttonBackground.withAlpha(128),
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: PlurColors.buttonBackground.withAlpha(77),
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
          style: GoogleFonts.nunito(
            textStyle: TextStyle(
              color: enabled ? PlurColors.buttonText : PlurColors.buttonText.withAlpha(179),
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
