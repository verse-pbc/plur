import 'package:flutter/material.dart';
import 'package:nostrmo/util/theme_util.dart';

/// Displays a menu item in the group info screen.
class GroupInfoMenuItemWidget extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final IconData? trailingIcon;

  const GroupInfoMenuItemWidget({
    super.key,
    required this.title,
    required this.onTap,
    this.trailingIcon = Icons.chevron_right,
  });

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: themeData.textTheme.bodyLarge,
            ),
            if (trailingIcon != null)
              Icon(
                trailingIcon,
                size: 20,
                color: themeData.customColors.dimmedColor,
              ),
          ],
        ),
      ),
    );
  }
}
