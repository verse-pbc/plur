#!/bin/bash

# Fix permissions by changing ownership without deleting files
echo "🔐 Fixing permissions by changing ownership to $(whoami)..."

# Get current user
CURRENT_USER=$(whoami)

# Fix permissions on Flutter directory and GeneratedPluginRegistrant.swift
echo "🔧 Changing ownership of macos directory to $CURRENT_USER..."
if [ -d "macos" ]; then
  chown -R $CURRENT_USER macos
  chmod -R u+w macos
  echo "✅ Ownership changed successfully"
else
  echo "❌ macos directory not found"
fi

# Now try to build
echo "🏗️ Building macOS app..."
flutter config --enable-macos-desktop
flutter build macos --debug --no-tree-shake-icons