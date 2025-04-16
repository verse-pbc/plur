#!/bin/bash

# Fourth round of localization fixes focusing on remaining keys

# Directory containing the code
PROJECT_DIR="/Users/rabble/code/verse/plur"
cd "$PROJECT_DIR" || exit 1

echo "Starting fourth round of localization fixes..."

# Get all the remaining issues
REMAINING_ISSUES=$(flutter analyze | grep "The getter '" | grep -o "The getter '[^']*'" | sed "s/The getter '//g" | sed "s/'//g" | sort | uniq)

echo "Found these remaining issues:"
echo "$REMAINING_ISSUES"

# Create a mapping file
MAPPING_FILE="/tmp/remaining_mappings.txt"
> "$MAPPING_FILE"

# For each issue, create a mapping to camelCase
echo "$REMAINING_ISSUES" | while read -r KEY; do
  # Skip keys that are already in camelCase
  if [[ $KEY =~ ^[a-z][a-zA-Z0-9]*$ ]]; then
    continue
  fi
  
  # Create camelCase version
  CAMEL_CASE=""
  
  # Handle snake_case
  if [[ $KEY == *_* ]]; then
    # Split by underscore and capitalize each part except the first
    IFS='_' read -ra PARTS <<< "$KEY"
    CAMEL_CASE="${PARTS[0],,}"
    
    for ((i=1; i<${#PARTS[@]}; i++)); do
      part="${PARTS[$i]}"
      # Capitalize first letter
      CAMEL_CASE="${CAMEL_CASE}${part^}"
    done
  # Handle PascalCase
  elif [[ $KEY =~ ^[A-Z] ]]; then
    # Convert first character to lowercase
    first_char=$(echo "${KEY:0:1}" | tr '[:upper:]' '[:lower:]')
    CAMEL_CASE="${first_char}${KEY:1}"
  fi
  
  # If we created a valid camelCase version, add it to the mappings
  if [[ -n "$CAMEL_CASE" ]]; then
    echo "$KEY|$CAMEL_CASE" >> "$MAPPING_FILE"
  fi
done

# Check if we have any mappings
if [[ ! -s "$MAPPING_FILE" ]]; then
  echo "No more mappings to apply."
  exit 0
fi

# Create sed commands file
SED_COMMANDS="/tmp/sed_commands_round4.txt"
> "$SED_COMMANDS"

# For each mapping, create sed commands
while IFS="|" read -r OLD_KEY NEW_KEY; do
  echo "s/S\.of(context)\.$OLD_KEY/S.of(context).$NEW_KEY/g" >> "$SED_COMMANDS"
  echo "s/localization\.$OLD_KEY/localization.$NEW_KEY/g" >> "$SED_COMMANDS"
done < "$MAPPING_FILE"

# Apply all changes at once to all Dart files
echo "Applying all replacements at once..."
find "$PROJECT_DIR/lib" -name "*.dart" -print0 | xargs -0 sed -i '' -f "$SED_COMMANDS"

echo "Completed fourth round of localization fixes. Please run Flutter analyze to verify the changes."