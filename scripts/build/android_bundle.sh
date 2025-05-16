#!/bin/bash
set -e

echo "Building Android App Bundle for Google Play..."

# Clean and get dependencies
flutter clean
flutter pub get

# Generate the app bundle
echo "Generating app bundle with optimized settings..."
flutter build appbundle \
  --release \
  --no-tree-shake-icons \
  --target-platform=android-arm64,android-arm \
  --build-number=$(date +%s)

# Show the output location
echo "Build completed successfully!"
echo "App Bundle location: build/app/outputs/bundle/release/app-release.aab"
echo "You can now upload this bundle to Google Play Console"