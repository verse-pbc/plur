#!/bin/bash

# Ensure provisioning profiles are up to date
flutter build ipa --flavor runner-staging --export-options-plist=ios/Runner/ExportOptions.plist

# Create symlink for scheme if it doesn't exist
SCHEME_PATH="/Users/rabble/code/verse/plur/ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner-Staging.xcscheme"
if [ -f "$SCHEME_PATH" ]; then
  echo "Runner-Staging scheme exists"
else
  echo "Creating Runner-Staging scheme from Runner scheme"
  cp /Users/rabble/code/verse/plur/ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme "$SCHEME_PATH"
  sed -i '' 's/buildConfiguration = "Debug"/buildConfiguration = "Debug-Runner-Staging"/g' "$SCHEME_PATH"
  sed -i '' 's/buildConfiguration = "Release"/buildConfiguration = "Release-Runner-Staging"/g' "$SCHEME_PATH"
fi

# Deploy using fastlane - make sure to specify the correct scheme
cd /Users/rabble/code/verse/plur
fastlane ios deploy_staging