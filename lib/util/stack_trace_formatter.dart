import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

/// Utility class to format stack traces for better readability in logs
class StackTraceFormatter {
  /// App package prefixes to highlight in stack traces
  static final List<String> _appPackages = [
    'package:nostrmo/',
    'package:plur/',
  ];

  /// Framework package prefixes to de-emphasize in stack traces 
  static final List<String> _frameworkPackages = [
    'package:flutter/',
    'package:provider/',
    'package:riverpod/',
    'dart:',
  ];

  /// Format a stack trace to be more readable
  /// 
  /// - Highlights app code
  /// - De-emphasizes framework code
  /// - Removes excessive frames if [compact] is true
  /// - Limits to [maxFrames] frames if specified
  static String format(
    StackTrace stackTrace, {
    bool compact = true,
    int? maxFrames,
    bool highlightAppCode = true,
  }) {
    // Convert stack trace to string
    final String stackTraceStr = stackTrace.toString();
    final List<String> lines = LineSplitter.split(stackTraceStr).toList();
    
    // Process each line
    final List<String> formatted = [];
    int appCodeFrames = 0;
    int frameworkFrames = 0;
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      
      // Check if this is app code or framework code
      final bool isAppCode = _appPackages.any((prefix) => line.contains(prefix));
      final bool isFrameworkCode = _frameworkPackages.any((prefix) => line.contains(prefix));
      
      // Format the line
      final String formattedLine = _formatStackTraceLine(
        line, 
        isAppCode: isAppCode,
        isFrameworkCode: isFrameworkCode,
        highlightAppCode: highlightAppCode,
      );
      
      // In compact mode, limit framework frames
      if (compact && isFrameworkCode) {
        frameworkFrames++;
        if (frameworkFrames > 3 && i < lines.length - 3) {
          // Only include the first few and last few framework frames
          if (frameworkFrames == 4) {
            formatted.add('  ... (${lines.length - 7} more frames) ...');
          }
          continue;
        }
      }
      
      // Update app code frame count
      if (isAppCode) {
        appCodeFrames++;
      }
      
      // Add the formatted line
      formatted.add(formattedLine);
      
      // Stop if we've reached the max frames
      if (maxFrames != null && formatted.length >= maxFrames) {
        if (i < lines.length - 1) {
          formatted.add('  ... (${lines.length - i - 1} more frames) ...');
        }
        break;
      }
    }
    
    return formatted.join('\n');
  }
  
  /// Format a single line of a stack trace
  static String _formatStackTraceLine(
    String line, {
    required bool isAppCode,
    required bool isFrameworkCode,
    required bool highlightAppCode,
  }) {
    if (!kDebugMode) {
      return line; // Skip formatting in release mode
    }
    
    if (isAppCode && highlightAppCode) {
      // Extract and format the filename for app code
      final fileInfo = _extractFileInfo(line);
      if (fileInfo != null) {
        return '  → ${fileInfo.fileName}:${fileInfo.lineNumber} - ${fileInfo.methodName}';
      }
      return '  → $line';
    } else if (isFrameworkCode) {
      // De-emphasize framework code
      return '  $line';
    } else {
      // Other code (like Dart SDK)
      return '  $line';
    }
  }
  
  /// Extract file information from a stack trace line
  static FileInfo? _extractFileInfo(String line) {
    // Match patterns like 'package:app/file.dart:123:45' or '#12 file.dart:123:45'
    final RegExp fileRegex = RegExp(r'(package:[^:]+|[^:]+\.dart):(\d+)(?::(\d+))?');
    final match = fileRegex.firstMatch(line);
    
    if (match != null) {
      final filePath = match.group(1) ?? '';
      final fileName = path.basename(filePath);
      final lineNumber = match.group(2) ?? '';
      
      // Extract the method name if possible
      String methodName = '';
      final RegExp methodRegex = RegExp(r'([a-zA-Z0-9_]+)\s');
      final methodMatch = methodRegex.firstMatch(line);
      if (methodMatch != null) {
        methodName = methodMatch.group(1) ?? '';
      }
      
      return FileInfo(fileName, lineNumber, methodName);
    }
    
    return null;
  }
}

/// Holds information about a file reference in a stack trace
class FileInfo {
  final String fileName;
  final String lineNumber;
  final String methodName;
  
  FileInfo(this.fileName, this.lineNumber, this.methodName);
} 