import 'dart:developer';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:nostr_sdk/nostr.dart';
import 'package:nostr_sdk/event.dart';

/// Utility class for handling notifications
/// Plur may receive remote notifications from Firebase Cloud Messaging.
/// If a notification is received while the app is in the foreground, it is not
/// automatically displayed and we generate and display a local notification.
/// If the app is in the background, the notification is displayed automatically.
class NotificationUtil {
  static final FlutterLocalNotificationsPlugin
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    description:
        'This channel is used for important notifications.', // description
    importance: Importance.high,
    playSound: true,
    showBadge: true,
    enableVibration: true,
    enableLights: true,
  );

  static Future<void> setUp() async {
    await _setUpLocalNotifications();
    _setupForegroundMessaging();
    _setupBackgroundClickHandler(_handleBackgroundNotificationClick);
  }

  /// Initializes _flutterLocalNotificationsPlugin with the proper configuration.
  static Future<void> _setUpLocalNotifications() async {
    // Skip initialization on web platform as it's not supported
    if (kIsWeb) {
      log('Skipping local notifications initialization on web platform');
      return;
    }

    try {
      // Initialize Flutter Local Notifications
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // Configure iOS-specific settings
      final DarwinInitializationSettings initializationSettingsDarwin =
          DarwinInitializationSettings(
        // Do not request permissions here - we handle them in AppDelegate
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
        // Additional iOS settings
        notificationCategories: [
          DarwinNotificationCategory(
            'default_category',
            actions: [
              DarwinNotificationAction.plain(
                'open',
                'Open',
                options: {DarwinNotificationActionOption.foreground},
              ),
            ],
          ),
        ],
      );

      final InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
        macOS: initializationSettingsDarwin, // Also set for macOS
      );

      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse:
            (NotificationResponse notificationResponse) {
          // Handle notification tap in app
          log('Notification clicked: ${notificationResponse.payload}');
          log('Notification id: ${notificationResponse.id}');
          log('Notification action: ${notificationResponse.actionId}');
          log('Notification input: ${notificationResponse.input}');

          // You could route to a specific page here based on the notification
        },
      );

      // Create the Android notification channel (Android only)
      if (Platform.isAndroid) {
        await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(_channel);
      }
    } catch (e) {
      log('Error initializing local notifications: $e');
    }
  }

  /// Set up foreground message handler to show local notifications when app
  /// receives a remote notification while open.
  static void _setupForegroundMessaging() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log("Got a message whilst in the foreground!");
      log("Message data: ${message.data}");

      RemoteNotification? notification = message.notification;

      // On web platform, we don't need to show a custom notification
      // as the browser will handle it
      if (kIsWeb) {
        log("Web platform: browser will handle notification display");
        return;
      }

      // Show a local notification on mobile platforms
      try {
        if (notification != null) {
          const AndroidNotificationDetails androidPlatformChannelSpecifics =
              AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription:
                'This channel is used for important notifications.',
            importance: Importance.high,
            priority: Priority.high,
            showWhen: true,
          );

          const DarwinNotificationDetails iOSPlatformChannelSpecifics =
              DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          );

          const NotificationDetails platformChannelSpecifics =
              NotificationDetails(
            android: androidPlatformChannelSpecifics,
            iOS: iOSPlatformChannelSpecifics,
          );

          _flutterLocalNotificationsPlugin.show(
            notification.hashCode,
            notification.title,
            notification.body,
            platformChannelSpecifics,
            payload: message.data.toString(),
          );
        }
      } catch (e) {
        log("Error showing local notification: $e");
      }
    });
  }

  /// Request notification permissions
  static Future<void> requestPermissions() async {
    // Skip platform-specific code on web
    if (!kIsWeb) {
      if (Platform.isAndroid) {
        try {
          // Create the Android notification channel first
          final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
              _flutterLocalNotificationsPlugin
                  .resolvePlatformSpecificImplementation<
                      AndroidFlutterLocalNotificationsPlugin>();

          if (androidImplementation != null) {
            // For Android 13+ (SDK 33+), request POST_NOTIFICATIONS permission
            // The flutter_local_notifications v16.3.0 changed how permissions work
            final bool? result =
                await androidImplementation.areNotificationsEnabled();
            log('Android notifications enabled: $result');

            // If notifications are not enabled, request permissions through Firebase
            // The Firebase permission request will trigger the system permission dialog
            if (result == false) {
              log('Android notifications not enabled, will request via Firebase');
            }

            // Create notification channel
            await androidImplementation.createNotificationChannel(_channel);
            log('Android notification channel prepared');
          }
        } catch (e) {
          log('Error preparing Android notification channel: $e');
        }
      } else if (Platform.isIOS) {
        try {
          final IOSFlutterLocalNotificationsPlugin? iosImplementation =
              _flutterLocalNotificationsPlugin
                  .resolvePlatformSpecificImplementation<
                      IOSFlutterLocalNotificationsPlugin>();

          final bool? result = await iosImplementation?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );

          log('iOS local notification permission result: $result');

          // Also get status of system permissions via Firebase
          final settings =
              await FirebaseMessaging.instance.getNotificationSettings();
          log('iOS Firebase notification status: ${settings.authorizationStatus}');
        } catch (e) {
          log('Error requesting iOS notification permissions: $e');
        }
      }
    }

    // Request permission for Firebase Messaging
    NotificationSettings settings =
        await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    log('User granted permission: ${settings.authorizationStatus}');
  }

  /// Get the Firebase Cloud Messaging token
  static Future<String?> getToken() async {
    String? token = await FirebaseMessaging.instance.getToken();
    log('FCM Token: $token');
    return token;
  }

  /// Set up background message handlers
  static void _setupBackgroundClickHandler(Function(RemoteMessage) callback) {
    try {
      // Handle notification click when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen(callback);

      // Check if app was opened from a notification when terminated
      FirebaseMessaging.instance.getInitialMessage().then((message) {
        if (message != null) {
          callback(message);
        }
      });
    } catch (e) {
      log("Error setting up background messaging: $e");
    }
  }

  static void _handleBackgroundNotificationClick(RemoteMessage message) {
    log("Notification clicked with data: ${message.data}");
    // Navigate to appropriate screen based on message data
  }

  /// Register an FCM token with the relay by sending a kind 3079 event
  /// Returns true if registration was submitted for publishing successfully,
  /// false otherwise.
  static Future<bool> registerTokenWithRelay({
    required String token,
    required Nostr nostr,
    required String relayUrl,
  }) async {
    return _sendTokenEventToRelay(
      token: token,
      nostr: nostr,
      relayUrl: relayUrl,
      eventKind: 3079,
    );
  }

  /// Deregister an FCM token with the relay by sending a kind 3080 event
  /// Returns true if deregistration was submitted for publish successfully,
  /// false otherwise
  static Future<bool> deregisterTokenWithRelay({
    required String token,
    required Nostr nostr,
    required String relayUrl,
  }) async {
    return _sendTokenEventToRelay(
      token: token,
      nostr: nostr,
      relayUrl: relayUrl,
      eventKind: 3080,
    );
  }

  /// Internal method to send token events to relay
  static Future<bool> _sendTokenEventToRelay({
    required String token,
    required Nostr nostr,
    required String relayUrl,
    required int eventKind,
  }) async {
    try {
      final expirationTimestamp = _registrationExpirationTimestamp();

      final event = Event(
        nostr.publicKey,
        eventKind,
        [
          ['expiration', expirationTimestamp.toString()]
        ],
        token,
      );

      final result = await nostr
          .sendEvent(event, tempRelays: [relayUrl], targetRelays: [relayUrl]);
      return result != null;
    } catch (e) {
      log('Error sending token event to relay: $e');
      return false;
    }
  }

  /// Returns the date that token registration events should expire as a unix
  /// timestamp.
  static int _registrationExpirationTimestamp() {
    return (DateTime.now().millisecondsSinceEpoch ~/ 1000) + (7 * 24 * 60 * 60);
  }
}
