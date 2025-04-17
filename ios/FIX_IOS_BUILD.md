# iOS Build Fix Guide

The iOS build issues are related to CocoaPods and deployment target compatibility. Follow these steps to fix them:

## 1. Update your Ruby environment

You need to use a newer version of Ruby with rbenv. Make sure you have rbenv installed:

```bash
brew install rbenv ruby-build
```

Then install Ruby 3.0+ (current latest is 3.2.2):

```bash
rbenv install 3.2.2
rbenv global 3.2.2  # or use local for this project only
```

## 2. Update your Podfile

Replace your Podfile with the improved version:

```ruby
# Uncomment this line to define a global platform for your project
platform :ios, '15.5'

# CocoaPods analytics sends network stats synchronously affecting flutter build latency.
ENV['COCOAPODS_DISABLE_STATS'] = 'true'

# Use git source instead of CDN due to connection issues
source 'https://github.com/CocoaPods/Specs.git'

project 'Runner', {
  'Debug-Runner-Staging' => :debug,
  'Debug' => :debug,
  'Profile' => :release,
  'Release' => :release,
  'Release-Runner-Staging' => :release,
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
  
  # Explicitly add Firebase dependencies
  pod 'Firebase/Core'
  pod 'Firebase/Messaging'
  
  # Just install all the pods
  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    
    # Fix deployment target issues
    target.build_configurations.each do |config|
      # Add preprocessor macros to disable Sentry
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= ['$(inherited)']
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << 'SENTRY_DISABLED=1'
      
      # Set minimum deployment target to 15.5 for all pods
      if config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'].to_f < 15.5
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.5'
      end
      
      # For Xcode 16+ compatibility
      if config.build_settings['MACOSX_DEPLOYMENT_TARGET'].to_f < 10.15
        config.build_settings['MACOSX_DEPLOYMENT_TARGET'] = '10.15'
      end
      
      # Explicitly set the build active architecture only for debug
      config.build_settings['ENABLE_BITCODE'] = 'NO'
      config.build_settings["EXCLUDED_ARCHS[sdk=iphonesimulator*]"] = "arm64"
    end
  end
  
  # For Xcode 15+ compatibility
  installer.pods_project.build_configurations.each do |config|
    config.build_settings["DEAD_CODE_STRIPPING"] = "YES"
  end
end
```

## 3. Update Flutter configuration files

Edit the following files to ensure proper CocoaPods integration:

### ios/Flutter/Debug.xcconfig

```
#include "Pods/Target Support Files/Pods-Runner/Pods-Runner.debug.xcconfig"
#include "Generated.xcconfig"
```

### ios/Flutter/Release.xcconfig

```
#include "Pods/Target Support Files/Pods-Runner/Pods-Runner.release.xcconfig"
#include "Generated.xcconfig"
```

### ios/Flutter/Staging.xcconfig

```
#include "Pods/Target Support Files/Pods-Runner/Pods-Runner.debug-runner-staging.xcconfig"
#include "Generated.xcconfig"

PRODUCT_BUNDLE_IDENTIFIER = app.verse.prototype.plur-staging
```

## 4. Clean and rebuild

Run these commands in order:

```bash
# Make sure rbenv is active
eval "$(rbenv init -)"

# Clean up everything
cd /path/to/plur
flutter clean

# Get Flutter dependencies
flutter pub get

# Set up Ruby with Bundler
cd ios
echo "source 'https://rubygems.org'" > Gemfile
echo "gem 'cocoapods', '~> 1.12.1'" >> Gemfile
bundle install

# Install pods with the proper Ruby environment
rm -rf Pods .symlinks Podfile.lock
bundle exec pod install

# Build
cd ..
flutter build ios --release
```

## 5. For CI/CD (Fastlane)

Update the fastlane configuration to use the right Ruby/CocoaPods environment:

1. Set the Xcode version using `xcversion` action
2. Set the Ruby version using rbenv in the CI environment
3. Ensure all CocoaPods commands use bundler: `bundle exec pod install`