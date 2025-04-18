import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

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

  @override
  Future<void> setAutomaticDataCollectionEnabled(bool enabled) async {}

  @override
  Future<void> setAutomaticResourceManagementEnabled(bool enabled) async {}

  @override
  bool get isAutomaticDataCollectionEnabled => false;
}

/// Setup function that registers the mock implementation for Firebase Core
Future<void> setupMockFirebase() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Register the mock Firebase platform implementation
  FirebasePlatform.instance = MockFirebasePlatform();
}
