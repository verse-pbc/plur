#!/bin/bash
echo "Running app on iOS simulator (x86_64)..."
export FLUTTER_SIMULATOR_ARCHS=x86_64
flutter run -d "iPhone 16 Plus"
