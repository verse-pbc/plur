#!/bin/bash

# Prepare app for App Store submission
echo "📱 Preparing App for App Store Submission 📱"
echo "------------------------------------------"

# Get app version from pubspec.yaml
VERSION=$(grep "version:" pubspec.yaml | awk '{print $2}' | tr -d ' ')
echo "App version from pubspec: $VERSION"

# Ask for confirmation to continue
read -p "Continue preparing app version $VERSION for App Store? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo "Operation cancelled."
    exit 1
fi

# Step 1: Clean the project
echo "Step 1: Cleaning project..."
flutter clean
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# Step 2: Get dependencies
echo "Step 2: Getting dependencies..."
flutter pub get

# Step 3: Update Podfile for production build
echo "Step 3: Configuring Podfile for production build..."
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
    
    # Production build settings
    target.build_configurations.each do |config|
      # Set deployment target to 15.5 for all configurations
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.5'
      
      # Add permissions definitions
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '$(inherited)',
        'PERMISSION_CAMERA=1',
        'PERMISSION_PHOTOS=1',
        'PERMISSION_MICROPHONE=1',
        'PERMISSION_NOTIFICATIONS=1'
      ]
      
      # Optimize for production (this can be removed if it causes issues)
      if config.name == 'Release'
        config.build_settings['COMPILER_INDEX_STORE_ENABLE'] = 'NO'
        config.build_settings['GCC_OPTIMIZATION_LEVEL'] = 's'
      end
    end
  end
end
EOF

# Step 4: Reinstall pods
echo "Step 4: Reinstalling pods..."
cd ios
rm -rf Pods
rm -f Podfile.lock
pod install --repo-update
cd ..

# Step 5: Double-check App Store configuration
echo "Step 5: Checking App Store configuration..."
echo "App ID: 6744957029"
echo "Bundle ID: app.verse.prototype.plur"

echo "Step 6: Build the archive..."
echo ""
echo "✅ Setup complete! Now open Xcode to create an archive for App Store submission:"
echo ""
echo "1. Open the project in Xcode:"
echo "   open ios/Runner.xcworkspace"
echo ""
echo "2. Select 'Any iOS Device (arm64)' as the build target"
echo ""
echo "3. Set the build configuration to 'Release'"
echo ""
echo "4. Go to Product > Archive to create an archive"
echo ""
echo "5. After archiving completes, use the Xcode Organizer to upload to App Store Connect"