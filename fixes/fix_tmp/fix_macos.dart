import 'dart:io';

void main() async {
  // Step 1: Check if the GeneratedPluginRegistrant.swift exists
  final registrantFile = File('macos/Flutter/GeneratedPluginRegistrant.swift');
  if (\!registrantFile.existsSync()) {
    print('GeneratedPluginRegistrant.swift does not exist');
    return;
  }

  // Step 2: Make it writable
  await Process.run('chmod', ['+w', 'macos/Flutter/GeneratedPluginRegistrant.swift']);

  // Step 3: Read the contents
  final content = await registrantFile.readAsString();
  
  // Step 4: Remove cryptography_flutter references
  final modifiedContent = content
      .replaceAll('import cryptography_flutter\n', '')
      .replaceAll('  CryptographyFlutterPlugin.register(with: registry.registrar(forPlugin: "CryptographyFlutterPlugin"))\n', '');

  // Step 5: Write the modified contents back
  await registrantFile.writeAsString(modifiedContent);

  print('Successfully removed cryptography_flutter references from GeneratedPluginRegistrant.swift');

  // Step 6: Create a simple shell script to run before builds
  final shellScript = '''
#\!/bin/bash
echo "Applying macOS fixes for cryptography_flutter..."
chmod +w macos/Flutter/GeneratedPluginRegistrant.swift
sed -i '' '/import cryptography_flutter/d' macos/Flutter/GeneratedPluginRegistrant.swift
sed -i '' '/CryptographyFlutterPlugin/d' macos/Flutter/GeneratedPluginRegistrant.swift
echo "Fixes applied successfully."
''';

  await File('fix_macos_before_build.sh').writeAsString(shellScript);
  await Process.run('chmod', ['+x', 'fix_macos_before_build.sh']);

  print('Created fix_macos_before_build.sh - run this script before building for macOS.');
  print('Usage: ./fix_macos_before_build.sh && flutter build macos');
}
