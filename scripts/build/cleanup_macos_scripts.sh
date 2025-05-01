#!/bin/bash
# Script to clean up redundant macOS build fix scripts

echo "Cleaning up redundant macOS build fix scripts..."

# Keep only the consolidated build_macos.sh script
# Remove all other fix scripts
rm -f build_macos_arm64.sh
rm -f build_macos_minimal.sh
rm -f build_macos_simple_fix.sh
rm -f fix_and_build_macos.sh
rm -f fix_cryptography.sh
rm -f fix_macos_arch.sh
rm -f fix_macos_best.sh
rm -f fix_macos_cryptography.sh
rm -f fix_macos_final.sh
rm -f fix_macos_simple.sh
rm -f fix_macos_ultimate.sh
rm -f fix_macos_x86_64.sh
rm -f macos_post_build_fix.sh
rm -f macos_pre_build.sh
rm -f macos_simple_build.sh
rm -f one_click_macos_fix.sh

echo "Cleanup complete!"
echo "The consolidated solution is now in build_macos.sh"
echo "Documentation is in MACOS_BUILD_FIX.md"