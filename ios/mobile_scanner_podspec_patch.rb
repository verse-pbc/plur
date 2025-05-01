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

# Patch the podspec file to use GoogleMLKit/MLKitCore 7.0.0
def patch_podspec(podspec_path)
  return false unless podspec_path && File.exist?(podspec_path)
  
  content = File.read(podspec_path)
  
  # Replace the GoogleMLKit/BarcodeScanning dependency version
  patched_content = content.gsub(
    /s\.dependency 'GoogleMLKit\/BarcodeScanning', '~> 4\.0\.0'/,
    "s.dependency 'GoogleMLKit/BarcodeScanning', '~> 4.0.0'\n  s.dependency 'GoogleMLKit/MLKitCore', '= 7.0.0'"
  )
  
  # Only write if changes were made
  if content != patched_content
    File.write(podspec_path, patched_content)
    puts "Successfully patched mobile_scanner.podspec to use GoogleMLKit/MLKitCore 7.0.0"
    return true
  else
    puts "No changes needed for mobile_scanner.podspec"
    return false
  end
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
