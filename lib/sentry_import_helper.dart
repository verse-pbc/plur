// This file is loaded on non-iOS/macOS platforms
// It imports the real Sentry package

import 'package:sentry_flutter/sentry_flutter.dart';

// Re-export Sentry to make it available to main.dart
export 'package:sentry_flutter/sentry_flutter.dart';

class SentryStub {
  static const bool isSentryAvailable = true;
}

// Function to initialize Sentry
Future<void> initSentry(void Function() appRunner) async {
  if (const bool.hasEnvironment("SENTRY_DSN")) {
    try {
      await SentryFlutter.init(
        (options) {
          // environment can also be set with SENTRY_ENVIRONMENT in our secret .env files
          options.environment = const String.fromEnvironment('ENVIRONMENT',
              defaultValue: 'production');
        },
        appRunner: appRunner,
      );
    } catch (e) {
      print("Error initializing Sentry: $e");
      appRunner();
    }
  } else {
    appRunner();
  }
}