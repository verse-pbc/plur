// Empty Sentry stub implementation for iOS compatibility
// This completely disables Sentry functionality while maintaining API compatibility

class SentryStub {
  static Future<void> init(Function(dynamic options) callback) async {
    print('Sentry initialization disabled');
    // Do nothing - Sentry is disabled
  }
}

// Replace real Sentry with stub in imports
class Sentry {
  static Future<void> init(Function(dynamic options) callback) async {
    print('Sentry initialization disabled');
    // Do nothing - Sentry is disabled
  }
  
  static void captureException(dynamic throwable, {dynamic stackTrace}) {
    // Do nothing - Sentry is disabled
  }

  static void captureMessage(String message, {dynamic level}) {
    // Do nothing - Sentry is disabled
  }

  static Future<void> close() async {
    // Do nothing - Sentry is disabled
  }
}

class SentryFlutter {
  static Future<void> init({required String dsn, Map<String, dynamic>? options}) async {
    print('SentryFlutter.init disabled for iOS compatibility');
    // Do nothing - Sentry is disabled
  }
}
