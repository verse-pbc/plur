import 'package:flutter/material.dart';

import '../../consts/base.dart';

class TapPlaceholder extends StatelessWidget {
  final Color color;

  final double width;

  const TapPlaceholder({super.key, required this.width, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 30,
      padding: const EdgeInsets.all(Base.basePaddingHalf),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}
