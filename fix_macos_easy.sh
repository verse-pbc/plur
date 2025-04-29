#!/bin/bash
# Simple macOS build fix script

# Make sure you have run flutter clean and flutter pub get
# before running this script

set -e

echo "🚀 Fixing macOS build with simple approach..."

# Make GeneratedPluginRegistrant.swift writable
chmod +w macos/Flutter/GeneratedPluginRegistrant.swift

# Edit GeneratedPluginRegistrant.swift to remove cryptography_flutter
echo "Removing cryptography_flutter references from GeneratedPluginRegistrant.swift..."
sed -i '' '/import cryptography_flutter/d' macos/Flutter/GeneratedPluginRegistrant.swift
sed -i '' '/CryptographyFlutterPlugin/d' macos/Flutter/GeneratedPluginRegistrant.swift

# Create a dummy implementation
echo "Creating dummy plugin implementation..."
mkdir -p macos/Runner/Plugins
cat > macos/Runner/Plugins/CryptographyFlutterPlugin.swift << 'EOF'
import FlutterMacOS
import Foundation

// Dummy implementation of CryptographyFlutterPlugin
public class CryptographyFlutterPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    // No-op implementation
    print("Dummy CryptographyFlutterPlugin registered")
  }
}
EOF

# Make GeneratedPluginRegistrant.swift read-only
chmod -w macos/Flutter/GeneratedPluginRegistrant.swift

echo "✅ Fix completed! Now run: flutter build macos --no-tree-shake-icons"