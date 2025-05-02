# This script patches the mobile_scanner podspec to use GoogleMLKit/MLKitCore 7.0.0
require 'pathname'
require 'fileutils'

# Find the mobile_scanner.podspec file
def find_podspec
  symlinks_dir = File.join(Dir.pwd, '.symlinks', 'plugins', 'mobile_scanner', 'ios')
  podspec_path = File.join(symlinks_dir, 'mobile_scanner.podspec')
  
  if File.exist?(podspec_path)
    return podspec_path
  else
    puts "Could not find mobile_scanner.podspec at #{podspec_path}"
    return nil
  end
end

# Patch the podspec file to do nothing
def patch_podspec(podspec_path)
  puts "Skipping patch, using GoogleMLKit/BarcodeScanning 8.0.0"
  return false
end

# Main execution
podspec_path = find_podspec
if podspec_path
  patched = patch_podspec(podspec_path)
  if patched
    puts "✅ mobile_scanner.podspec has been patched"
  else
    puts "⚠️ No changes were made to mobile_scanner.podspec"
  end
else
  puts "❌ Failed to find mobile_scanner.podspec"
end
