#!/bin/bash
set -e

echo "Building Plur for Android..."

# Prepare environment variables
export ANDROID_SDK_ROOT=/Users/rabble/Library/Android/sdk
export JAVA_HOME=/Applications/Android\ Studio.app/Contents/jbr/Contents/Home
export PATH=$JAVA_HOME/bin:$PATH

# Ensure all dependencies are up to date
flutter clean
flutter pub get

# Update local.properties with correct settings
echo "flutter.sdk=/opt/homebrew/Caskroom/flutter/3.27.4/flutter" > android/local.properties
echo "sdk.dir=/Users/rabble/Library/Android/sdk" >> android/local.properties
echo "flutter.buildMode=release" >> android/local.properties
echo "flutter.versionName=0.1.2" >> android/local.properties
echo "flutter.versionCode=$(date +%s)" >> android/local.properties

# Explicitly add JVM argument to allow running with Java 21
echo "org.gradle.jvmargs=-Xmx1536M -Dkotlin.daemon.jvm.options="-Xmx1536M" --add-exports=java.base/sun.nio.ch=ALL-UNNAMED --add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/java.lang.reflect=ALL-UNNAMED --add-opens=java.base/java.io=ALL-UNNAMED --add-exports=jdk.unsupported/sun.misc=ALL-UNNAMED" >> android/gradle.properties

# Create an APK first (often more reliable than app bundle)
echo "Building APK..."
cd android
./gradlew clean
./gradlew assembleRelease

# Go back to project root
cd ..

echo "Build completed!"
echo "APK location: build/app/outputs/apk/release/app-release.apk"

# If APK build succeeds, try the app bundle
if [ -f "build/app/outputs/apk/release/app-release.apk" ]; then
  echo "APK build successful, now attempting App Bundle..."
  cd android
  ./gradlew bundleRelease
  cd ..
  echo "App Bundle location: build/app/outputs/bundle/release/app-release.aab"
else
  echo "APK build failed. Please check the error messages above."
fi