#!/bin/bash

# Simple macOS build script that avoids using sudo
# This script fixes the macOS build by handling cryptography_flutter incompatibility

echo "🚀 Starting macOS build process..."

# Navigate to project directory 
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Step 1: Make the generated plugin registrant file writable if it exists
if [ -f "macos/Flutter/GeneratedPluginRegistrant.swift" ]; then
  echo "📄 Making GeneratedPluginRegistrant.swift writable..."
  chmod u+w macos/Flutter/GeneratedPluginRegistrant.swift
fi

# Step 2: Get dependencies to trigger plugin registration generation
echo "🔄 Getting dependencies..."
flutter pub get

# Step 3: Modify GeneratedPluginRegistrant.swift to exclude cryptography_flutter 
if [ -f "macos/Flutter/GeneratedPluginRegistrant.swift" ]; then
  echo "🔧 Patching GeneratedPluginRegistrant.swift..." 
  chmod u+w macos/Flutter/GeneratedPluginRegistrant.swift
  sed -i '' '/import cryptography_flutter/d' macos/Flutter/GeneratedPluginRegistrant.swift
  sed -i '' '/CryptographyFlutterPlugin/d' macos/Flutter/GeneratedPluginRegistrant.swift
fi

# Step 4: Build macOS app with --no-tree-shake-icons to avoid regenerating files
echo "🏗️ Building macOS app..."
flutter build macos --debug --no-tree-shake-icons

echo "✅ macOS build process completed!"