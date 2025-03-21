# Push Notifications Testing Guide

This guide provides instructions for testing and troubleshooting push notifications in the app.

## Overview

The app uses Firebase Cloud Messaging (FCM) for cross-platform push notifications. The implementation includes:

1. Permission handling for Android and iOS
2. Local notifications display using flutter_local_notifications
3. Background message handling
4. Foreground message handling
5. Platform-specific configurations

## Testing Push Notifications

### Using the Test Widget

1. Navigate to the Push Notification Test screen in the app
2. Check the Permission Status - it should show "AUTHORIZED"
3. Copy your FCM token (you'll need this to send test notifications)
4. Test local notifications using the "Test System Channel" button
5. Subscribe to the test topic if you want to test broadcast messages

### Testing with Firebase Console

1. Log in to the [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Navigate to Messaging (in the Engage section)
4. Click "Send your first message"
5. Enter notification details (title, message)
6. Under "Target", select "Single device" and paste your FCM token
7. Complete the message setup and send

### Testing with cURL (for Developers)

You can send a test notification using cURL:

```bash
curl -X POST -H "Authorization: key=YOUR_SERVER_KEY" -H "Content-Type: application/json" \
-d '{
  "to": "DEVICE_FCM_TOKEN",
  "notification": {
    "title": "Test Notification",
    "body": "This is a test message"
  },
  "data": {
    "type": "test",
    "id": "123"
  }
}' \
https://fcm.googleapis.com/fcm/send
```

Replace `YOUR_SERVER_KEY` with your Firebase project server key and `DEVICE_FCM_TOKEN` with the token shown in the app.

## Troubleshooting

### iOS Issues

1. **Permissions**: Make sure you've allowed notifications in iOS Settings for the app
2. **Developer Settings**: Check if "Show Preview" is enabled in iOS Settings > Notifications
3. **Certificates**: For production, ensure APNs certificates are correctly configured in Firebase
4. **Entitlements**: Verify `aps-environment` is set in the entitlements file

Common iOS debugging steps:
- Check Xcode console logs for registration errors
- Verify APNs token registration in AppDelegate logs
- Test with a system notification first using the "Test System Channel" button

### Android Issues

1. **Channels**: Make sure the notification channel is created correctly
2. **Permissions**: For Android 13+, verify the NOTIFICATION permission is granted
3. **Firebase Token**: Ensure the FCM token is successfully generated

### General Issues

If notifications aren't working:
1. Check Permission Status in the test widget
2. Verify the FCM token is generated
3. Look for error messages in the device logs
4. Test with a simple system notification first
5. Make sure the device has internet connectivity

## Implementation Details

The push notification implementation consists of several components:

1. **AppDelegate.swift**: Handles iOS notifications setup and APNs token registration
2. **AndroidManifest.xml**: Contains Android notification permissions and services
3. **notification_util.dart**: Utility class for notification handling
4. **push_notification_tester.dart**: Utility for testing notifications
5. **main.dart**: Sets up Firebase and background handlers

## Adding Custom Notification Handling

To handle custom data in notifications:

1. Add custom data to the "data" field when sending notifications
2. Handle this data in the `_handleNotificationClick` method in main.dart
3. Implement routing logic based on notification data