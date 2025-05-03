#!/bin/bash

# Exit on error
set -e

echo "🚀 Custom macOS Build Helper"
echo "-------------------------"

# Clean up everything
echo "🧹 Cleaning project..."
flutter clean
rm -rf macos/Pods
rm -rf macos/Podfile.lock
rm -rf macos/.symlinks
rm -rf build/macos

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Create dummy cryptography plugin
echo "🔧 Creating dummy plugin file..."
mkdir -p macos/Runner/Plugins
cat > macos/Runner/Plugins/CryptographyFlutterDummy.swift << 'EOF'
import FlutterMacOS
import Foundation

// This is a dummy implementation of the cryptography_flutter plugin
public class CryptographyFlutterDummy: NSObject {
    // No-op implementation
}
EOF

# Update the Podfile to exclude cryptography_flutter
echo "🔧 Updating Podfile..."
cat > macos/Podfile << 'EOF'
platform :osx, '10.15'

# CocoaPods analytics sends network stats synchronously affecting flutter build latency.
ENV['COCOAPODS_DISABLE_STATS'] = 'true'

project 'Runner', {
  'Debug' => :debug,
  'Profile' => :release,
  'Release' => :release,
}

def flutter_root
  generated_xcode_build_settings_path = File.expand_path(File.join('..', 'Flutter', 'ephemeral', 'Flutter-Generated.xcconfig'), __FILE__)
  unless File.exist?(generated_xcode_build_settings_path)
    raise "#{generated_xcode_build_settings_path} must exist. If you're running pod install manually, make sure \"flutter pub get\" is executed first"
  end

  File.foreach(generated_xcode_build_settings_path) do |line|
    matches = line.match(/FLUTTER_ROOT\=(.*)/)
    return matches[1].strip if matches
  end
  raise "FLUTTER_ROOT not found in #{generated_xcode_build_settings_path}. Try deleting Flutter-Generated.xcconfig, then run \"flutter pub get\""
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
    
    # Force ARM64 architecture for all build configurations
    target.build_configurations.each do |config|
      config.build_settings['ARCHS'] = 'arm64'
      config.build_settings['EXCLUDED_ARCHS[sdk=macosx*]'] = 'x86_64'
      config.build_settings['ONLY_ACTIVE_ARCH'] = 'YES'
      
      # Ensure minimum macOS version is set correctly
      config.build_settings['MACOSX_DEPLOYMENT_TARGET'] = '10.15'
    end
  end
end
EOF

# Install pods
echo "🔄 Installing pods..."
cd macos
pod install --repo-update
cd ..

# Patch GeneratedPluginRegistrant.swift if needed
echo "🔧 Patching GeneratedPluginRegistrant.swift..."
if [ -f "macos/Flutter/GeneratedPluginRegistrant.swift" ]; then
  # Make backup
  cp macos/Flutter/GeneratedPluginRegistrant.swift macos/Flutter/GeneratedPluginRegistrant.swift.bak
  
  # Comment out cryptography_flutter imports and registrations
  sed -i '' 's/import cryptography_flutter/\/\/ import cryptography_flutter/' macos/Flutter/GeneratedPluginRegistrant.swift
  sed -i '' 's/CryptographyFlutterPlugin.register/\/\/ CryptographyFlutterPlugin.register/' macos/Flutter/GeneratedPluginRegistrant.swift
  
  echo "✅ Successfully patched GeneratedPluginRegistrant.swift"
else
  echo "❌ Error: GeneratedPluginRegistrant.swift not found!"
fi

# Build macOS app
echo "🏗️ Building macOS app..."
flutter config --enable-macos-desktop
flutter build macos --debug --no-tree-shake-icons

echo "✅ macOS build process completed!"