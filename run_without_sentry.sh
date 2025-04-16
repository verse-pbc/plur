#!/bin/bash

# This script runs the Flutter app with Sentry disabled
# This is the default local development mode

echo "===================================="
echo "Running Flutter app with Sentry disabled"
echo "Local development mode (default)"
echo "===================================="

# First, run flutter pub get to make sure dependencies are up-to-date
echo "Running flutter pub get..."
flutter pub get

# Run pod install (without FASTLANE_BUILD for local dev)
echo "Running pod install for local dev (Sentry will be disabled)..."
cd ios && pod install && cd ..

# Run the app
echo "Running Flutter app..."
flutter run "$@"