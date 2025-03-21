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

### Local Notifications

1. Navigate to the Settings, then tap Push Notification Test at the bottom
2. Check the Permission Status - it should show "AUTHORIZED"
3. Test local notifications using the "Test System Channel" button
4. Subscribe to the test topic if you want to test broadcast messages

### Testing with Firebase Console

1. Launch Plur and copy your device FCM token from the Test Push Notifications screen.
2. Log in to the [Firebase Console](https://console.firebase.google.com/)
3. Navigate to [Messaging](https://console.firebase.google.com/u/0/project/plur-623b0/messaging).
4. Click "New Campaign" -> "Notifications"
5. Enter notification details (title, message)
6. Click "Send Test Message"
7. Paste in your FCM token 
8. Click "Test" to send the notification.

You should see the notification appear on your device.