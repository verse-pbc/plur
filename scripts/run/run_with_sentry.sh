#!/bin/bash

# This script runs the Flutter app with Sentry enabled
# Simulating the environment of a Fastlane build

echo "===================================="
echo "Running Flutter app with Sentry enabled"
echo "Simulating CI/Fastlane build environment"
echo "===================================="

# Set the environment variable to indicate this is a Fastlane build
export FASTLANE_BUILD=true

# First, run flutter pub get to make sure dependencies are up-to-date
echo "Running flutter pub get..."
flutter pub get

# Run pod install with FASTLANE_BUILD set
echo "Running pod install with FASTLANE_BUILD=true..."
cd ios && FASTLANE_BUILD=true pod install && cd ..

# Run the app
echo "Running Flutter app..."
flutter run --dart-define=FASTLANE_BUILD=true "$@"