#!/bin/bash

echo "🔧 Final iOS Build Fix 🔧"
echo "-----------------------"

# Step 1: Get dependencies
echo "Step 1: Getting dependencies..."
flutter pub get

# Step 2: Reset CocoaPods
echo "Step 2: Installing pods with fresh configuration..."
cd ios
pod install

echo "✅ Setup completed."
echo ""
echo "Now run: flutter run -d 'iPhone 16 Plus'"
echo ""
echo "Alternatively, you can open the project in Xcode to set your architecture preferences:"
echo "open ios/Runner.xcworkspace"
echo ""
echo "For App Store submission, build the app with Xcode using Product > Archive"