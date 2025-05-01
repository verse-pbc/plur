#!/bin/bash

# This script fixes the GeneratedPluginRegistrant.swift file after builds
echo "Applying post-build fixes..."

# Make sure GeneratedPluginRegistrant.swift is writable
chmod +w macos/Flutter/GeneratedPluginRegistrant.swift

# Remove cryptography_flutter from GeneratedPluginRegistrant.swift
sed -i '' '/import cryptography_flutter/d' macos/Flutter/GeneratedPluginRegistrant.swift
sed -i '' '/CryptographyFlutterPlugin/d' macos/Flutter/GeneratedPluginRegistrant.swift

echo "Post-build fixes applied."
