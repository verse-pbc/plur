#!/bin/bash
# Run this script before building for macOS to prevent cryptography_flutter issues

echo "Applying pre-build fixes for macOS..."
chmod +w macos/Flutter/GeneratedPluginRegistrant.swift
sed -i '' '/import cryptography_flutter/d' macos/Flutter/GeneratedPluginRegistrant.swift
sed -i '' '/CryptographyFlutterPlugin/d' macos/Flutter/GeneratedPluginRegistrant.swift
echo "Fixed! Now run 'flutter build macos'"
