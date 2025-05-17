import 'dart:io';

/// Simple pre-commit hook script to enforce logging best practices
/// Run with: dart scripts/lint_logging.dart [files...]
void main(List<String> arguments) {
  // If no arguments are provided, scan staged files
  final List<String> filesToCheck = arguments.isEmpty
      ? getStagedDartFiles()
      : arguments.where((path) => path.endsWith('.dart')).toList();

  if (filesToCheck.isEmpty) {
    print('No Dart files to check.');
    exit(0);
  }

  print('Checking ${filesToCheck.length} Dart files for logging issues...');
  
  int issues = 0;
  
  for (final file in filesToCheck) {
    final violations = checkFile(file);
    issues += violations.length;
    
    if (violations.isNotEmpty) {
      print('\n${file}:');
      for (final violation in violations) {
        print('  Line ${violation.lineNumber}: ${violation.message}');
        print('    ${violation.line.trim()}');
      }
    }
  }
  
  if (issues > 0) {
    print('\nFound $issues logging issues. Please fix them before committing.');
    exit(1);
  } else {
    print('\nNo logging issues found. ✓');
    exit(0);
  }
}

/// Get a list of staged Dart files from Git
List<String> getStagedDartFiles() {
  try {
    final result = Process.runSync('git', ['diff', '--cached', '--name-only', '--diff-filter=ACMR']);
    if (result.exitCode != 0) {
      print('Error getting staged files: ${result.stderr}');
      return [];
    }
    
    final output = result.stdout as String;
    return output
        .split('\n')
        .where((line) => line.trim().isNotEmpty && line.endsWith('.dart'))
        .toList();
  } catch (e) {
    print('Error executing git command: $e');
    return [];
  }
}

/// Check a file for logging violations
List<Violation> checkFile(String filePath) {
  final file = File(filePath);
  if (!file.existsSync()) {
    print('File not found: $filePath');
    return [];
  }
  
  final List<Violation> violations = [];
  final lines = file.readAsLinesSync();
  
  for (int i = 0; i < lines.length; i++) {
    final line = lines[i];
    final lineNumber = i + 1;
    
    // Skip commented lines
    if (line.trim().startsWith('//')) continue;
    
    // Check for direct print statements
    if (RegExp(r'\bprint\s*\(').hasMatch(line)) {
      violations.add(Violation(
        lineNumber,
        line,
        'Use logger.d() instead of print()',
      ));
    }
    
    // Check for debugPrint
    if (RegExp(r'\bdebugPrint\s*\(').hasMatch(line)) {
      violations.add(Violation(
        lineNumber,
        line,
        'Use logger.d() instead of debugPrint()',
      ));
    }
    
    // Check for developer.log
    if (RegExp(r'\bdeveloper\.log\s*\(').hasMatch(line)) {
      violations.add(Violation(
        lineNumber,
        line,
        'Use logger.d() instead of developer.log()',
      ));
    }
    
    // Incorrect logger usage (without category)
    if (RegExp(r'\blogger\.(v|d|i|w|e|wtf)\s*\(\s*[\'"]').hasMatch(line) &&
        !line.contains('LogCategory.')) {
      violations.add(Violation(
        lineNumber,
        line,
        'Consider adding a LogCategory to logger calls',
      ));
    }
  }
  
  return violations;
}

/// Represents a logging violation in the code
class Violation {
  final int lineNumber;
  final String line;
  final String message;
  
  Violation(this.lineNumber, this.line, this.message);
} 