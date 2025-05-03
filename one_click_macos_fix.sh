#\!/bin/bash

# One-click macOS build fix script
echo "🔧 Starting one-click macOS build fix..."

# Step 1: Create directories
mkdir -p macos/Runner/Plugins

# Step 2: Create dummy plugin implementation
echo "📝 Creating dummy plugin implementation..."
cat > macos/Runner/Plugins/CryptographyFlutterPlugin.swift << 'PLUGINEOF'
import FlutterMacOS
import Foundation

// Dummy implementation of the cryptography_flutter plugin
public class CryptographyFlutterPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    // No-op implementation for compatibility
    print("Dummy CryptographyFlutterPlugin registered for macOS")
  }
}
PLUGINEOF
chmod 644 macos/Runner/Plugins/CryptographyFlutterPlugin.swift

# Step 3: Modify Podfile to force ARM64 only
echo "📋 Updating Podfile..."
cat > macos/Podfile << 'PODEOF'
platform :osx, '10.15'

# CocoaPods analytics sends network stats synchronously affecting flutter build latency.
ENV['COCOAPODS_DISABLE_STATS'] = 'true'

# Suppress warning about not specifying the CocoaPods master specs repo
install\! 'cocoapods', :warn_for_unused_master_specs_repo => false

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
  use_frameworks\!
  use_modular_headers\!

  flutter_install_all_macos_pods File.dirname(File.realpath(__FILE__))
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_macos_build_settings(target)
    
    # Force ARM64 architecture for all build configurations
    target.build_configurations.each do |config|
      # Set architecture to ARM64 only
      config.build_settings['ARCHS'] = 'arm64'
      config.build_settings['EXCLUDED_ARCHS[sdk=macosx*]'] = 'x86_64'
      config.build_settings['ONLY_ACTIVE_ARCH'] = 'YES'
      
      # Ensure minimum macOS version is set correctly
      config.build_settings['MACOSX_DEPLOYMENT_TARGET'] = '10.15'
    end
  end
end
PODEOF

# Step 4: Clean the project
echo "🧹 Cleaning up..."
flutter clean

# Step 5: Get dependencies and install pods
echo "📦 Getting dependencies..."
flutter pub get
cd macos && pod install && cd ..

# Step 6: Set up a build command with all necessary flags
echo "🚀 Building macOS app (this may take a while)..."
flutter build macos --debug

echo "✅ Build process complete\! Check for any errors above."
