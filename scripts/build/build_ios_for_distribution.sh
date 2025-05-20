#!/bin/bash

# Define important variables
APP_NAME="Holis"
OUTPUT_DIR="$HOME/Desktop/$APP_NAME-$(date +%Y%m%d)"

# Define build number paths 
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VERSION_FILE="${PROJECT_ROOT}/ios/build_number.txt"

# Ensure the build number file exists, initialize with 11 if it doesn't
if [[ ! -f "$VERSION_FILE" ]]; then
  mkdir -p "$(dirname "$VERSION_FILE")"
  echo "11" > "$VERSION_FILE"
  echo "Initialized build number to 11"
fi

# Get current build number and increment it
if [[ -f "$VERSION_FILE" ]]; then
  CURRENT_BUILD_NUMBER=$(cat "$VERSION_FILE")
  # Make sure it's a valid number
  if ! [[ "$CURRENT_BUILD_NUMBER" =~ ^[0-9]+$ ]]; then
    echo "Invalid build number in $VERSION_FILE. Setting to 11."
    CURRENT_BUILD_NUMBER=11
  fi
else
  CURRENT_BUILD_NUMBER=11
  echo "Build number file not found. Starting from 11."
fi

NEXT_BUILD_NUMBER=$((CURRENT_BUILD_NUMBER + 1))

# Store the new build number
echo "$NEXT_BUILD_NUMBER" > "$VERSION_FILE"

echo "===== Building $APP_NAME for App Store Distribution ====="
echo "Previous Build Number: $CURRENT_BUILD_NUMBER"
echo "New Build Number: $NEXT_BUILD_NUMBER"

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Clean Flutter project
echo "Cleaning Flutter project..."
flutter clean

echo "Getting dependencies..."
flutter pub get

# Simple build approach
echo "Building iOS app with build number $NEXT_BUILD_NUMBER..."
cd "$PROJECT_ROOT"

# Build the Flutter app with the build number
echo "Building Flutter app..."
flutter build ios --release --build-number="$NEXT_BUILD_NUMBER"

echo "Archive and IPA generation complete."
echo "Build number incremented from $CURRENT_BUILD_NUMBER to $NEXT_BUILD_NUMBER"
echo ""
echo "Use Xcode to open the workspace and create an archive for App Store submission:"
echo "1. Open Xcode"
echo "2. Open $PROJECT_ROOT/ios/Runner.xcworkspace"
echo "3. Select Product > Archive"
echo "4. Once archive is complete, click 'Distribute App' and follow the prompts"

echo "===== Build complete ====="
echo "IPA file created at: $OUTPUT_DIR/$APP_NAME-$NEXT_BUILD_NUMBER.ipa"
echo "Build number incremented from $CURRENT_BUILD_NUMBER to $NEXT_BUILD_NUMBER"
echo ""
echo "Use Transporter or Application Loader to upload your app to the App Store."