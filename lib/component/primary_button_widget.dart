import 'package:flutter/material.dart';
import 'package:nostrmo/util/theme_util.dart';

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
    this.height = 40,
    this.borderRadius = 0,
  });

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final buttonColor = themeData.customColors.accentColor;
    final buttonTextColor = themeData.customColors.buttonTextColor;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: InkWell(
        onTap: enabled ? onTap : null,
        highlightColor: buttonColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          decoration: BoxDecoration(
            color: enabled ? buttonColor : buttonColor.withOpacity(0.4),
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          height: height,
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color:
                  enabled ? buttonTextColor : buttonTextColor.withOpacity(0.4),
            ),
          ),
        ),
      ),
    );
  }
}
