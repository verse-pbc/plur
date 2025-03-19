import 'package:flutter/material.dart';

class LongFormSection extends StatelessWidget {
  final Widget titleWidget;
  final Widget imageWidget;
  final Widget summaryWidget;

  const LongFormSection({
    super.key,
    required this.titleWidget,
    required this.imageWidget,
    required this.summaryWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        titleWidget,
        imageWidget,
        summaryWidget,
      ],
    );
  }
}
