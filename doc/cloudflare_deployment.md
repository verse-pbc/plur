# Deploying Plur to Cloudflare Pages

This document outlines the steps to deploy the Plur application to Cloudflare Pages.

## Prerequisites

- A Cloudflare account
- Access to the Cloudflare Pages service
- GitHub repository with the Plur codebase

## Setup Steps

1. **Build the Flutter Web App Locally**:
   ```bash
   flutter build web --release
   ```
   This creates a production build in the `build/web` directory.

2. **Set Up Cloudflare Pages Project**:
   
   a. Log in to your Cloudflare account and go to Pages
   
   b. Click "Create a project" > "Connect to Git"
   
   c. Select the GitHub repository for Plur
   
   d. Configure your build settings:
      - Production branch: `main` (or your preferred branch)
      - Build command: `flutter build web --release`
      - Build output directory: `build/web`
      - Environment variables:
        - `NODE_VERSION`: `16.13.0` or newer
      
   e. Advanced build settings:
      - Install Flutter during the build process by adding these lines to the beginning of the build command:
        ```
        curl -O https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.5-stable.tar.xz &&
        tar xf flutter_linux_3.24.5-stable.tar.xz &&
        export PATH="$PATH:`pwd`/flutter/bin" &&
        flutter precache --web &&
        ```

3. **Deploy Manually Using Wrangler (Alternative)**:
   
   If you prefer to deploy manually, you can use Wrangler (Cloudflare's CLI tool):
   
   a. Install Wrangler:
   ```bash
   npm install -g wrangler
   ```
   
   b. Create a `wrangler.toml` file in the project root:
   ```toml
   name = "plur-app"
   type = "webpack"
   account_id = "your-account-id"
   zone_id = "your-zone-id"
   route = ""
   workers_dev = true
   
   [site]
   bucket = "./build/web"
   entry-point = "."
   ```
   
   c. Deploy with Wrangler:
   ```bash
   wrangler publish
   ```

## Post-Deployment Steps

1. **Configure Custom Domain** (if needed):
   
   a. In Cloudflare Pages, go to your project > Custom domains
   
   b. Add your custom domain and follow the verification steps

2. **Update DNS Records** (if using custom domain):
   
   Ensure your DNS records point to your Cloudflare Pages deployment

## Continuous Deployment

To set up continuous deployment, you can create a GitHub Action workflow:

1. Create `.github/workflows/cloudflare-pages-deploy.yml`:

```yaml
name: Deploy to Cloudflare Pages

on:
  push:
    branches:
      - main  # or your production branch
  workflow_dispatch:

jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      deployments: write
    steps:
      - name: Checkout repository
        uses: actions/checkout@v3
        with:
          submodules: recursive

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.5'
          channel: 'stable'
          cache: true

      - name: Install dependencies
        run: flutter pub get

      - name: Build web app
        run: flutter build web --release

      - name: Deploy to Cloudflare Pages
        uses: cloudflare/pages-action@v1
        with:
          apiToken: ${{ secrets.CLOUDFLARE_API_TOKEN }}
          accountId: ${{ secrets.CLOUDFLARE_ACCOUNT_ID }}
          projectName: plur-app  # Your Cloudflare Pages project name
          directory: build/web
          gitHubToken: ${{ secrets.GITHUB_TOKEN }}
```

2. Add the required secrets to your GitHub repository:
   - `CLOUDFLARE_API_TOKEN`: Your Cloudflare API token with Pages access
   - `CLOUDFLARE_ACCOUNT_ID`: Your Cloudflare account ID

## Troubleshooting

- If you encounter issues with Flutter installation during Cloudflare build, consider using a custom Docker image that already has Flutter installed
- For routing issues, ensure you have a proper `web/index.html` that handles path-based routing
- Check the Cloudflare Pages build logs for detailed error information

## Useful Resources

- [Cloudflare Pages Documentation](https://developers.cloudflare.com/pages/)
- [Flutter Web Deployment Guide](https://docs.flutter.dev/deployment/web)
- [Wrangler Documentation](https://developers.cloudflare.com/workers/wrangler/)