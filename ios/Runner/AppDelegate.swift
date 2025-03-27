import UIKit
import Flutter
import UserNotifications
import FirebaseCore
import FirebaseMessaging

@main
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Needed by FlutterLocalNotificationsPlugin
        UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
        
        // Set messaging delegate for Firebase
        Messaging.messaging().delegate = self
        
        // Log FCM token for debugging
        Messaging.messaging().token { token, error in
            if let error = error {
                print("Error fetching FCM registration token: \(error)")
            } else if let token = token {
                print("FCM registration token: \(token)")
            }
        }
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    override func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        // Pass device token to Firebase Messaging
        Messaging.messaging().apnsToken = deviceToken
        super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }
    
    override func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("Failed to register for remote notifications: \(error)")
    }

    override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        if url.scheme?.lowercased() == "plur" {
            // Pass the URL to Flutter
            let controller = window?.rootViewController as! FlutterViewController
            let channel = FlutterMethodChannel(name: "com.example.app/deeplink", binaryMessenger: controller.binaryMessenger)
            channel.invokeMethod("onDeepLink", arguments: url.absoluteString)
            return true
        }
        return false
    }
}

// MARK: - MessagingDelegate
extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("Firebase registration token: \(String(describing: fcmToken))")
        
        // Note: This callback is fired at each app startup and whenever a new token is generated.
        // You can use this token to send targeted push notifications to this specific device.
    }
}
