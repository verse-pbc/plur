// Custom web entrypoint to avoid package name issues
import 'dart:developer' as developer;
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Import the app's main file directly using a relative import
import '../lib/main.dart' as app;

void main() {
  // Enable better error logging
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    developer.log('Flutter error: ${details.exception}', 
      name: 'Web Entry',
      error: details.exception,
      stackTrace: details.stack
    );
  };

  // Use URL strategy for better web URLs (removes the # from the URL)
  setUrlStrategy(PathUrlStrategy());
  
  // Initialize the Flutter app with error handling
  try {
    developer.log('Starting Flutter app from web entrypoint', name: 'Web Entry');
    app.main();
  } catch (e, stack) {
    developer.log('Error initializing Flutter app', 
      name: 'Web Entry',
      error: e,
      stackTrace: stack
    );
    // Try to display error to user
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Error initializing app: $e'),
        ),
      ),
    ));
  }
} 