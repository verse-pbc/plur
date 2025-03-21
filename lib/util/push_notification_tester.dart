import 'dart:convert';
import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Utility class for testing push notifications during development
class PushNotificationTester {
  static final Dio _dio = Dio();

  /// Get the current FCM token for the device
  static Future<String?> getDeviceToken() async {
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      log('Error getting FCM token: $e');
      return null;
    }
  }

  /// Send a test notification to the current device
  ///
  /// This would typically be called from a debug/test screen in your app
  static Future<void> sendTestNotification({
    required String token,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Note: In a real implementation, you would never include your Firebase server key in client code
      // This is just for testing purposes during development
      // You would typically have a backend service that sends notifications

      // This is a fake key for demonstration purposes only
      const String fcmServerKey =
          'REPLACE_WITH_YOUR_FCM_SERVER_KEY_DURING_TESTING';

      final response = await _dio.post(
        'https://fcm.googleapis.com/fcm/send',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'key=$fcmServerKey',
          },
        ),
        data: jsonEncode({
          'to': token,
          'notification': {
            'title': title,
            'body': body,
            'sound': 'default',
          },
          'data': data ?? {},
          'priority': 'high',
        }),
      );

      log('Test notification sent: ${response.statusCode}');
      log('Response: ${response.data}');
    } catch (e) {
      log('Error sending test notification: $e');
    }
  }

  /// Trigger a local test notification (doesn't require FCM)
  static Future<void> triggerLocalTestNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
          FlutterLocalNotificationsPlugin();

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        channelDescription: 'This channel is used for important notifications.',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
      );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      // Show the notification
      await flutterLocalNotificationsPlugin.show(
        0, // Notification ID
        title,
        body,
        platformChannelSpecifics,
        payload: json.encode(data ?? {}),
      );

      log('Local test notification triggered');
    } catch (e) {
      log('Error triggering local test notification: $e');
    }
  }
}
