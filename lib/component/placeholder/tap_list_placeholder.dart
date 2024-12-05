import 'dart:math';

import 'package:flutter/material.dart';
import 'package:nostrmo/component/placeholder/tap_placeholder.dart';

class TapListPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    var hintColor = themeData.hintColor;

    var random = Random();
    double width = 40;

    List<Widget> list = [];
    for (var i = 0; i < 60; i++) {
      var rndWidth = random.nextDouble() * width + 20;
      list.add(TapPlaceholder(width: rndWidth, color: hintColor));
    }

    return Container(
      color: themeData.cardColor,
      child: Center(
        child: Wrap(
          spacing: 14,
          runSpacing: 14,
          alignment: WrapAlignment.center,
          children: list,
        ),
      ),
    );
  }
}
