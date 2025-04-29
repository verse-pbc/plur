import FlutterMacOS
import Foundation

// Dummy implementation of the cryptography_flutter plugin to avoid build failures
public class CryptographyFlutterPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    // No-op implementation for compatibility
    print("Dummy CryptographyFlutterPlugin registered for macOS")
  }
}
