#!/bin/bash
set -e

# Script to build Android debug APK for testing

echo "Building Android APK for testing..."
flutter build apk --debug

echo "Build completed!"
echo "Debug APK location: build/app/outputs/apk/debug/app-debug.apk"
echo ""
echo "To install on a connected device, run:"
echo "flutter install"