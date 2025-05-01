#!/bin/bash

# Script to fix GeneratedPluginRegistrant.swift for macOS

echo "Fixing GeneratedPluginRegistrant.swift..."

# Make sure the file is writable
chmod +w /Users/rabble/code/verse/plur/macos/Flutter/GeneratedPluginRegistrant.swift

# Remove the cryptography_flutter import and registration lines
sed -i '' '/import cryptography_flutter/d' /Users/rabble/code/verse/plur/macos/Flutter/GeneratedPluginRegistrant.swift
sed -i '' '/CryptographyFlutterPlugin/d' /Users/rabble/code/verse/plur/macos/Flutter/GeneratedPluginRegistrant.swift

echo "Fixed! GeneratedPluginRegistrant.swift modified."