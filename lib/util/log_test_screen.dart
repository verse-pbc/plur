import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nostrmo/component/styled_input_field_widget.dart';
import 'package:nostrmo/util/app_logger.dart';
import 'package:nostrmo/util/log_filter_dialog.dart';

/// A screen for testing and demonstrating the logging functionality
class LogTestScreen extends StatefulWidget {
  /// Constructor
  const LogTestScreen({Key? key}) : super(key: key);

  @override
  State<LogTestScreen> createState() => _LogTestScreenState();
}

class _LogTestScreenState extends State<LogTestScreen> {
  final _messageController = TextEditingController(text: 'Test log message');
  LogCategory _selectedCategory = LogCategory.core;
  bool _includeError = false;
  bool _includeStackTrace = false;
  String _selectedLevel = 'verbose';
  bool _isLoading = false;
  
  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  /// Get the current error and stack trace if enabled
  (dynamic, StackTrace?) _getErrorAndStack() {
    if (!_includeError) return (null, null);
    
    final error = Exception('Test error');
    final stack = _includeStackTrace ? StackTrace.current : null;
    
    return (error, stack);
  }

  /// Log a message at a specific level
  void _logWithSelectedLevel() {
    final message = _messageController.text;
    
    // For testing with error and stack trace
    Exception? error;
    StackTrace? stack;
    
    if (_includeError) {
      error = Exception('Test exception for logging');
      stack = StackTrace.current;
    }
    
    // Log with the selected level and chosen parameters
    switch (_selectedLevel) {
      case 'verbose':
        logger.v(message, error, stack, _selectedCategory);
        break;
      case 'debug':
        logger.d(message, error, stack, _selectedCategory);
        break;
      case 'info':
        logger.i(message, error, stack, _selectedCategory);
        break;
      case 'warning':
        logger.w(message, error, stack, _selectedCategory);
        break;
      case 'error':
        logger.e(message, error, stack, _selectedCategory);
        break;
      case 'wtf':
        logger.wtf(message, error, stack, _selectedCategory);
        break;
    }
  }

  /// Test all log levels
  void _testAllLevels() {
    // Test all log levels with the selected category
    logger.v('This is a VERBOSE message', null, null, _selectedCategory);
    logger.d('This is a DEBUG message', null, null, _selectedCategory);
    logger.i('This is an INFO message', null, null, _selectedCategory);
    logger.w('This is a WARNING message', null, null, _selectedCategory);
    logger.e('This is an ERROR message', null, null, _selectedCategory);
    logger.wtf('This is a WHAT A TERRIBLE FAILURE message', null, null, _selectedCategory);
  }

  /// Test category filtering
  void _testAllCategories() {
    // Test all categories with DEBUG level
    logger.d('Core category log message', null, null, LogCategory.core);
    logger.d('Network category log message', null, null, LogCategory.network);
    logger.d('Database category log message', null, null, LogCategory.database);
    logger.d('UI category log message', null, null, LogCategory.ui);
    logger.d('Auth category log message', null, null, LogCategory.auth);
    logger.d('Groups category log message', null, null, LogCategory.groups);
    logger.d('Events category log message', null, null, LogCategory.events);
    logger.d('Performance category log message', null, null, LogCategory.performance);
  }

  /// Test logging with errors and stack traces
  void _testError() {
    try {
      // Simulate an error
      throw Exception('This is a test exception');
    } catch (e, stack) {
      logger.e('Caught an exception during testing', e, stack, _selectedCategory);
    }
  }

  /// Test a simulated network request with logging
  void _simulateNetworkRequest() {
    // Simulate a network request with logging
    logger.d('Starting simulated network request', null, null, LogCategory.network);
    
    Future.delayed(const Duration(seconds: 1), () {
      try {
        logger.d('GET: https://api.example.com/data', null, null, LogCategory.network);
        
        // 50% chance of success or error
        if (Random().nextBool()) {
          // Success
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
              
              logger.d('Network request completed successfully', null, null, LogCategory.network);
              logger.v('Response data: {"status": "success", "data": {...}}', null, null, LogCategory.network);
            }
          });
        } else {
          // Error
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted) {
              final e = Exception('API Error: 503 Service Unavailable');
              final stack = StackTrace.current;
              
              setState(() {
                _isLoading = false;
              });
              
              logger.e('Network request failed', e, stack, LogCategory.network);
            }
          });
        }
      } catch (e, stack) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          logger.e('Error in network simulation', e, stack, LogCategory.network);
        }
      }
    });
  }

  /// Show the log filter dialog
  void _showFilterDialog() {
    LogFilterDialog.show(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logging Test & Verification'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Configure Log Filters',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Custom message input
            StyledInputFieldWidget(
              controller: _messageController,
              hintText: 'Log Message',
            ),
            const SizedBox(height: 16),
            
            // Category selection
            DropdownButtonFormField<LogCategory>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Log Category',
                border: OutlineInputBorder(),
              ),
              items: LogCategory.values.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category.toString().split('.').last),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCategory = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            
            // Error options
            Row(
              children: [
                Expanded(
                  child: CheckboxListTile(
                    title: const Text('Include Error'),
                    value: _includeError,
                    onChanged: (value) {
                      setState(() {
                        _includeError = value ?? false;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: CheckboxListTile(
                    title: const Text('Include Stack Trace'),
                    value: _includeStackTrace,
                    onChanged: (value) {
                      setState(() {
                        _includeStackTrace = value ?? false;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Log level buttons
            const Text('Log at specific level:'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () => _logWithSelectedLevel(),
                  child: const Text('Log'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Test scenario buttons
            const Text('Test Scenarios:'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _testAllLevels,
                  child: const Text('Test All Levels'),
                ),
                ElevatedButton(
                  onPressed: _testAllCategories,
                  child: const Text('Test All Categories'),
                ),
                ElevatedButton(
                  onPressed: _testError,
                  child: const Text('Test Error Logging'),
                ),
                ElevatedButton(
                  onPressed: _simulateNetworkRequest,
                  child: const Text('Test Network Request'),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            const Text(
              'Check the console output to see the logs. Use the filter button in the app bar to configure log filtering.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
} 