import UIKit
import Flutter
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // For Firebase notifications
        UNUserNotificationCenter.current().delegate = self
        
        // Initialize plugins
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    // Handle Universal Links
    override func application(
        _ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([UIUserActivityRestoring]) -> Void
    ) -> Bool {
        // Check if the user activity is a web URL
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb, let url = userActivity.webpageURL {
            print("Universal Link received: \(url)")
            // Here we would process the URL by sending it to Flutter
            if let controller = window?.rootViewController as? FlutterViewController {
                let channel = FlutterMethodChannel(name: "com.example.app/deeplink", binaryMessenger: controller.binaryMessenger)
                channel.invokeMethod("onDeepLink", arguments: url.absoluteString)
                return true
            }
        }
        return false
    }
    
    // Handle Custom URL Schemes
    override func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        print("Custom URL scheme received: \(url)")
        // Here we would process the URL by sending it to Flutter
        if let controller = window?.rootViewController as? FlutterViewController {
            let channel = FlutterMethodChannel(name: "com.example.app/deeplink", binaryMessenger: controller.binaryMessenger)
            channel.invokeMethod("onDeepLink", arguments: url.absoluteString)
            return true
        }
        return false
    }
}