// Copyright (c) 2024, Plur Inc.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

/// A collection of mock implementations for Firebase Core functionality.
/// These mocks are primarily used for basic Firebase initialization in tests
/// that don't require complex Firebase features.
///
/// This is particularly useful for:
/// - Sign up/login tests
/// - Tests that need Firebase Core initialized but don't use specific Firebase services
/// - Basic Firebase configuration tests
///
/// For tests that require Firebase Messaging functionality, use the mocks in
/// `firebase_messaging_mock.dart` instead.

/// Mock implementation of FirebaseAppPlatform for testing
class MockFirebaseAppPlatform extends FirebaseAppPlatform {
  MockFirebaseAppPlatform({String? name, FirebaseOptions? options})
      : super(name ?? '[DEFAULT]', options ?? _defaultOptions);

  static FirebaseOptions get _defaultOptions => const FirebaseOptions(
        apiKey: 'test-api-key',
        appId: 'test-app-id',
        messagingSenderId: 'test-sender-id',
        projectId: 'test-project',
      );

  @override
  FirebaseOptions get options => _defaultOptions;

  @override
  bool get isAutomaticDataCollectionEnabled => false;

  @override
  Future<void> delete() async {}

  @override
  Future<void> setAutomaticDataCollectionEnabled(bool enabled) async {}

  @override
  Future<void> setAutomaticResourceManagementEnabled(bool enabled) async {}
}

/// Mock implementation of FirebasePlatform for testing
class MockFirebasePlatform extends FirebasePlatform {
  final _app = MockFirebaseAppPlatform();
  final _apps = <FirebaseAppPlatform>[];

  MockFirebasePlatform() {
    _apps.add(_app);
  }

  @override
  FirebaseAppPlatform app([String name = defaultFirebaseAppName]) {
    return _app;
  }

  @override
  Future<FirebaseAppPlatform> initializeApp({
    String? name,
    FirebaseOptions? options,
  }) async {
    return _app;
  }

  @override
  List<FirebaseAppPlatform> get apps => _apps;
}

/// Setup function that registers the mock implementation for Firebase Core.
/// This should be called in the setUpAll() function of your test file if you
/// need basic Firebase functionality.
///
/// Example:
/// ```dart
/// setUpAll(() async {
///   await setupFirebaseCoreMocks();
///   // ... other setup code
/// });
/// ```
Future<void> setupFirebaseCoreMocks() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Register the mock Firebase platform implementation
  FirebasePlatform.instance = MockFirebasePlatform();
}
