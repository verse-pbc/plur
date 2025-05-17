#!/bin/bash

# Check if ImageMagick is installed
if ! command -v convert &> /dev/null; then
    echo "Error: ImageMagick is not installed. Please install it first."
    echo "Run: brew install imagemagick"
    exit 1
fi

# Source logo
SOURCE_LOGO="/Users/rabble/code/verse/plur/holis_logo.png"
ICONS_DIR="/Users/rabble/code/verse/plur/ios/Runner/Assets.xcassets/AppIcon.appiconset"
LAUNCH_DIR="/Users/rabble/code/verse/plur/ios/Runner/Assets.xcassets/LaunchImage.imageset"

# Check if source file exists
if [ ! -f "$SOURCE_LOGO" ]; then
    echo "Error: Source logo not found at $SOURCE_LOGO"
    exit 1
fi

# Create App Icons
echo "Generating App Icons..."

# iPhone App icon sizes
convert "$SOURCE_LOGO" -resize 20x20 "$ICONS_DIR/Icon-App-20x20@1x.png"
convert "$SOURCE_LOGO" -resize 40x40 "$ICONS_DIR/Icon-App-20x20@2x.png"
convert "$SOURCE_LOGO" -resize 60x60 "$ICONS_DIR/Icon-App-20x20@3x.png"
convert "$SOURCE_LOGO" -resize 29x29 "$ICONS_DIR/Icon-App-29x29@1x.png"
convert "$SOURCE_LOGO" -resize 58x58 "$ICONS_DIR/Icon-App-29x29@2x.png"
convert "$SOURCE_LOGO" -resize 87x87 "$ICONS_DIR/Icon-App-29x29@3x.png"
convert "$SOURCE_LOGO" -resize 40x40 "$ICONS_DIR/Icon-App-40x40@1x.png"
convert "$SOURCE_LOGO" -resize 80x80 "$ICONS_DIR/Icon-App-40x40@2x.png"
convert "$SOURCE_LOGO" -resize 120x120 "$ICONS_DIR/Icon-App-40x40@3x.png"
convert "$SOURCE_LOGO" -resize 120x120 "$ICONS_DIR/Icon-App-60x60@2x.png"
convert "$SOURCE_LOGO" -resize 180x180 "$ICONS_DIR/Icon-App-60x60@3x.png"
convert "$SOURCE_LOGO" -resize 76x76 "$ICONS_DIR/Icon-App-76x76@1x.png"
convert "$SOURCE_LOGO" -resize 152x152 "$ICONS_DIR/Icon-App-76x76@2x.png"
convert "$SOURCE_LOGO" -resize 167x167 "$ICONS_DIR/Icon-App-83.5x83.5@2x.png"
convert "$SOURCE_LOGO" -resize 1024x1024 "$ICONS_DIR/Icon-App-1024x1024@1x.png"

# Generate Launch Images
echo "Generating Launch Images..."

# Create a white background with logo in center
convert -size 750x1334 xc:white "$SOURCE_LOGO" -gravity center -composite "$LAUNCH_DIR/LaunchImage@2x.png"
convert -size 1242x2208 xc:white "$SOURCE_LOGO" -gravity center -composite "$LAUNCH_DIR/LaunchImage@3x.png"
# Create the 1x version as well
convert -size 375x667 xc:white "$SOURCE_LOGO" -resize 150x150 -gravity center -composite "$LAUNCH_DIR/LaunchImage.png"

echo "App icons and launch images generated successfully!"