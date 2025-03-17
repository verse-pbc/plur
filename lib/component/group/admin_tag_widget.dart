import 'package:flutter/material.dart';
import 'package:nostrmo/util/theme_util.dart';

class AdminTagWidget extends StatelessWidget {
  const AdminTagWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: themeData.customColors.feedBgColor,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(
        'Admin',
        style: TextStyle(
          fontSize: 12,
          color: themeData.customColors.dimmedColor,
        ),
      ),
    );
  }
}
