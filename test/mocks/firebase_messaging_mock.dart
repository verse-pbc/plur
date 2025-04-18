import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging_platform_interface/firebase_messaging_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';

// Mock implementation of FirebasePlatform
class MockFirebasePlatform extends Mock
    with MockPlatformInterfaceMixin
    implements FirebasePlatform {
  @override
  Future<FirebaseAppPlatform> initializeApp({
    String? name,
    FirebaseOptions? options,
  }) async {
    return MockFirebaseAppPlatform();
  }

  @override
  FirebaseAppPlatform app([String name = defaultFirebaseAppName]) {
    return MockFirebaseAppPlatform();
  }
}

// Mock implementation of FirebaseAppPlatform
class MockFirebaseAppPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements FirebaseAppPlatform {
  @override
  String get name => '[DEFAULT]';

  @override
  FirebaseOptions get options => const FirebaseOptions(
        apiKey: 'mock-api-key',
        appId: 'mock-app-id',
        messagingSenderId: 'mock-sender-id',
        projectId: 'mock-project-id',
      );
}

/// Mock implementation of FirebaseMessagingPlatform
class MockFirebaseMessaging extends FirebaseMessagingPlatform {
  // Controller for the onTokenRefresh stream
  final StreamController<String> _tokenRefreshController =
      StreamController<String>.broadcast();
  String _mockToken = 'test_fcm_token';
  bool _autoInitEnabled = true;

  MockFirebaseMessaging() : super();

  static MockFirebaseMessaging get instance {
    return FirebaseMessagingPlatform.instance as MockFirebaseMessaging;
  }

  @override
  FirebaseMessagingPlatform delegateFor({FirebaseApp? app}) {
    return this;
  }

  @override
  FirebaseMessagingPlatform setInitialValues({
    bool? isAutoInitEnabled,
  }) {
    _autoInitEnabled = isAutoInitEnabled ?? true;
    return this;
  }

  @override
  Future<String?> getToken({String? vapidKey}) async {
    return _mockToken.isEmpty ? null : _mockToken;
  }

  // Set a custom token value (useful for testing different scenarios)
  void setMockToken(String token) {
    _mockToken = token;
  }

  // Allow tests to emit token refresh events
  void simulateTokenRefresh(String newToken) {
    _mockToken = newToken;
    _tokenRefreshController.add(newToken);
  }

  @override
  Stream<String> get onTokenRefresh => _tokenRefreshController.stream;

  // Clean up resources
  void dispose() {
    _tokenRefreshController.close();
  }

  // Minimum overrides to prevent runtime errors
  @override
  Future<RemoteMessage?> getInitialMessage() async => null;

  @override
  bool get isAutoInitEnabled => _autoInitEnabled;
}

void setupFirebaseCoreMocks() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Setup method channel mock
  const MethodChannel channel =
      MethodChannel('plugins.flutter.io/firebase_core');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall call) async {
    if (call.method == 'Firebase#initializeCore') {
      return [
        {
          'name': defaultFirebaseAppName,
          'options': {
            'apiKey': 'mock-api-key',
            'appId': 'mock-app-id',
            'messagingSenderId': 'mock-sender-id',
            'projectId': 'mock-project-id',
          },
          'pluginConstants': {},
        }
      ];
    }
    if (call.method == 'Firebase#initializeApp') {
      return {
        'name': call.arguments['appName'],
        'options': call.arguments['options'],
        'pluginConstants': {},
      };
    }
    return null;
  });

  // Setup Firebase platform interface mock
  FirebasePlatform.instance = MockFirebasePlatform();
}

// Get the current mock instance
MockFirebaseMessaging getMockFirebaseMessaging() {
  return MockFirebaseMessaging.instance;
}

void setupFirebaseMessagingMocks() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Setup Firebase core mocks
  setupFirebaseCoreMocks();

  // Register the mock messaging platform
  FirebaseMessagingPlatform.instance = MockFirebaseMessaging();
}
