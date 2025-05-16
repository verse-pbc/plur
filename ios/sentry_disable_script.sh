#!/bin/bash

# This script creates a completely empty Sentry implementation for iOS builds

# Create necessary directories
mkdir -p ios/Pods/sentry_flutter/ios/Classes

# Create Sentry implementations
cat > ios/Pods/sentry_flutter/ios/Classes/SentryFlutterPlugin.h << EOF
#import <Flutter/Flutter.h>

@interface SentryFlutterPlugin : NSObject<FlutterPlugin>
@end
EOF

cat > ios/Pods/sentry_flutter/ios/Classes/SentryFlutterPlugin.m << EOF
#import "SentryFlutterPlugin.h"

@implementation SentryFlutterPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  // Do nothing - Sentry is disabled
}

@end
EOF

# Create the umbrella header
mkdir -p ios/Pods/Headers/Public/sentry_flutter

cat > ios/Pods/Headers/Public/sentry_flutter/SentryFlutterPlugin.h << EOF
#ifndef SentryFlutterPlugin_h
#define SentryFlutterPlugin_h

#import <Flutter/Flutter.h>

@interface SentryFlutterPlugin : NSObject<FlutterPlugin>
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar;
@end

#endif /* SentryFlutterPlugin_h */
EOF

cat > ios/Pods/Headers/Public/sentry_flutter/sentry_flutter-umbrella.h << EOF
#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "SentryFlutterPlugin.h"

FOUNDATION_EXPORT double sentry_flutterVersionNumber;
FOUNDATION_EXPORT const unsigned char sentry_flutterVersionString[];
EOF

# Create stub Dart implementation
mkdir -p ios/Pods/sentry_flutter/lib

cat > ios/Pods/sentry_flutter/lib/sentry_flutter.dart << EOF
// Empty stub Sentry implementation
library sentry_flutter;

class Sentry {
  static Future<void> init(String dsn, {Map? options}) async {}
  static void captureException(dynamic throwable, {dynamic stackTrace}) {}
  static void captureMessage(String message, {dynamic level}) {}
  static Future<void> close() async {}
}

class SentryFlutter {
  static Future<void> init({required String dsn, Map? options}) async {}
}

class SentryEvent {
  SentryEvent({String? message});
}

class SentryOptions {
  String? dsn;
  bool? enabled;
}

class Breadcrumb {
  Breadcrumb({String? message, String? category, Map<String, dynamic>? data, DateTime? timestamp});
}

class SentryLevel {
  static const SentryLevel fatal = SentryLevel._('fatal');
  static const SentryLevel error = SentryLevel._('error');
  static const SentryLevel warning = SentryLevel._('warning');
  static const SentryLevel info = SentryLevel._('info');
  static const SentryLevel debug = SentryLevel._('debug');

  final String _name;
  const SentryLevel._(this._name);
}
EOF

# Also modify the main.dart to ensure Sentry is not being initialized
if grep -q "import 'package:sentry_flutter/sentry_flutter.dart';" lib/main.dart; then
  echo "Commenting out Sentry initialization in main.dart..."
  sed -i '' 's|import '"'"'package:sentry_flutter/sentry_flutter.dart'"'"';|//import '"'"'package:sentry_flutter/sentry_flutter.dart'"'"';|g' lib/main.dart
  sed -i '' 's|await SentryFlutter.init|//await SentryFlutter.init|g' lib/main.dart
fi

echo "Sentry has been completely disabled."