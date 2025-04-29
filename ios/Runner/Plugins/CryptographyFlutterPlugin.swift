import Flutter
import UIKit

@objc public class CryptographyFlutterPlugin: NSObject, FlutterPlugin {
    @objc public static func register(with registrar: FlutterPluginRegistrar) {
        // This is a dummy implementation that does nothing
        // It's only here to satisfy the plugin registration requirements
        // The actual implementation is in the cryptography_flutter plugin
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        // All calls will return an error indicating this is a dummy implementation
        result(FlutterError(
            code: "UNSUPPORTED",
            message: "This is a dummy implementation of cryptography_flutter",
            details: nil))
    }
}