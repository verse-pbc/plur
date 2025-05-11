#!/bin/bash
# Script to run Flutter in Chrome with debugging enabled
# This script sets up a proper debugging environment for Flutter web apps

# Colors for better readability
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Flutter Chrome Debug Runner ===${NC}"
echo -e "This script helps run Flutter in Chrome with debugging enabled"
echo -e "Make sure Chrome is installed and no other Flutter instances are running\n"

# Check if optional arguments were provided
WEB_PORT=8080
CHROME_PORT=9222
AUTO_TEST=false
AUTO_TEST_SCRIPT=""

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --port)
            WEB_PORT="$2"
            shift
            ;;
        --chrome-port)
            CHROME_PORT="$2"
            shift
            ;;
        --auto-test)
            AUTO_TEST=true
            AUTO_TEST_SCRIPT="$2"
            shift
            ;;
        *)
            echo -e "${RED}Unknown parameter: $1${NC}"
            exit 1
            ;;
    esac
    shift
done

# Make sure the web port and chrome debug port are not the same
if [ "$WEB_PORT" -eq "$CHROME_PORT" ]; then
    echo -e "${RED}Web port and Chrome debug port cannot be the same. Using default ports.${NC}"
    WEB_PORT=8080
    CHROME_PORT=9222
fi

# Kill any existing Chrome debug instances
echo -e "${YELLOW}Cleaning up any existing Chrome debug instances...${NC}"
pkill -f "chrome.*remote-debugging-port=$CHROME_PORT" || true
sleep 1

# Build the Flutter app for web
echo -e "${YELLOW}Building Flutter web app...${NC}"
flutter clean
flutter pub get
flutter build web --web-renderer html --profile

# Verify Chrome is installed
if ! command -v google-chrome &> /dev/null && ! command -v "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" &> /dev/null; then
    echo -e "${RED}Error: Google Chrome not found. Please install Chrome.${NC}"
    exit 1
fi

# Determine Chrome path
CHROME_PATH="google-chrome"
if [[ "$OSTYPE" == "darwin"* ]]; then
    CHROME_PATH="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
fi

# Create a temporary Chrome profile to avoid conflicts
CHROME_PROFILE_DIR="$(mktemp -d -t flutter_chrome_debug_XXXXXX)"
echo -e "${GREEN}Created Chrome profile at: $CHROME_PROFILE_DIR${NC}"

# Start Chrome with debugging enabled
echo -e "${YELLOW}Starting Chrome with remote debugging on port $CHROME_PORT...${NC}"
"$CHROME_PATH" --user-data-dir="$CHROME_PROFILE_DIR" \
               --remote-debugging-port=$CHROME_PORT \
               --no-first-run \
               --no-default-browser-check \
               --disable-translate \
               --disable-extensions \
               --disable-background-networking \
               --disable-background-timer-throttling \
               --disable-backgrounding-occluded-windows \
               --disable-component-extensions-with-background-pages \
               --disable-breakpad \
               --disable-sync \
               --disable-default-apps \
               --enable-features=NetworkService,NetworkServiceInProcess \
               --disable-popup-blocking \
               --window-size=1200,900 \
               about:blank &

CHROME_PID=$!

# Wait for Chrome to start
echo -e "${YELLOW}Waiting for Chrome to start...${NC}"
sleep 3

# Serve the Flutter web app
echo -e "${YELLOW}Starting Flutter web server on port $WEB_PORT...${NC}"
cd "$(dirname "$0")/.."
flutter run -d web-server --web-port=$WEB_PORT --web-renderer=html --profile &

FLUTTER_PID=$!

# Print important info
echo -e "\n${GREEN}====== FLUTTER DEBUG INFO ======${NC}"
echo -e "${GREEN}Flutter web app running at:${NC} http://localhost:$WEB_PORT"
echo -e "${GREEN}Chrome remote debugging:${NC} http://localhost:$CHROME_PORT"
echo -e "${GREEN}Chrome profile:${NC} $CHROME_PROFILE_DIR"
echo -e "${GREEN}Flutter PID:${NC} $FLUTTER_PID"
echo -e "${GREEN}Chrome PID:${NC} $CHROME_PID"

# If auto-test is enabled, run the test script
if [ "$AUTO_TEST" = true ] && [ -n "$AUTO_TEST_SCRIPT" ]; then
    echo -e "\n${YELLOW}Running automated test script: $AUTO_TEST_SCRIPT${NC}"
    sleep 5 # Give Flutter app a moment to initialize
    python3 "$AUTO_TEST_SCRIPT"
    TEST_EXIT_CODE=$?
    if [ $TEST_EXIT_CODE -ne 0 ]; then
        echo -e "${RED}Test script failed with exit code $TEST_EXIT_CODE${NC}"
    else
        echo -e "${GREEN}Test script completed successfully${NC}"
    fi
fi

# Wait for user to press Ctrl+C
echo -e "\n${BLUE}App is now running. Press Ctrl+C to stop...${NC}"
trap 'echo -e "\n${YELLOW}Shutting down...${NC}"; kill $FLUTTER_PID $CHROME_PID 2>/dev/null; rm -rf "$CHROME_PROFILE_DIR"; exit 0' INT
wait $FLUTTER_PID $CHROME_PID