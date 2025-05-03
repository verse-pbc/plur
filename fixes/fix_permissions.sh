#!/bin/bash

# Fix permissions and build for macOS
echo "🔑 Fixing macOS permissions and building..."

# Delete GeneratedPluginRegistrant.swift if it exists (it will be regenerated)
rm -f macos/Flutter/GeneratedPluginRegistrant.swift

# Make sure Flutter directory exists with correct permissions
mkdir -p macos/Flutter
chmod -R 755 macos/Flutter

# Make Flutter directory writeable
echo "👩‍💻 Making Flutter directory writeable..."
chmod -R +w macos/Flutter

# Get dependencies to regenerate files
echo "📦 Getting dependencies..."
flutter pub get

# Build macOS app
echo "🏗️ Building macOS app..."
flutter config --enable-macos-desktop
flutter build macos --debug --no-tree-shake-icons