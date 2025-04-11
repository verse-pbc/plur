import 'package:flutter/material.dart';

class EventBitcoinIconWidget extends StatelessWidget {
  const EventBitcoinIconWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          width: 8,
          color: Colors.amber[600]!.withAlpha(128),
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(54),
      ),
      child: Icon(
        Icons.currency_bitcoin,
        color: Colors.amber[600]!.withAlpha(128),
        size: 100,
      ),
    );
  }

  static Widget wrapper(Widget child) {
    return Stack(
      children: [
        child,
        const Positioned(
          top: -35,
          right: -10,
          child: EventBitcoinIconWidget(),
        ),
      ],
    );
  }
}
