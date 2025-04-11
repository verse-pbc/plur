// Empty stub for iOS/macOS that doesn't import Sentry
// This file is loaded on iOS/macOS platforms

// Define fallback functions that do nothing
Future<void> initSentry(void Function() appRunner) async {
  // Just run the app directly without Sentry
  appRunner();
}

class SentryStub {
  static const bool isSentryAvailable = false;
}

// Export the stub to be used in place of real Sentry
export 'sentry_stub.dart';