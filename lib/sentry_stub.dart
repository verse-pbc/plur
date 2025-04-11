// Stub implementation of Sentry to prevent compile errors on iOS/macOS
// This provides empty implementations of the Sentry classes and methods we use

class SentryFlutter {
  static Future<void> init(
    Function(dynamic options) optionsConfiguration, {
    required void Function() appRunner,
  }) async {
    // Just run the app without Sentry
    appRunner();
  }
}

class SentryOptions {
  String? environment;
}