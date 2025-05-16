#!/bin/bash
set -e

# Script to build Android release app bundle with secure credentials

# Load environment variables from the secrets file
if [ -f "./secrets/android-keys.env" ]; then
  echo "Loading Android signing credentials..."
  source ./secrets/android-keys.env
else
  echo "Error: Android signing credentials not found!"
  echo "Please create ./secrets/android-keys.env with ANDROID_STORE_PASSWORD and ANDROID_KEY_PASSWORD"
  exit 1
fi

# Check if credentials are loaded
if [ -z "$ANDROID_STORE_PASSWORD" ] || [ -z "$ANDROID_KEY_PASSWORD" ]; then
  echo "Error: Android signing credentials are not properly set in the environment file."
  exit 1
fi

echo "Building Android App Bundle for release..."
flutter build appbundle --release -P storePassword="$ANDROID_STORE_PASSWORD" -P keyPassword="$ANDROID_KEY_PASSWORD"

echo "Build completed!"
echo "App Bundle location: build/app/outputs/bundle/release/app-release.aab"
echo ""
echo "Next steps:"
echo "1. Upload to Google Play Console: https://play.google.com/console/"
echo "2. Create a new release under your app"
echo "3. Upload the AAB file"