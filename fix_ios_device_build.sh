#!/bin/bash

# Fix iOS device build issues
echo "🛠️ iOS Device Build Fix 🛠️"
echo "-------------------------"

# Clean everything
echo "Step 1: Cleaning project and derived data..."
flutter clean
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# Get dependencies
echo "Step 2: Getting dependencies..."
flutter pub get

# Update Podfile with physical device settings
echo "Step 3: Updating Podfile with proper iOS device settings..."
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
    
    # Settings for physical devices and simulator
    target.build_configurations.each do |config|
      # Set deployment target to 15.5 for all configurations
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.5'
      
      # For physical device, use default architecture settings
      if config.build_settings['SDKROOT'] == 'iphoneos'
        config.build_settings['ARCHS'] = 'arm64'
      end
      
      # For simulator, force x86_64 and exclude arm64
      if config.build_settings['SDKROOT'] == 'iphonesimulator'
        config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
        config.build_settings['ARCHS[sdk=iphonesimulator*]'] = 'x86_64'
      end
      
      # Add permissions definitions
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '$(inherited)',
        'PERMISSION_CAMERA=1',
        'PERMISSION_PHOTOS=1',
        'PERMISSION_MICROPHONE=1',
        'PERMISSION_NOTIFICATIONS=1'
      ]
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

echo "✅ Setup complete!"
echo ""
echo "Now build the app for a physical device with:"
echo "flutter build ios --no-codesign"
echo ""
echo "Or to run on a connected device:"
echo "flutter run"
echo ""
echo "If you have a wireless device, connect to it first:"
echo "flutter devices"
echo "flutter run -d <device_id>"
echo ""
echo "For App Store deployment, use Xcode for final signing and distribution."