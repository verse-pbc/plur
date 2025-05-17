#!/bin/bash

# Define the source and target paths
SCRIPT_PATH=$(dirname "$(realpath "$0")")
HOOK_FILE="$SCRIPT_PATH/pre-commit"
TARGET_DIR="$(git rev-parse --git-dir)/hooks"
TARGET_FILE="$TARGET_DIR/pre-commit"

# Create the hook script
cat > "$HOOK_FILE" << 'EOF'
#!/bin/bash

# Prevent commit if logging linter fails
echo "Running logging linter..."
dart scripts/lint_logging.dart
if [ $? -ne 0 ]; then
  echo "❌ Logging linter failed. Please fix the issues and try again."
  exit 1
fi

# Add more checks here as needed

echo "✅ All checks passed"
exit 0
EOF

# Make the hook executable
chmod +x "$HOOK_FILE"

# Create the hooks directory if it doesn't exist
mkdir -p "$TARGET_DIR"

# Install the hook
cp "$HOOK_FILE" "$TARGET_FILE"
chmod +x "$TARGET_FILE"

echo "Git pre-commit hook installed successfully!" 