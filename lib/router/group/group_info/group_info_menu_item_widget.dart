import 'package:flutter/material.dart';
import 'package:nostrmo/theme/app_colors.dart';

/// Displays a menu item in the group info screen with leading icon and improved styling.
class GroupInfoMenuItemWidget extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final IconData? icon;
  final IconData? trailingIcon;
  final Color? textColor;
  final Color? iconColor;

  const GroupInfoMenuItemWidget({
    super.key,
    required this.title,
    required this.onTap,
    this.icon,
    this.trailingIcon = Icons.chevron_right,
    this.textColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final effectiveTextColor = textColor ?? context.colors.primaryText;
    final effectiveIconColor = iconColor ?? context.colors.accent;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            // Leading icon
            if (icon != null) ...[
              Icon(
                icon,
                size: 24,
                color: effectiveIconColor,
              ),
              const SizedBox(width: 16),
            ],
            
            // Title
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: effectiveTextColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            
            // Trailing icon
            if (trailingIcon != null)
              Icon(
                trailingIcon,
                size: 20,
                color: context.colors.dimmed,
              ),
          ],
        ),
      ),
    );
  }
}
