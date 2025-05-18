#!/bin/bash

# Ensure the script is run with bash
if [ -z "$BASH_VERSION" ]; then
  echo "✗ This script must be run with bash. Please use: bash install.sh"
  exit 1
fi

# Colors and formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Function to print section headers
print_header() {
    echo -e "\n${BLUE}${BOLD}=== $1 ===${NC}\n"
}

# Function to print success messages
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Function to print error messages
print_error() {
    echo -e "${RED}✗ $1${NC}"
    exit 1
}

# Function to print info messages
print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

# Function to validate API key format and check with server
validate_api_key() {
    local api_key=$1

    # Check with server
    print_info "Validating API key with Operative servers..."
    local response
    response=$(curl -s -H "x-operative-api-key: $api_key" \
                  "https://operative-backend.onrender.com/api/validate-key")
    
    # Check if curl request was successful
    if [ $? -ne 0 ]; then
        print_error "Could not connect to validation server. Please check your internet connection."
    fi

    # Parse response using jq
    if echo "$response" | jq -e '.valid' > /dev/null; then
        return 0
    else
        local error_message
        error_message=$(echo "$response" | jq -r '.message')
        echo -e "${RED}✗ $error_message${NC}" >&2
        return 1
    fi
}

# Print welcome message with ASCII art
cat << "EOF"                                                    
                                    $$$$                                    
                                 $$$    $$$                                 
                              $$$          $$$                              
                           $$$     $$$$$$     $$$                           
                        $$$     $$$  $$  $$$     $$$c                       
                    c$$$     $$$     $$     $$$     $$$$                    
                   $$$$      $$$x    $$     $$$      $$$$                   
                   $$  $$$      >$$$ $$ ;$$$      $$$  $$                   
                   $$     $$$       $$$$8      $$$     $$                   
                   $$        $$$            $$$        $$                   
                   $$   $$$     $$$$     $$$     $$$   $$                   
                   $$   $  $$$     I$$$$$     $$$  $   $$                   
                   $$   $     $$$    $$    $$$     $   $$                   
                   $$   $     $$$$   $$   $$$$     $   $$                   
                   $$   $  $$$   $   $$   $   $$$  $   $$                   
                   $$   $$$      $   $$   $      $$$   $$                   
                   $$     $$$    $   $$   $    $$$     $$                   
                    $$$      $$$ $   $$   $ $$$      $$$                    
                       $$$      $$   $$   $$      $$$                       
                          $$$        $$        $$$                          
                             $$$     $$     $$$                             
                                $$$  $$  $$$                                
                                   $$$$$$                                   
EOF

echo -e "\n${BOLD}🚀 Welcome to the Operative Web Eval Agent Installer${NC}"
echo -e "This script will set up everything you need to get started.\n"

# Ask for installation type
print_header "Installation Type"
echo -e "Choose the installation type:"

