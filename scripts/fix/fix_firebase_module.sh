#!/bin/bash

# Script to fix the "No such module 'FirebaseCore'" error
echo "🔄 Fixing Firebase module error..."

# Clean everything thoroughly
echo "Step 1: Complete cleanup..."
flutter clean
rm -rf ~/Library/Developer/Xcode/DerivedData/*
rm -rf ~/Library/Caches/CocoaPods/*
rm -rf ~/.cocoapods/repos/*

# Get dependencies
echo "Step 2: Getting dependencies..."
flutter pub get

# Fix Podfile to ensure Firebase modules are properly linked
echo "Step 3: Updating Podfile..."
cat << 'EOF' > ios/Podfile
# Uncomment this line to define a global platform for your project
platform :ios, '15.5'

# CocoaPods analytics sends network stats synchronously affecting flutter build latency.
ENV['COCOAPODS_DISABLE_STATS'] = 'true'
ENV['warn_for_unused_master_specs_repo'] = 'false'

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

  # Force Firebase pods to be compiled and linked
  pod 'Firebase/Core'
  pod 'Firebase/Messaging'
  
  # Then install Flutter pods
  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    
    # Force simulator to use x86_64
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.5'

      # For simulator
      if config.build_settings['SDKROOT'] == 'iphonesimulator'
        config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
        config.build_settings['ARCHS[sdk=iphonesimulator*]'] = 'x86_64'
        config.build_settings['ONLY_ACTIVE_ARCH'] = 'NO'
      end
    end
  end
end
EOF

# Reinstall pods with a clean environment
echo "Step 4: Reinstalling pods..."
cd ios
rm -rf Pods
rm -f Podfile.lock
pod deintegrate
pod setup
pod install --repo-update

echo "✅ Setup complete!"
echo "Now try running the app with: flutter run -d 'iPhone 16 Plus'"