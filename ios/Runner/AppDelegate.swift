import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        if url.scheme == "plur" {
            // Pass the URL to Flutter
            let controller = window?.rootViewController as! FlutterViewController
            let channel = FlutterMethodChannel(name: "com.example.app/deeplink", binaryMessenger: controller.binaryMessenger)
            channel.invokeMethod("onDeepLink", arguments: url.absoluteString)
            return true
        }
        return false
    }
}
