#!/bin/bash

# Ultra-simple approach to fix macOS build issues by removing cryptography_flutter
echo "Fixing macOS build with cryptography_flutter removal..."

# Make sure GeneratedPluginRegistrant.swift exists and is writable
if [ ! -f "macos/Flutter/GeneratedPluginRegistrant.swift" ]; then
  echo "GeneratedPluginRegistrant.swift does not exist, running flutter pub get to generate it..."
  flutter pub get
fi

# Make it writable
chmod +w macos/Flutter/GeneratedPluginRegistrant.swift

# Remove cryptography_flutter references using sed
echo "Removing cryptography_flutter references..."
sed -i '' '/import cryptography_flutter/d' macos/Flutter/GeneratedPluginRegistrant.swift
sed -i '' '/CryptographyFlutterPlugin/d' macos/Flutter/GeneratedPluginRegistrant.swift

echo "Fixed GeneratedPluginRegistrant.swift!"
echo ""
echo "Now run 'flutter build macos' to build your app."
echo "If you need to rebuild, run this script again before building."