#!/bin/bash

# Fix iOS simulator architecture issues
echo "🛠️ iOS Simulator Architecture Fix 🛠️"
echo "------------------------------------"

# Clean everything
echo "Step 1: Cleaning project and derived data..."
flutter clean
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# Get dependencies
echo "Step 2: Getting dependencies..."
flutter pub get

# Update Podfile with explicit architecture settings for simulators
echo "Step 3: Updating Podfile with proper simulator architecture settings..."
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
  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    
    # Force x86_64 architecture for simulators on Apple Silicon Macs
    target.build_configurations.each do |config|
      # Set deployment target to 15.5 for all configurations
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.5'
      
      # Fix simulator architectures - CRITICAL PART
      if config.build_settings['SDKROOT'] == 'iphonesimulator'
        # For simulators on Apple Silicon Macs, force x86_64
        # This is necessary because Apple Silicon Macs (arm64) are trying to build for arm64 simulators,
        # but the libraries like libswiftWebKit.dylib are only available for x86_64 simulators
        config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
        config.build_settings['ONLY_ACTIVE_ARCH'] = 'NO'
        config.build_settings['ARCHS[sdk=iphonesimulator*]'] = 'x86_64'
      end
    end
  end
end
EOF

# Clean and reinstall pods
echo "Step 4: Reinstalling pods with new configuration..."
cd ios
rm -rf Pods
rm -f Podfile.lock
pod install --repo-update

# Create a xcconfig file to force the simulator to use x86_64
echo "Step 5: Creating custom xcconfig for simulator architecture..."
cat << 'EOF' > Flutter/simulator_archs.xcconfig
EXCLUDED_ARCHS[sdk=iphonesimulator*] = arm64
ONLY_ACTIVE_ARCH = NO
ARCHS[sdk=iphonesimulator*] = x86_64
VALID_ARCHS = x86_64
EOF

# Update Debug.xcconfig to include our custom config
echo "Step 6: Updating Debug.xcconfig to include simulator architecture settings..."
echo "#include \"simulator_archs.xcconfig\"" >> Flutter/Debug.xcconfig

echo "✅ Setup complete!"
echo ""
echo "Now run the app on the simulator with:"
echo "flutter run --no-sound-null-safety -d 'iPhone 16 Plus'"
echo ""
echo "If it still fails, open Xcode and manually update the build settings:"
echo "1. open ios/Runner.xcworkspace"
echo "2. Select the Runner project, then click Build Settings"
echo "3. Search for 'Architecture'"
echo "4. For the Debug-iphonesimulator configuration, make sure 'Excluded Architectures' includes 'arm64'"
echo "5. Rebuild the app"