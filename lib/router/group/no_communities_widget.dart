import 'package:flutter/material.dart';
import 'package:nostrmo/util/theme_util.dart';

class NoCommunitiesWidget extends StatelessWidget {
  const NoCommunitiesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    return SingleChildScrollView(
      child: Container(
        margin: const EdgeInsets.all(80.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                themeData.customColors.dimmedColor,
                BlendMode.srcIn,
              ),
              child: Image.asset("assets/imgs/welcome_groups.png"),
            ),
            const SizedBox(height: 18),
            Text(
              'Not seeing your community here?\n\nLocate your invite link, and tap on it again.',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 18.0,
                fontWeight: FontWeight.w500,
                color: themeData.customColors.primaryForegroundColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
