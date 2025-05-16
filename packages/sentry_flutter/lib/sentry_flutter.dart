// Empty Sentry stub implementation
import 'package:flutter/widgets.dart';

// Stub Sentry implementation
class Sentry {
  static Future<void> init(String dsn, {dynamic options}) async {}
  static Future<SentryId> captureException(dynamic throwable, {dynamic stackTrace, dynamic hint}) async {
    return SentryId();
  }
  static Future<SentryId> captureEvent(dynamic event, {dynamic stackTrace, dynamic hint}) async {
    return SentryId();
  }
  static Future<SentryId> captureMessage(String message, {dynamic level, dynamic hint}) async {
    return SentryId();
  }
  static Future<void> close() async {}
}

class SentryId {
  final String id = "00000000000000000000000000000000";
  const SentryId();
  
  @override
  String toString() => id;
}

class SentryEvent {
  SentryEvent();
}

class SentryBreadcrumb {
  SentryBreadcrumb();
}

class SentryBreadcrumbLevel {
  static const info = SentryBreadcrumbLevel();
  const SentryBreadcrumbLevel();
}

class SentryLevel {
  static const fatal = SentryLevel._();
  static const error = SentryLevel._();
  static const warning = SentryLevel._();
  static const info = SentryLevel._();
  static const debug = SentryLevel._();
  const SentryLevel._();
}

class SentryOptions {
  SentryOptions();
  bool debug = false;
  bool enabled = false;
  String? dsn;
  List<dynamic> integrations = [];
}

class SentryFlutter {
  static Future<void> init({
    required String dsn,
    dynamic options,
  }) async {}
  
  static bool get isNativeCrashHandlingAvailable => false;
}

// Stubs for various tracing mechanisms
class SentryTracing {}
class SentrySpan {}
class SentryTransaction {}
class SentrySpanStatus {}

Future<T> SentryFlutterError<T>(Future<T> Function() callback) async {
  try {
    return await callback();
  } catch (error) {
    // Just rethrow, no Sentry
    rethrow;
  }
}

// Stub widget wrapper
Widget Function(BuildContext, Widget?) sentryTracing(Widget Function(BuildContext, Widget?) builder) {
  return builder;
}

// Exported types for compatibility
export 'sentry_flutter.dart';