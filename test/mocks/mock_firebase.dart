import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeFirebaseAppPlatform extends FirebaseAppPlatform {
  FakeFirebaseAppPlatform({String? name, FirebaseOptions? options})
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

class FakeFirebasePlatform extends FirebasePlatform {
  final _app = FakeFirebaseAppPlatform();
  final _apps = <FirebaseAppPlatform>[];

  FakeFirebasePlatform() {
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

// Setup function that registers the fake platform implementation
Future<void> setupMockFirebase() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Register the fake implementation
  Firebase.delegatePackingProperty = FakeFirebasePlatform();
}
