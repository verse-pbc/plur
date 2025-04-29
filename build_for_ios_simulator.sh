#!/bin/bash

# Simple script for building on iOS simulator only
echo "🚀 Preparing iOS simulator build..."

# Clean the project
echo "Step 1: Cleaning project..."
flutter clean

# Get dependencies
echo "Step 2: Getting dependencies..."
flutter pub get

# Create a very simple Podfile that works for iOS simulator
echo "Step 3: Creating simplified Podfile..."
cat << 'EOF' > ios/Podfile
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
    
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.5'
      
      # Force x86_64 for simulator and exclude arm64
      if config.build_settings['SDKROOT'] == 'iphonesimulator'
        config.build_settings['ONLY_ACTIVE_ARCH'] = 'NO'
        config.build_settings['ARCHS[sdk=iphonesimulator*]'] = 'x86_64'
        config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
      end
    end
  end
end
EOF

# Remove AppDelegate.swift imports that might cause issues
echo "Step 4: Simplifying AppDelegate.swift..."
cat << 'EOF' > ios/Runner/AppDelegate.swift
import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    // Handle Universal Links
    override func application(
        _ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([UIUserActivityRestoring]) -> Void
    ) -> Bool {
        // Check if the user activity is a web URL
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb, let url = userActivity.webpageURL {
            print("Universal Link received: \(url)")
            // Here we would process the URL, but for now just print it
            return true
        }
        return false
    }
    
    // Handle Custom URL Schemes
    override func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        print("Custom URL scheme received: \(url)")
        // Here we would process the URL, but for now just print it
        return true
    }
}
EOF

# Reinstall pods
echo "Step 5: Reinstalling pods..."
cd ios
rm -rf Pods
rm -f Podfile.lock
pod install

echo "✅ Setup complete!"
echo "Now try running on the simulator:"
echo "flutter run -d 'iPhone 16 Plus'"