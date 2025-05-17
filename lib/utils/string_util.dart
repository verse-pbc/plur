import 'package:nostr_sdk/nostr_sdk.dart';

/// Utility class for string operations
class StringUtil {
  static bool isNotBlank(String? str) {
    if (str != null && str.trim().isNotEmpty) {
      return true;
    }
    return false;
  }

  static bool isBlank(String? str) {
    return !isNotBlank(str);
  }

  /// Formats a public key for display by shortening it 
  /// e.g., "npub123456789abcdef..." -> "npub123...def"
  static String formatPublicKey(String pubkey) {
    if (pubkey.length < 12) {
      return pubkey;
    }

    // If it starts with npub, use that format
    if (pubkey.startsWith('npub')) {
      return "${pubkey.substring(0, 6)}...${pubkey.substring(pubkey.length - 3)}";
    }
    
    // Otherwise, show beginning and end of hex
    return "${pubkey.substring(0, 6)}...${pubkey.substring(pubkey.length - 6)}";
  }
} 