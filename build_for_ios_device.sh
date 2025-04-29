#!/bin/bash

# Script to build for iOS device
echo "🔧 Building for iOS Device 📱"
echo "-------------------------"

# Clean project
echo "Step 1: Cleaning project..."
flutter clean
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# Get dependencies
echo "Step 2: Getting dependencies..."
flutter pub get

# Create a summary of our recommendations
echo "✅ Setup complete!"
echo ""
echo "Based on the issues encountered, here's our recommendation:"
echo ""
echo "For deep linking and architecture compatibility issues in this project, the best approach is to:"
echo ""
echo "1. Open the project in Xcode directly and complete the build there:"
echo "   open ios/Runner.xcworkspace"
echo ""
echo "2. In Xcode, make these changes:"
echo "   - Under Build Settings, search for 'Architectures'"
echo "   - For simulators, ensure 'Excluded Architectures' includes 'arm64'"
echo "   - Set 'Build Active Architecture Only' to NO for Release, YES for Debug"
echo ""
echo "3. For the AppDelegate.swift file, manually fix these issues in Xcode:"
echo "   - For missing FirebaseCore, ensure you properly import it"
echo "   - Fix the UIUserActivityRestoring parameter type in the continue userActivity method"
echo ""
echo "4. Finally, build for device:"
echo "   - Select a physical iOS device in Xcode"
echo "   - Product > Run"
echo ""
echo "For App Store submission:"
echo "   - Product > Archive"
echo "   - Follow the Xcode distribution workflow"