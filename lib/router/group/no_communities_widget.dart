import 'package:flutter/material.dart';

class NoCommunitiesWidget extends StatelessWidget {
  const NoCommunitiesWidget({super.key});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.all(80.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset("assets/imgs/welcome_groups.png"),
            const SizedBox(height: 18),
            const Text(
              'Not seeing your community here?\n\nLocate your invite link, and tap on it again.',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 18.0,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
}
