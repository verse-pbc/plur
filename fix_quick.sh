#!/bin/bash

# Quick fix for macOS build issues
echo "Quick fix for macOS build..."

# Step 1: Fix the GeneratedPluginRegistrant.swift file
echo "Fixing GeneratedPluginRegistrant.swift..."
chmod +w macos/Flutter/GeneratedPluginRegistrant.swift
sed -i '' '/import cryptography_flutter/d' macos/Flutter/GeneratedPluginRegistrant.swift
sed -i '' '/CryptographyFlutterPlugin/d' macos/Flutter/GeneratedPluginRegistrant.swift

echo "Fixed! Now trying to build..."
flutter build macos --debug