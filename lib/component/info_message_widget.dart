import 'package:flutter/material.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/util/theme_util.dart';

class InfoMessageWidget extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color? iconColor;
  final Color? textColor;
  final double? iconSize;
  final double? fontSize;

  const InfoMessageWidget({
    super.key,
    required this.icon,
    required this.message,
    this.iconColor,
    this.textColor,
    this.iconSize = 16,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Base.basePadding,
        vertical: Base.basePadding / 2,
      ),
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: iconSize,
            color: iconColor ?? themeData.customColors.primaryForegroundColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: textColor ?? themeData.customColors.dimmedColor,
                fontSize: fontSize ?? themeData.textTheme.bodyMedium!.fontSize,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
