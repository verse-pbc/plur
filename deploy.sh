#!/bin/bash

# Build the Flutter web app
echo "Building Flutter web app..."
flutter build web --release

# Deploy to Cloudflare Pages
echo "Deploying to Cloudflare Pages..."
CLOUDFLARE_ACCOUNT_ID="c84e7a9bf7ed99cb41b8e73566568c75" npx wrangler pages deploy build/web --project-name=plur-app --commit-dirty=true

echo "Deployment complete!"