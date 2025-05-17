#!/bin/bash

# Create a directory to work in
mkdir -p tmp_app_update

# Extract the IPA
unzip -q ipaOutput2/Holis.ipa -d tmp_app_update

# Update the plist with the new build number
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion 6" tmp_app_update/Payload/Runner.app/Info.plist

# Repackage the IPA
cd tmp_app_update
zip -qr ../ipaOutput2/Holis_v6.ipa Payload
cd ..

echo "Build number updated to 6 and new IPA created at ipaOutput2/Holis_v6.ipa"