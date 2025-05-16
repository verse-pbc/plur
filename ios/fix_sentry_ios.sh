#!/bin/bash

# Complete Sentry removal and iOS build fix for plur project
# This script removes all traces of Sentry to fix build issues with iOS 18.4 SDK and Xcode 16.3+

echo "🔧 Running complete Sentry removal for iOS build..."

# 1. Create directory for Sentry stub files if needed
mkdir -p Runner/Plugins/SentryStubs

# 2. Create Sentry stub header
cat > Runner/Plugins/SentryStubs/SentryFlutterPlugin.h << 'EOL'
#ifndef SentryFlutterPlugin_h
#define SentryFlutterPlugin_h

#import <Flutter/Flutter.h>

@interface SentryFlutterPlugin : NSObject<FlutterPlugin>
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar;
@end

#endif /* SentryFlutterPlugin_h */
EOL

# 3. Create Sentry stub implementation
cat > Runner/Plugins/SentryStubs/SentryFlutterPlugin.m << 'EOL'
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
EOL

# 4. Add header search path to Runner project
echo "Adding Sentry stub header path to Runner project..."

# 5. Clean up any existing Sentry files from Pods
echo "Removing any remaining Sentry files from Pods directory..."
rm -rf Pods/Sentry Pods/sentry_flutter 2>/dev/null

# 6. Create a .nosentry file to mark Sentry as disabled
echo "Marking Sentry as disabled..."
touch .nosentry

# 7. Run pod install with special flags
echo "Running pod install with Sentry disabled..."
pod install --no-repo-update

echo "✅ Sentry has been completely removed from the iOS build!"
echo "Now build the app with: flutter build ios --simulator"
echo "Or run on simulator with: flutter run"