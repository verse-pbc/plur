#!/bin/bash
# Script to set up the Flutter testing environment

# Colors for better readability
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Flutter Test Environment Setup ===${NC}"
echo -e "This script installs required dependencies for Flutter testing\n"

# Check Python installation
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}Error: Python 3 is not installed. Please install Python 3.${NC}"
    exit 1
fi

# Install Playwright
echo -e "${YELLOW}Installing Playwright...${NC}"
pip3 install playwright
python3 -m playwright install

# Check Flutter installation
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}Error: Flutter is not installed. Please install Flutter.${NC}"
    exit 1
fi

# Check if Chrome is installed
if ! command -v google-chrome &> /dev/null && ! [[ -d "/Applications/Google Chrome.app" ]]; then
    echo -e "${YELLOW}Warning: Google Chrome not found. Please install Chrome for testing.${NC}"
fi

# Verify Flutter web is enabled
echo -e "${YELLOW}Verifying Flutter web is enabled...${NC}"
flutter config --enable-web

# Run Flutter doctor
echo -e "${YELLOW}Running Flutter doctor...${NC}"
flutter doctor -v

echo -e "\n${GREEN}Setup complete! You can now run the testing scripts:${NC}"
echo -e "  ${BLUE}./scripts/run_flutter_chrome_debug.sh${NC} - Run Flutter in Chrome with debugging"
echo -e "  ${BLUE}./scripts/plur_app_tester.py${NC} - Run the interactive app tester"
echo -e "\nExample usage:"
echo -e "  ${BLUE}./scripts/run_flutter_chrome_debug.sh${NC}"
echo -e "  ${BLUE}python3 ./scripts/plur_app_tester.py interactive${NC}"