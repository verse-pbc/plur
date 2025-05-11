# Flutter Plur App Testing Tools

This directory contains tools for testing the Plur Flutter application using Chrome DevTools Protocol and Playwright automation.

## Overview

These tools allow you to:
1. Run the Flutter app in Chrome with debugging enabled
2. Connect to the running app for automated testing
3. Automate specific testing flows for the Plur app
4. Interactively control and test the app

## Setup

1. Run the setup script to install dependencies:

```bash
./setup_test_environment.sh
```

This will install:
- Playwright (Python package for browser automation)
- Browser binaries for Playwright

## Running the App with Debugging

Use the `run_flutter_chrome_debug.sh` script to run your Flutter app in Chrome with remote debugging enabled:

```bash
./run_flutter_chrome_debug.sh
```

Options:
- `--port PORT` - Set the Flutter web server port (default: 8080)
- `--chrome-port PORT` - Set the Chrome DevTools debugging port (default: 9222)
- `--auto-test SCRIPT_PATH` - Run an automated test script after launch

Example:
```bash
./run_flutter_chrome_debug.sh --port 8000 --chrome-port 9223
```

## Using the Testing Tools

### Basic Flutter Test Automation

The `flutter_test_automation.py` script provides basic automation capabilities:

```bash
python3 flutter_test_automation.py
```

This starts an interactive session where you can:
- Click on elements by text content
- Type into input fields
- Take screenshots
- View the app structure

### Plur-Specific Testing

The `plur_app_tester.py` script extends the basic automation with Plur-specific features:

```bash
python3 plur_app_tester.py [command]
```

Commands:
- `test_invite_flow` - Test the community invite flow
- `test_community_creation` - Test creating a new community
- `interactive` - Start an interactive session (default)

In interactive mode, you can:
- Login to the app
- Navigate to communities section
- Create new communities
- Generate invite links
- List visible communities
- Take screenshots

Example:
```bash
python3 plur_app_tester.py test_invite_flow
```

## Connecting to Flutter DevTools

When running the app with debugging enabled, you can connect to Flutter DevTools:

1. Visit http://localhost:9222 (or your custom Chrome debug port)
2. Click on the Flutter app link in the list
3. Click on the "Sources" tab
4. You can now debug the app and use the Chrome DevTools console

## Further Customization

These scripts provide a starting point for automation. You can extend them to:

1. Add more Plur-specific test flows
2. Create automated regression tests
3. Build a CI/CD pipeline for testing
4. Record test sessions for documentation

## Troubleshooting

If you encounter issues:

1. Make sure Chrome is not running with the same debug port
2. Check that Flutter web is properly configured
3. Verify the ports are available and not used by other services
4. Run `flutter doctor -v` to check for Flutter issues

For Playwright-specific issues, check the [Playwright documentation](https://playwright.dev/python/docs/intro).