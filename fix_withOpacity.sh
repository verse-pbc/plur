#!/bin/bash

# This script replaces all occurrences of withOpacity() with withAlpha()
# and dynamically calculates the appropriate alpha value (opacity * 255).

# Find all Dart files with withOpacity
find lib -type f -name "*.dart" | xargs grep -l "withOpacity" > files.txt

while IFS= read -r file; do
  echo "Processing $file"
  
  # Create a temporary file
  temp_file="${file}.tmp"
  
  # Read the file line by line
  while IFS= read -r line; do
    # Check if the line contains withOpacity
    if [[ "$line" == *".withOpacity("* ]]; then
      # Extract all withOpacity occurrences in the line
      while [[ "$line" =~ (.*)\.withOpacity\(([0-9]*\.[0-9]+)\)(.*) ]]; do
        prefix="${BASH_REMATCH[1]}"
        opacity="${BASH_REMATCH[2]}"
        suffix="${BASH_REMATCH[3]}"
        
        # Calculate alpha value (opacity * 255, rounded to nearest integer)
        alpha=$(echo "$opacity * 255" | bc -l | xargs printf "%.0f")
        
        # Replace withOpacity with withAlpha
        line="${prefix}.withAlpha(${alpha})${suffix}"
      done
    fi
    
    # Write the line to the temporary file
    echo "$line" >> "$temp_file"
  done < "$file"
  
  # Replace the original file with the temporary file
  mv "$temp_file" "$file"
  
done < files.txt

# Cleanup
rm files.txt

echo "All withOpacity calls have been replaced with withAlpha!"