import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:nostrmo/util/notification_util.dart';
import 'package:nostrmo/util/push_notification_tester.dart';
import 'package:share_plus/share_plus.dart';

/// A test widget to help with testing push notifications
class PushNotificationTestWidget extends StatefulWidget {
  const PushNotificationTestWidget({super.key});

  @override
  State<PushNotificationTestWidget> createState() =>
      _PushNotificationTestWidgetState();
}

class _PushNotificationTestWidgetState
    extends State<PushNotificationTestWidget> {
  String? _token;
  bool _isLoading = false;
  String _permissionStatus = 'Unknown';
  final TextEditingController _titleController =
      TextEditingController(text: 'Test Notification');
  final TextEditingController _bodyController =
      TextEditingController(text: 'This is a test notification');

  @override
  void initState() {
    super.initState();
    _getToken();
    _checkPermissionStatus();
  }

  Future<void> _getToken() async {
    setState(() => _isLoading = true);
    try {
      final token = await NotificationUtil.getToken();
      setState(() {
        _token = token;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting token: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkPermissionStatus() async {
    try {
      final settings =
          await FirebaseMessaging.instance.getNotificationSettings();

      setState(() {
        _permissionStatus =
            settings.authorizationStatus.toString().split('.').last;
      });

      // Log detailed permission status for debugging
      dev.log('Authorization status: ${settings.authorizationStatus}');
      dev.log('Alert setting: ${settings.alert}');
      dev.log('Announcement setting: ${settings.announcement}');
      dev.log('Badge setting: ${settings.badge}');
      dev.log('Sound setting: ${settings.sound}');
      dev.log('Critical alert setting: ${settings.criticalAlert}');

      // Check if the token exists too
      final token = await FirebaseMessaging.instance.getToken();
      dev.log('FCM Token exists: ${token != null}');

      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Notification permissions are not fully granted. Notifications may not appear.'),
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _permissionStatus = 'Error checking: $e';
      });
      dev.log('Error checking permission status: $e');
    }
  }

  Future<void> _requestPermissions() async {
    setState(() => _isLoading = true);
    try {
      await NotificationUtil.requestPermissions();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification permissions requested')),
      );
      // Check the status after requesting
      await _checkPermissionStatus();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error requesting permissions: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _shareToken() async {
    if (_token == null) return;

    try {
      await Share.share('My FCM Token: $_token');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing token: $e')),
      );
    }
  }

  Future<void> _triggerLocalNotification() async {
    await PushNotificationTester.triggerLocalTestNotification(
      title: _titleController.text,
      body: _bodyController.text,
      data: {'type': 'test', 'id': '123'},
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Local notification triggered')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Push Notification Test'),
        actions: [
          if (_isLoading)
            Container(
              margin: const EdgeInsets.all(14),
              width: 24,
              height: 24,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Push Notification Testing',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Permission status card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.security),
                        const SizedBox(width: 8),
                        const Text(
                          'Permission Status:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _permissionStatus,
                            style: TextStyle(
                              color: _permissionStatus.toLowerCase() ==
                                      'authorized'
                                  ? Colors.green
                                  : _permissionStatus.toLowerCase() == 'denied'
                                      ? Colors.red
                                      : Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          tooltip: 'Refresh status',
                          onPressed: _checkPermissionStatus,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _requestPermissions,
                      child: const Text('Request Permissions'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Token card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.vpn_key),
                        const SizedBox(width: 8),
                        const Text(
                          'FCM Token:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          tooltip: 'Refresh token',
                          onPressed: _isLoading ? null : _getToken,
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy),
                          tooltip: 'Copy token to clipboard',
                          onPressed: _token == null || _isLoading
                              ? null
                              : () {
                                  Clipboard.setData(
                                      ClipboardData(text: _token!));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('Token copied to clipboard')),
                                  );
                                },
                        ),
                        IconButton(
                          icon: const Icon(Icons.share),
                          tooltip: 'Share token',
                          onPressed:
                              _token == null || _isLoading ? null : _shareToken,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: SelectableText(
                        _token ?? 'Loading token...',
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Test notification card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.notifications),
                        SizedBox(width: 8),
                        Text(
                          'Test Notification',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Notification Title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _bodyController,
                      decoration: const InputDecoration(
                        labelText: 'Notification Body',
                        border: OutlineInputBorder(),
                      ),
                      minLines: 2,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed:
                                _isLoading ? null : _triggerLocalNotification,
                            icon: const Icon(Icons.send),
                            label: const Text('Trigger Local Notification'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Info card
            Card(
              color: Colors.blue.shade50,
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Developer Info',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'To send actual test notifications, you need to use:',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                    SizedBox(height: 4),
                    Text('• Firebase console'),
                    Text('• A server with your FCM server key'),
                    Text('• The Firebase Admin SDK'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }
}
