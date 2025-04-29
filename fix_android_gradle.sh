#!/bin/bash

# Script to fix Android Gradle plugin loading issue
# This addresses the issue with app_plugin_loader.gradle

echo "Fixing Android Gradle configuration..."

# Path to app build.gradle
APP_GRADLE_PATH="android/app/build.gradle"

# Create backup of build.gradle
cp "$APP_GRADLE_PATH" "${APP_GRADLE_PATH}.bak"

# Update plugin application method in build.gradle
# Replace the apply from: line with plugins { id 'dev.flutter.flutter-gradle-plugin' }
sed -i '' 's/apply from: "$flutterRoot\/packages\/flutter_tools\/gradle\/flutter.gradle"/flutter { source "../.." }/' "$APP_GRADLE_PATH"

# Add the plugins block at the beginning of the file
sed -i '' 's/def localProperties = new Properties()/plugins { id "dev.flutter.flutter-gradle-plugin" }\n\ndef localProperties = new Properties()/' "$APP_GRADLE_PATH"

# Remove the flutter section at the bottom
sed -i '' '/flutter {/,/}/d' "$APP_GRADLE_PATH"

echo "Android Gradle configuration fixed!"
echo "Please try building again with: flutter build apk --debug"