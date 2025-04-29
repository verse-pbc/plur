#!/bin/bash

echo "🔧 iOS Build Fixing Script 🔧"
echo "-----------------------------"

# Clean project first
echo "Step 1: Cleaning project..."
flutter clean

# Get dependencies
echo "Step 2: Getting dependencies..."
flutter pub get

# Create dummy CryptographyFlutterPlugin files
echo "Step 2.5: Creating dummy CryptographyFlutterPlugin files..."
mkdir -p ios/Runner/Plugins

# Create header file
cat > ios/Runner/Plugins/CryptographyFlutterDummy.h << 'EOF'
#import <Flutter/Flutter.h>

@interface CryptographyFlutterPlugin : NSObject<FlutterPlugin>
@end
EOF

# Create implementation file
cat > ios/Runner/Plugins/CryptographyFlutterDummy.m << 'EOF'
#import "CryptographyFlutterDummy.h"

@implementation CryptographyFlutterPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    // This is a dummy implementation that does nothing
    // It's only here to satisfy the plugin registration requirements
}

@end
EOF

# Update Podfile with proper configurations
echo "Step 3: Updating Podfile..."
cat << 'EOF' > ios/Podfile
# Uncomment this line to define a global platform for your project
platform :ios, '15.5'

# CocoaPods analytics sends network stats synchronously affecting flutter build latency.
ENV['COCOAPODS_DISABLE_STATS'] = 'true'

project 'Runner', {
  'Debug' => :debug,
  'Profile' => :release,
  'Release' => :release,
}

def flutter_root
  generated_xcode_build_settings_path = File.expand_path(File.join('..', 'Flutter', 'Generated.xcconfig'), __FILE__)
  unless File.exist?(generated_xcode_build_settings_path)
    raise "#{generated_xcode_build_settings_path} must exist. If you're running pod install manually, make sure flutter pub get is executed first"
  end

  File.foreach(generated_xcode_build_settings_path) do |line|
    matches = line.match(/FLUTTER_ROOT\=(.*)/)
    return matches[1].strip if matches
  end
  raise "FLUTTER_ROOT not found in #{generated_xcode_build_settings_path}. Try deleting Generated.xcconfig, then run flutter pub get"
end

require File.expand_path(File.join('packages', 'flutter_tools', 'bin', 'podhelper'), flutter_root)

flutter_ios_podfile_setup

target 'Runner' do
  use_frameworks!
  use_modular_headers!

  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    
    # Architecture compatibility settings
    target.build_configurations.each do |config|
      # Ensure proper deployment target
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.5'
      
      # Support both architectures for the simulator
      if config.build_settings['SDKROOT'] == 'iphonesimulator'
        config.build_settings['ARCHS'] = 'arm64 x86_64'
        config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = ''
        config.build_settings['ONLY_ACTIVE_ARCH'] = 'NO'
      end
      
      # Fix build settings that might cause issues
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '$(inherited)',
        'PERMISSION_CAMERA=1', # Add permissions needed by your app
        'PERMISSION_PHOTOS=1',
        'PERMISSION_MICROPHONE=1',
        'PERMISSION_NOTIFICATIONS=1'
      ]
    end
  end
end
EOF

# Navigate to iOS directory
echo "Step 4: Changing to iOS directory..."
cd ios

# Delete Flutter/ephemeral directory to force regeneration
echo "Step 5: Cleaning Flutter/ephemeral directory..."
rm -rf Flutter/ephemeral

# Remove Pods directory and Podfile.lock
echo "Step 6: Removing Pods directory and Podfile.lock..."
rm -rf Pods
rm -f Podfile.lock

# Install Pods
echo "Step 7: Running pod install..."
pod install --repo-update

echo "Step 8: Updating Flutter-*.xcconfig files..."
cd ..

# Generate Flutter-*.xcconfig files
flutter pub get

# Fix GeneratedPluginRegistrant.m to use our dummy implementation
echo "Step 9: Fixing GeneratedPluginRegistrant.m..."
if [ -f "ios/Runner/GeneratedPluginRegistrant.m" ]; then
  sed -i.bak 's/#if __has_include(<cryptography_flutter\/CryptographyFlutterPlugin.h>).*@import cryptography_flutter;.*#endif/\/\/ Using local dummy implementation for CryptographyFlutterPlugin\n#import "Plugins\/CryptographyFlutterDummy.h"/' ios/Runner/GeneratedPluginRegistrant.m
fi

# Reopen the Xcode project and perform recommended updates
echo "✅ Setup complete!"
echo "Now open the Runner.xcworkspace in Xcode:"
echo "open ios/Runner.xcworkspace"
echo ""
echo "In Xcode, accept the recommended project setting updates when prompted."
echo "If you still see 'No such module 'Flutter'' errors, try updating the Pods project settings in Xcode as well."
echo ""
echo "To run the app in a simulator, use:"
echo "flutter run -d 'iPhone 16 Plus'"