# Simpler arrow-based selection function that works across different shells
select_option() {
    local options=("$@")
    local current=0
    local IFS=$'\n'

    # Function to display menu with current selection highlighted
    display_menu() {
        local idx=0
        for opt in "${options[@]}"; do
            if [ $idx -eq $current ]; then
                echo -e "${GREEN}→ $opt${NC}"
            else
                echo -e "  $opt"
            fi
            ((idx++))
        done
    }

    # Clear screen area for menu
    clear_menu() {
        local i
        for ((i=0; i<${#options[@]}; i++)); do
            tput cuu1; tput el
        done
    }

    # Display initial menu
    display_menu

    # Loop until user hits enter
    while true; do
        # Wait for keypress
        IFS= read -r -s -n1 key

        case "$key" in
            # Enter key
            "")
                return $current
                ;;
            # Escape key - could be arrow key sequence
            $'\e')
                # Read additional bytes (arrow keys send 3-byte sequence)
                read -r -s -n2 arrow || continue

                # Handle arrow keys
                case "$arrow" in
                    "[A") # Up arrow
                        if [ $current -gt 0 ]; then
                            ((current--))
                        else
                            current=$((${#options[@]}-1))
                        fi
                        clear_menu
                        display_menu
                        ;;
                    "[B") # Down arrow
                        if [ $current -lt $((${#options[@]}-1)) ]; then
                            ((current++))
                        else
                            current=0
                        fi
                        clear_menu
                        display_menu
                        ;;
                esac
                ;;
        esac
    done
}

# Define options array for installation type
install_options=("Cursor Agent Mode (default)" "Cline Extension" "Claude Desktop" "Windsurf")

# Display menu and get selection
echo
select_option "${install_options[@]}"
INSTALL_TYPE=$?
echo

# Determine MCP path based on selection
if [[ "$INSTALL_TYPE" == "0" ]]; then
    # Cursor Agent Mode
    print_info "Selected: Cursor Agent Mode"
    MCP_FILE="$HOME/.cursor/mcp.json"
    USE_CLINE=0
elif [[ "$INSTALL_TYPE" == "1" ]]; then
    # Cline Extension
    print_info "Selected: Cline Extension"
    USE_CLINE=1

    # Ask where Cline is being used
    print_header "Cline Editor Selection"
    echo -e "Where are you using the Cline Extension?"
    echo
    cline_editor_options=("Cursor (default)" "VS Code")
    select_option "${cline_editor_options[@]}"
    CLINE_EDITOR=$?
    echo

    if [[ "$CLINE_EDITOR" == "0" ]]; then
        # Cline in Cursor
        print_info "Using Cline Extension in Cursor"
        CLINE_DIR="$HOME/Library/Application Support/Cursor/User/globalStorage/saoudrizwan.claude-dev/settings"
        MCP_FILE="$CLINE_DIR/cline_mcp_settings.json"
    else
        # Cline in VS Code
        print_info "Using Cline Extension in VS Code"
        CLINE_DIR="$HOME/Library/Application Support/Code/User/globalStorage/saoudrizwan.claude-dev/settings"
        MCP_FILE="$CLINE_DIR/cline_mcp_settings.json"
    fi
elif [[ "$INSTALL_TYPE" == "2" ]]; then
    # Claude Desktop
    print_info "Selected: Claude Desktop"
    USE_CLINE=0
    MCP_FILE="$HOME/Library/Application Support/Claude/claude_desktop_config.json"
else
    # Windsurf
    print_info "Selected: Windsurf"
    USE_CLINE=0
    MCP_FILE="$HOME/.codeium/windsurf/mcp_config.json"
fi

# Create necessary directory for MCP config
print_header "Setting up directory"
if [[ "$USE_CLINE" == "0" ]]; then
    # Cursor Agent Mode, Claude Desktop, or Windsurf
    mkdir -p "$(dirname "$MCP_FILE")"
    # Determine the correct directory name to print
    DIR_NAME=""
    if [[ "$INSTALL_TYPE" == "0" ]]; then
        DIR_NAME="Cursor"
    elif [[ "$INSTALL_TYPE" == "2" ]]; then
        DIR_NAME="Claude Desktop"
    else # Windsurf
        DIR_NAME="Windsurf"
    fi
    print_success "Created $DIR_NAME directory: $(dirname "$MCP_FILE")"
else
    # Cline Extension
    mkdir -p "$CLINE_DIR"
    print_success "Created Cline settings directory: $CLINE_DIR"
fi

# Check for UV
print_header "Checking dependencies"
if ! command -v uv &> /dev/null; then
    print_info "Installing UV package manager..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    source ~/.zshrc 
    print_success "UV installed successfully"
else
    print_success "UV is already installed"
fi

# Check for jq
if ! command -v jq &> /dev/null; then
    print_info "Installing jq..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        brew install jq
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        sudo apt-get update && sudo apt-get install -y jq
    fi
    print_success "jq installed successfully"
else
    print_success "jq is already installed"
fi

# Pre-download dependencies
print_header "Pre-downloading dependencies"
print_info "Downloading and initializing dependencies (this may take several minutes)..."

# Create a temporary file to capture the output
TEMP_LOG=$(mktemp)

# Run the command and redirect output to the temporary file
(uvx --from git+https://github.com/Operative-Sh/web-eval-agent.git webEvalAgent > "$TEMP_LOG" 2>&1) &
COMMAND_PID=$!

# Wait for the command to complete or timeout
MAX_WAIT=180  # Increased to 3 minutes (180 seconds)
WAIT_COUNT=0

# Store the last file size to detect progress
LAST_SIZE=0

while [ $WAIT_COUNT -lt $MAX_WAIT ]; do
    # Check if the process is still running
    if ! kill -0 $COMMAND_PID 2>/dev/null; then
        # Process completed on its own
        print_success "Dependencies downloaded successfully"
        break
    fi
    
    # Check for success indicators in the log file
    if grep -q "BrowserUse logging setup complete\|Successfully ran\|completed successfully\|OPERATIVE_API_KEY" "$TEMP_LOG"; then
        print_success "Setup complete, dependencies downloaded successfully"
        break
    fi
    
    # Check file size to show progress
    CURRENT_SIZE=$(wc -c < "$TEMP_LOG")
    if [ "$CURRENT_SIZE" -gt "$LAST_SIZE" ]; then
        # There's new output, show a preview
        tail -n 2 "$TEMP_LOG" | grep -v '^\s*$' | head -n 1
        LAST_SIZE=$CURRENT_SIZE
    fi
    
    sleep 2
    WAIT_COUNT=$((WAIT_COUNT + 2))
    
    # Show progress every 10 seconds
    if [ $((WAIT_COUNT % 10)) -eq 0 ]; then
        print_info "Still waiting... ($WAIT_COUNT/$MAX_WAIT seconds)"
    fi
done

# Kill the process if it's still running
if kill -0 $COMMAND_PID 2>/dev/null; then
    print_info "Stopping the download process..."
    kill $COMMAND_PID 2>/dev/null || true
    sleep 1
    
    # Make sure any child processes are also terminated
    pkill -P $COMMAND_PID 2>/dev/null || true
fi

# Show a helpful message based on results
if [ $WAIT_COUNT -ge $MAX_WAIT ]; then
    print_info "Timeout reached after $MAX_WAIT seconds."
    if [ -s "$TEMP_LOG" ]; then
        print_info "Partial download may have occurred. Installation will continue."
        print_info "Last output from download process:"
        tail -n 5 "$TEMP_LOG"
    else
        print_error "No download progress detected. Please check your network connection and try again."
    fi
else
    print_success "Dependencies initialized successfully"
fi

# Clean up the temporary file
rm -f "$TEMP_LOG"

# Install Playwright browsers
print_header "Installing Playwright browsers"
print_info "Installing browser binaries for web automation..."

# Simply run playwright install directly
npm install -g chromium
npm install -g playwright  

uvx --with playwright playwright install --with-deps

print_success "Playwright browsers installed successfully"

# Prompt for API key
print_header "API Key Configuration"
echo -e "An Operative.sh API key is required for this installation."
echo -e "If you don't have one, please visit ${BOLD}https://operative.sh${NC} to get your key.\n"

API_KEY=""
while true; do
    read -p "Please enter your Operative.sh API key: " API_KEY
    if [ -z "$API_KEY" ]; then
        echo -e "${RED}✗ API key cannot be empty${NC}"
        continue
    fi
    
    # Server validation
    if validate_api_key "$API_KEY"; then
        print_success "API key validated successfully"
        break
    else
        echo -e "${YELLOW}Would you like to try again? (y/n)${NC}"
        read -r response
        if [[ "$response" =~ ^[Nn] ]]; then
            print_error "Installation cancelled - valid API key required"
        fi
    fi
done

# Configure MCP server
print_header "Configuring MCP server"

# Create initial MCP configuration if needed
if [ ! -f "$MCP_FILE" ]; then
    echo '{
  "mcpServers": {}
}' > "$MCP_FILE"
    print_success "Created new MCP configuration file"
fi

# Define server configuration based on installation type
if [[ "$USE_CLINE" == "1" ]]; then
    # Cline Extension Configuration
    NEW_SERVER=$(cat <<EOF
{
  "command": "uvx",
  "args": [
    "--refresh-package",
    "webEvalAgent",
    "--from",
    "git+https://github.com/Operative-Sh/web-eval-agent.git",
    "webEvalAgent"
  ],
  "env": {
    "OPERATIVE_API_KEY": "$API_KEY"
  },
  "disabled": false,
  "autoApprove": []
}
EOF
)
else
    # Cursor Agent Mode / Claude Desktop Configuration
    NEW_SERVER=$(cat <<EOF
{
  "command": "uvx",
  "args": [
    "--refresh-package",
    "webEvalAgent",
    "--from",
    "git+https://github.com/Operative-Sh/web-eval-agent.git",
    "webEvalAgent"
  ],
  "env": {
    "OPERATIVE_API_KEY": "$API_KEY"
  }
}
EOF
)
fi

# Validate and update configuration
if echo "$NEW_SERVER" | jq '.' > /dev/null; then
    jq --arg name "web-eval-agent" \
       --argjson config "$NEW_SERVER" \
       '.mcpServers[$name] = $config' \
       "$MCP_FILE" > "$MCP_FILE.tmp" && mv "$MCP_FILE.tmp" "$MCP_FILE"
    print_success "MCP server configuration updated successfully"
else
    print_error "Invalid JSON configuration"
fi

# Installation complete
print_header "Installation Complete! 🎉"
echo -e "Your Operative Web Eval Agent has been set up successfully."

if [[ "$USE_CLINE" == "0" ]]; then
    if [[ "$INSTALL_TYPE" == "0" ]]; then
      echo -e "\nYou can now use the web_app_ux_evaluator in Cursor Agent Mode."
    elif [[ "$INSTALL_TYPE" == "2" ]]; then
      echo -e "\nYou can now use the web_app_ux_evaluator in Claude Desktop."
    else # Windsurf
      echo -e "\nYou can now use the web_app_ux_evaluator in Windsurf."
    fi
else
    echo -e "\nYou can now use the web_app_ux_evaluator in Cline."
fi

echo -e "
${BOLD}${RED}⚠️  IMPORTANT: You must restart the relevant application (Cursor, Claude, Cline, or Windsurf) or the MCP server for changes to take effect! ⚠️${NC}"
echo -e "${RED}To restart the MCP server, you can close and reopen the application, or restart it from the Command Palette if available.${NC}"

echo -e "\nThank you for installing! 🙏\n"
echo -e "Built with ❤️  by Operative.sh"
