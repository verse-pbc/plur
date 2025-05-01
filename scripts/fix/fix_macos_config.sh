#!/bin/bash

echo "🔧 macOS Flutter Configuration Fix 🔧"
echo "----------------------------------"

# Create basic Flutter-Generated.xcconfig in the ephemeral directory
echo "Step 1: Creating placeholder Flutter-Generated.xcconfig..."
mkdir -p "macos/Flutter/ephemeral"

# Get the Flutter root directory
FLUTTER_ROOT="/opt/homebrew/Caskroom/flutter/3.27.4/flutter"
echo "Flutter root: $FLUTTER_ROOT"

# Create a basic Flutter-Generated.xcconfig
cat << EOF > "macos/Flutter/ephemeral/Flutter-Generated.xcconfig"
// This is a generated file; do not edit or check into version control.
FLUTTER_ROOT=$FLUTTER_ROOT
FLUTTER_APPLICATION_PATH=$(pwd)
COCOAPODS_PARALLEL_CODE_SIGN=true
FLUTTER_BUILD_DIR=build
FLUTTER_BUILD_NAME=1.0.0
FLUTTER_BUILD_NUMBER=1
DART_OBFUSCATION=false
TRACK_WIDGET_CREATION=true
TREE_SHAKE_ICONS=false
PACKAGE_CONFIG=.dart_tool/package_config.json
EOF

# Fix Flutter-Debug.xcconfig
echo "Step 2: Fixing Flutter-Debug.xcconfig..."
cat << EOF > "macos/Flutter/Flutter-Debug.xcconfig"
#include "ephemeral/Flutter-Generated.xcconfig"
#include "Pods/Target Support Files/Pods-Runner/Pods-Runner.debug.xcconfig"
EOF

# Fix Flutter-Release.xcconfig
echo "Step 3: Fixing Flutter-Release.xcconfig..."
cat << EOF > "macos/Flutter/Flutter-Release.xcconfig"
#include "ephemeral/Flutter-Generated.xcconfig"
#include "Pods/Target Support Files/Pods-Runner/Pods-Runner.release.xcconfig"
EOF

# Update Podfile to handle architecture issues
echo "Step 4: Updating macOS Podfile..."
cat << 'EOF' > "macos/Podfile"
platform :osx, '10.15'

# CocoaPods analytics sends network stats synchronously affecting flutter build latency.
ENV['COCOAPODS_DISABLE_STATS'] = 'true'
ENV['warn_for_unused_master_specs_repo'] = 'false'

project 'Runner', {
  'Debug' => :debug,
  'Profile' => :release,
  'Release' => :release,
}

def flutter_root
  generated_xcode_build_settings_path = File.expand_path(File.join('..', 'Flutter', 'ephemeral', 'Flutter-Generated.xcconfig'), __FILE__)
  unless File.exist?(generated_xcode_build_settings_path)
    raise "#{generated_xcode_build_settings_path} must exist. If you're running pod install manually, make sure flutter pub get is executed first"
  end

  File.foreach(generated_xcode_build_settings_path) do |line|
    matches = line.match(/FLUTTER_ROOT\=(.*)/)
    return matches[1].strip if matches
  end
  raise "FLUTTER_ROOT not found in #{generated_xcode_build_settings_path}. Try deleting Flutter-Generated.xcconfig, then run flutter pub get"
end

require File.expand_path(File.join('packages', 'flutter_tools', 'bin', 'podhelper'), flutter_root)

flutter_macos_podfile_setup

target 'Runner' do
  use_frameworks!
  use_modular_headers!

  flutter_install_all_macos_pods File.dirname(File.realpath(__FILE__))
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_macos_build_settings(target)
    
    # macOS build settings for universal binary
    target.build_configurations.each do |config|
      # Add support for both arm64 and x86_64
      config.build_settings['ARCHS'] = 'arm64 x86_64'
      config.build_settings['MACOSX_DEPLOYMENT_TARGET'] = '10.15'
      
      # Avoid architecture conflicts
      if config.name == 'Debug'
        # For local development, use both architectures to support all Macs
        config.build_settings['ONLY_ACTIVE_ARCH'] = 'NO'
      end
    end
  end
end
EOF

# Now install the pods
echo "Step 5: Installing macOS pods..."
cd macos
pod install

# Go back to the project root
cd ..

echo "✅ macOS configuration fixed successfully!"
echo ""
echo "You can now run the app on macOS with: flutter run -d macos"
echo ""
echo "If you still encounter issues, try opening and building from Xcode:"
echo "open macos/Runner.xcworkspace"