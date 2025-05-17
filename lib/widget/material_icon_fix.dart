import 'package:flutter/material.dart';

/// A wrapper for Icon widget that fixes the alignment issues with Material Icons
/// in some Flutter versions.
class FixedIcon extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final double? size;
  final String? semanticLabel;
  final TextDirection? textDirection;
  final List<Shadow>? shadows;

  const FixedIcon(
    this.icon, {
    Key? key,
    this.color,
    this.size,
    this.semanticLabel,
    this.textDirection,
    this.shadows,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      color: color,
      size: size,
      semanticLabel: semanticLabel,
      textDirection: textDirection,
      shadows: shadows,
    );
  }
}