import 'package:flutter/material.dart';
import '../util/theme_util.dart';

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

  @override
  Size get preferredSize => const Size.fromHeight(1.0);
}
