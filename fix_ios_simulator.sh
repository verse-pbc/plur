#!/bin/bash

# Comprehensive iOS simulator build fix script
# This removes Sentry completely and fixes architecture issues

echo "🔧 Starting comprehensive iOS simulator build fix..."

# 1. Completely override sentry_flutter dependency
echo "Creating empty sentry_flutter package implementation..."
mkdir -p ios/.sentry_override/sentry_flutter
cat > ios/.sentry_override/sentry_flutter/sentry_flutter.podspec << 'EOL'
Pod::Spec.new do |s|
  s.name             = 'sentry_flutter'
  s.version          = '8.13.0'
  s.summary          = 'Empty Sentry implementation'
  s.description      = 'Empty stub implementation to avoid iOS compatibility issues'
  s.homepage         = 'https://github.com/getsentry/sentry-dart'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { 'Sentry' => 'mobile@sentry.io' }
  s.source           = { :git => 'https://github.com/getsentry/sentry-dart.git', :tag => s.version.to_s }
  s.platform         = :ios, '11.0'
  s.swift_version    = '5.0'

  # Empty source files
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/Public/*.h'
  
  # Create empty directories
  FileUtils.mkdir_p('Classes/Public') unless Dir.exist?('Classes/Public')

  # Create stub implementation file
  File.write('Classes/Public/SentryFlutterPlugin.h', <<~EOT
    #import <Flutter/Flutter.h>

    @interface SentryFlutterPlugin : NSObject<FlutterPlugin>
    + (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar;
    @end
  EOT
  )

  # Add the Flutter dependency
  s.dependency 'Flutter'
end
EOL

# Create empty LICENSE file to satisfy podspec
touch ios/.sentry_override/LICENSE

# Create the stub implementation class
mkdir -p ios/.sentry_override/sentry_flutter/Classes/Public
cat > ios/.sentry_override/sentry_flutter/Classes/Public/SentryFlutterPlugin.h << 'EOL'
#import <Flutter/Flutter.h>

@interface SentryFlutterPlugin : NSObject<FlutterPlugin>
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar;
@end
EOL

mkdir -p ios/.sentry_override/sentry_flutter/Classes
cat > ios/.sentry_override/sentry_flutter/Classes/SentryFlutterPlugin.m << 'EOL'
#import "Public/SentryFlutterPlugin.h"

@implementation SentryFlutterPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    // Empty implementation
}

@end
EOL

# 2. Modify the Podfile to use our empty Sentry implementation
echo "Updating Podfile to use our stub Sentry implementation..."
cat > ios/Podfile << 'EOL'
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

  # Skip Sentry pods completely during installation
  flutter_install_all_ios_pods(File.dirname(File.realpath(__FILE__))) do |pod_name|
    # Skip any Sentry-related pods
    if pod_name.start_with?('Sentry') || pod_name.start_with?('sentry')
      # Replace with our stub implementation
      pod 'sentry_flutter', :path => '.sentry_override/sentry_flutter'
      false
    else
      true
    end
  end
end

post_install do |installer|
  # Set up the Pods properly
  installer.pods_project.targets.each do |target|
    # Add the Flutter build settings
    flutter_additional_ios_build_settings(target)
    
    # Apply additional compiler settings for all targets
    target.build_configurations.each do |config|
      # Set deployment target to 15.5 for all configurations
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.5'
      
      # Add preprocessor definitions to disable Sentry
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '$(inherited)',
        'SENTRY_DISABLED=1',
        'SENTRY_NO_EXCEPTIONS=1',
        'SENTRY_NO_INIT=1',
        'SENTRY_TARGET_PROFILING_SUPPORTED=0',
        'SENTRY_NO_THREAD_PROFILING=1'
      ]
      
      # Force x86_64 architecture for simulators on Apple Silicon Macs
      if config.build_settings['SDKROOT'] == 'iphonesimulator'
        config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
        config.build_settings['ONLY_ACTIVE_ARCH'] = 'NO'
        config.build_settings['ARCHS[sdk=iphonesimulator*]'] = 'x86_64'
        config.build_settings['VALID_ARCHS'] = 'x86_64'
      end
    end
  end
end
EOL

# 3. Make sure the simulator architectures are correctly configured
echo "Setting up proper simulator architecture configuration..."
cat > ios/Flutter/simulator_archs.xcconfig << 'EOL'
// Force x86_64 architecture for simulators on Apple Silicon Macs
EXCLUDED_ARCHS[sdk=iphonesimulator*] = arm64
ONLY_ACTIVE_ARCH = NO
ARCHS[sdk=iphonesimulator*] = x86_64
VALID_ARCHS = x86_64
EOL

# 4. Replace the GeneratedPluginRegistrant.m file with a fixed version
echo "Creating modified GeneratedPluginRegistrant.m without Sentry imports..."
cp ios/Runner/GeneratedPluginRegistrant.m ios/Runner/GeneratedPluginRegistrant.m.bak

# Remove Sentry from GeneratedPluginRegistrant.m by replacing it with a no-op
sed -i.bak '/sentry_flutter\/SentryFlutterPlugin.h/,+5d' ios/Runner/GeneratedPluginRegistrant.m
sed -i.bak '/\[SentryFlutterPlugin registerWithRegistrar:/d' ios/Runner/GeneratedPluginRegistrant.m

# 5. Clean everything
echo "Cleaning Flutter project..."
cd /Users/sebastian/projects/plur
flutter clean

# 6. Get dependencies
echo "Getting Flutter dependencies..."
flutter pub get

# 7. Run pod install with special flags
echo "Installing pods..."
cd ios
pod install --no-repo-update

echo "✅ iOS simulator build fixes applied!"
echo ""
echo "Now build the app with: flutter build ios --simulator"
echo "Or run on simulator with: flutter run -d simulator"