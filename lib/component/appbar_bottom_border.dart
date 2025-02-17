import 'package:flutter/material.dart';
import '../util/theme_util.dart';

/// A widget that adds a bottom border to an AppBar.
///
/// It creates a 1-pixel border that automatically uses
/// the theme's separator color. It's designed to be used in the AppBar's
/// bottom property.
///
/// Example:
/// ```dart
/// AppBar(
///   bottom: AppBarBottomBorder(),
///   title: Text('App Title'),
/// )
/// ```
class AppBarBottomBorder extends StatelessWidget
    implements PreferredSizeWidget {
  const AppBarBottomBorder({super.key});

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: themeData.customColors.separatorColor,
            width: 1.0,
          ),
        ),
      ),
    );
  }

  /// Defines a constant height of 1.0 pixels for the border.
  @override
  Size get preferredSize => const Size.fromHeight(1.0);
}
