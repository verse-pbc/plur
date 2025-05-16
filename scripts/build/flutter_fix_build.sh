#!/bin/bash
set -e

# Attempt to build the app with specific Flutter optimization settings
# that can work around some common issues

echo "Running optimized Flutter build for Android..."

# Step 1: Clean the build environment
echo "Cleaning Flutter build..."
flutter clean

# Step 2: Get dependencies
echo "Getting dependencies..."
flutter pub get

# Step 3: Set local.properties for release mode
echo "Setting up build configuration..."
echo "flutter.buildMode=release" > android/local.properties.tmp
echo "flutter.versionName=0.1.2" >> android/local.properties.tmp
echo "sdk.dir=$ANDROID_SDK_ROOT" >> android/local.properties.tmp
echo "flutter.sdk=/opt/homebrew/Caskroom/flutter/3.27.4/flutter" >> android/local.properties.tmp
mv android/local.properties.tmp android/local.properties

# Step 4: Build with specific flags to avoid common issues
echo "Building APK..."
flutter build apk --release \
  --no-tree-shake-icons \
  --no-pub \
  --target-platform=android-arm64 \
  --split-debug-info=build/app/outputs/symbols

echo ""
echo "Build completed!"
echo "APK location: build/app/outputs/flutter-apk/app-release.apk"