#import "SentryFlutterPlugin.h"

@implementation SentryFlutterPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    // This is an empty stub implementation that does nothing
    // It's used to replace the real Sentry implementation
    // to avoid iOS build issues with iOS 18.4 and Xcode 16.3+
    NSLog(@"SentryFlutterPlugin stub implementation - Sentry is disabled");
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    // Return success for all method calls to prevent crashes
    result(nil);
}

@end
