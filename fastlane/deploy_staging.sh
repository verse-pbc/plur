#!/bin/bash

# Ensure provisioning profiles are up to date
flutter build ipa --flavor runner-staging --export-options-plist=ios/Runner/ExportOptions.plist

# Deploy using fastlane
fastlane ios deploy_staging