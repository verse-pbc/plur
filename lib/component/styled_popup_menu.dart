import 'package:flutter/material.dart';
import 'package:nostrmo/util/theme_util.dart';

/// Configuration for a popup menu item.
///
/// Each item consists of:
/// - [value]: Unique identifier for the item
/// - [text]: Display text shown to the user
/// - [icon]: Icon displayed on the right side
class StyledPopupItem {
  final String value;
  final String text;
  final IconData icon;

  const StyledPopupItem({
    required this.value,
    required this.text,
    required this.icon,
  });
}

/// A themed popup menu with dividers that appears on tap with a consistent style.
///
/// - Configurable menu items via [items]
/// - Handles selection through [onSelected] callback
class StyledPopupMenu extends StatelessWidget {
  /// List of items to show in the popup menu
  final List<StyledPopupItem> items;
  final void Function(String) onSelected;

  const StyledPopupMenu({
    super.key,
    required this.items,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: PopupMenuButton<String>(
        color: themeData.customColors.feedBgColor,
        offset: const Offset(0, 40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        icon: Icon(
          Icons.more_horiz,
          size: 30,
          color: themeData.customColors.dimmedColor,
        ),
        itemBuilder: (context) => [
          for (var i = 0; i < items.length; i++) ...[
            PopupMenuItem<String>(
              height: 40,
              value: items[i].value,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(items[i].text, style: themeData.textTheme.bodyMedium!),
                  Icon(items[i].icon,
                      size: 20,
                      color: themeData.customColors.primaryForegroundColor),
                ],
              ),
            ),
            if (i < items.length - 1) const PopupMenuDivider(height: 1),
          ],
        ],
        onSelected: onSelected,
      ),
    );
  }
}
