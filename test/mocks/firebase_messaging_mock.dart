import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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
  // Singleton instance of MockFirebaseAppPlatform
  final MockFirebaseAppPlatform _mockApp = MockFirebaseAppPlatform();

  @override
  Future<FirebaseAppPlatform> initializeApp({
    String? name,
    FirebaseOptions? options,
  }) async {
    return _mockApp;
  }

  @override
  FirebaseAppPlatform app([String name = defaultFirebaseAppName]) {
    return _mockApp;
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

/// Mock implementation of FirebaseMessaging
class MockFirebaseMessaging extends Mock implements FirebaseMessaging {
  static final MockFirebaseMessaging _instance = MockFirebaseMessaging._();
  late StreamController<String> _tokenRefreshController;
  String _mockToken = 'test_fcm_token';
  bool _autoInitEnabled = true;

  MockFirebaseMessaging._() {
    _tokenRefreshController = StreamController<String>.broadcast();
  }

  static MockFirebaseMessaging get instance => _instance;

  @override
  Stream<String> get onTokenRefresh => _tokenRefreshController.stream;

  @override
  Future<String?> getToken({String? vapidKey}) async {
    return _mockToken.isEmpty ? null : _mockToken;
  }

  void setMockToken(String token) {
    _mockToken = token;
  }

  void simulateTokenRefresh(String newToken) {
    _mockToken = newToken;
    _tokenRefreshController.add(newToken);
  }

  void reset() {
    if (!_tokenRefreshController.isClosed) {
      _tokenRefreshController.close();
    }
    _tokenRefreshController = StreamController<String>.broadcast();
    _mockToken = 'test_fcm_token';
    _autoInitEnabled = true;
  }

  @override
  bool get isAutoInitEnabled => _autoInitEnabled;
}

/// Mock implementation of FirebaseMessagingPlatform
class MockFirebaseMessagingPlatform extends FirebaseMessagingPlatform {
  final MockFirebaseMessaging _messaging = MockFirebaseMessaging.instance;

  MockFirebaseMessagingPlatform() : super();

  @override
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  @override
  Future<String?> getToken({String? vapidKey}) =>
      _messaging.getToken(vapidKey: vapidKey);

  @override
  bool get isAutoInitEnabled => _messaging.isAutoInitEnabled;

  @override
  FirebaseMessagingPlatform delegateFor({FirebaseApp? app}) {
    return this;
  }

  @override
  FirebaseMessagingPlatform setInitialValues({
    bool? isAutoInitEnabled,
  }) {
    return this;
  }

  @override
  Future<NotificationSettings> requestPermission({
    bool alert = true,
    bool announcement = false,
    bool badge = true,
    bool carPlay = false,
    bool criticalAlert = false,
    bool providesAppNotificationSettings = false,
    bool provisional = false,
    bool sound = true,
  }) async {
    return const NotificationSettings(
      alert: AppleNotificationSetting.enabled,
      announcement: AppleNotificationSetting.disabled,
      authorizationStatus: AuthorizationStatus.authorized,
      badge: AppleNotificationSetting.enabled,
      carPlay: AppleNotificationSetting.disabled,
      criticalAlert: AppleNotificationSetting.disabled,
      lockScreen: AppleNotificationSetting.enabled,
      notificationCenter: AppleNotificationSetting.enabled,
      providesAppNotificationSettings: AppleNotificationSetting.disabled,
      showPreviews: AppleShowPreviewSetting.always,
      sound: AppleNotificationSetting.enabled,
      timeSensitive: AppleNotificationSetting.disabled,
    );
  }
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

  // Reset the mock instance
  MockFirebaseMessaging.instance.reset();

  // Setup method channel mock for Firebase Messaging
  const MethodChannel channel =
      MethodChannel('plugins.flutter.io/firebase_messaging');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall call) async {
    switch (call.method) {
      case 'Messaging#getToken':
        return MockFirebaseMessaging.instance._mockToken;
      default:
        return null;
    }
  });

  // Register the mock messaging platform with our mock instance
  FirebaseMessagingPlatform.instance = MockFirebaseMessagingPlatform();
}
