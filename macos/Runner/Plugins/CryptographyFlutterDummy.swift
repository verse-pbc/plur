import FlutterMacOS
import Foundation

// This is a dummy implementation of the cryptography_flutter plugin
// to avoid build failures on macOS
public class CryptographyFlutterPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    // No-op implementation
    print("Dummy CryptographyFlutterPlugin registered")
  }
}
