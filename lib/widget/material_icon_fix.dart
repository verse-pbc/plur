import 'package:flutter/material.dart';

/// A wrapper widget that ensures icons use Material Icons font family
/// This fixes the issue where icons might inherit a custom font family
class MaterialIconFix extends StatelessWidget {
  final Widget child;
  
  const MaterialIconFix({
    Key? key,
    required this.child,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: const TextStyle(
        fontFamily: 'MaterialIcons',
      ),
      child: child,
    );
  }
}

/// A fixed version of the Icon widget that ensures the correct font is used
class FixedIcon extends StatelessWidget {
  final IconData icon;
  final double? size;
  final Color? color;
  final String? semanticLabel;
  final TextDirection? textDirection;
  
  const FixedIcon(
    this.icon, {
    Key? key,
    this.size,
    this.color,
    this.semanticLabel,
    this.textDirection,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontFamily: icon.fontFamily ?? 'MaterialIcons',
          fontSize: size ?? IconTheme.of(context).size ?? 24.0,
          color: color ?? IconTheme.of(context).color,
          package: icon.fontPackage,
        ),
      ),
      textDirection: textDirection ?? Directionality.of(context),
    );
  }
}