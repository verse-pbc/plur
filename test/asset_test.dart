import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Test asset loading', (WidgetTester tester) async {
    // Build our app and trigger a frame
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              Image.asset(
                'assets/imgs/landing/logo.png',
                width: 100,
                height: 100,
              ),
              Image.asset(
                'assets/imgs/welcome_groups.png',
                width: 100,
                height: 100,
              ),
              Image.asset(
                'assets/imgs/cashu_logo.png',
                width: 100,
                height: 100,
              ),
              Image.asset(
                'assets/imgs/alby_logo.png',
                width: 100,
                height: 100,
              ),
              Image.asset(
                'assets/imgs/logo/logo512.png',
                width: 100,
                height: 100,
              ),
              Image.asset(
                'assets/imgs/music/wavlake.png',
                width: 100,
                height: 100,
              ),
            ],
          ),
        ),
      ),
    );

    // Verify images load without errors
    expect(find.byType(Image), findsNWidgets(6));
  });
}