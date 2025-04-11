import 'package:flutter/material.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'mocks.dart';

/// A helper to create a test version of MyApp with mocked route implementations
class MockMyApp extends StatelessWidget {
  const MockMyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Define the routes with mocked implementations for Riverpod-based widgets
    final Map<String, Widget Function(BuildContext)> mockRoutes = {
      // Don't include index route since we use it as home
      RouterPath.login: (context) => const MockLoginWidget(),
      RouterPath.onboarding: (context) => const MockOnboardingWidget(),
      RouterPath.groupList: (context) => const MockCommunitiesScreen(),
      // Add other routes as needed
    };

    return MaterialApp(
      // Start at login screen for testing
      home: const MockLoginWidget(),
      routes: mockRoutes,
      initialRoute: null, // Don't set an initial route
    );
  }
}