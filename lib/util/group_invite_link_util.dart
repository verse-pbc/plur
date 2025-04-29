import 'dart:developer';
import 'dart:math' as math;

/// Utility class for generating group invite links that work with the app's
/// deep linking implementation.
class GroupInviteLinkUtil {
  /// Generates a direct protocol URL with full parameters
  /// 
  /// This format is meant to be used directly by the app: plur://join-community?group-id=X&code=Y&relay=Z
  static String generateDirectProtocolUrl(String groupId, String code, String relay) {
    try {
      // Encode relay to ensure it works in URL parameters
      String encodedRelay = Uri.encodeComponent(relay);
      
      // Build direct protocol URL
      return "plur://join-community?group-id=$groupId&code=$code&relay=$encodedRelay";
    } catch (e) {
      log('Error generating direct protocol URL: $e', name: 'GroupInviteLinkUtil');
      return "";
    }
  }

  /// Generates a Universal Link using a short code approach.
  /// 
  /// This requires the server to have an API endpoint that can resolve 
  /// short codes to full invite parameters.
  static String generateShortCodeUrl(String shortCode) {
    try {
      // Use the short code approach
      return "https://rabble.community/i/$shortCode";
    } catch (e) {
      log('Error generating short code URL: $e', name: 'GroupInviteLinkUtil');
      return "";
    }
  }

  /// Generates a Universal Link with an embedded protocol URL
  /// 
  /// This is a hybrid approach that embeds the protocol URL within
  /// a Universal Link, allowing it to work even on systems where
  /// custom protocols aren't supported or on first use.
  static String generateUniversalLink(String groupId, String code, String relay) {
    try {
      // First generate the direct protocol URL
      String protocolUrl = generateDirectProtocolUrl(groupId, code, relay);
      
      // Embed it in a universal link
      return "https://rabble.community/i/$protocolUrl";
    } catch (e) {
      log('Error generating universal link: $e', name: 'GroupInviteLinkUtil');
      return "";
    }
  }
  
  /// Generates a simple web join URL format
  static String generateJoinWebUrl(String groupId, String code, String relay) {
    try {
      // Encode relay to ensure it works in URL parameters
      String encodedRelay = Uri.encodeComponent(relay);
      
      // Web URL format with /join/{groupId} path format
      return "https://rabble.community/join/$groupId?code=$code&relay=$encodedRelay";
    } catch (e) {
      log('Error generating join web URL: $e', name: 'GroupInviteLinkUtil');
      return "";
    }
  }
  
  /// Generates a traditional web URL with query parameters
  static String generateJoinCommunityWebUrl(String groupId, String code, String relay) {
    try {
      // Encode relay to ensure it works in URL parameters
      String encodedRelay = Uri.encodeComponent(relay);
      
      // Web URL format with query parameters
      return "https://rabble.community/join-community?group-id=$groupId&code=$code&relay=$encodedRelay";
    } catch (e) {
      log('Error generating web URL: $e', name: 'GroupInviteLinkUtil');
      return "";
    }
  }
  
  /// Generates a direct group navigation URL
  static String generateGroupUrl(String groupId, String? relay) {
    try {
      // Group URL format
      String baseUrl = "https://rabble.community/g/$groupId";
      
      // Add relay parameter if provided
      if (relay != null && relay.isNotEmpty) {
        String encodedRelay = Uri.encodeComponent(relay);
        return "$baseUrl?relay=$encodedRelay";
      }
      
      return baseUrl;
    } catch (e) {
      log('Error generating group URL: $e', name: 'GroupInviteLinkUtil');
      return "";
    }
  }
  
  /// Generate a random invite code for use with short code links
  static String generateRandomCode(int length) {
    const String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final math.Random rnd = math.Random();
    
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(rnd.nextInt(chars.length)),
      )
    );
  }
  
  /// Registers a new invite code with the API server
  /// 
  /// This is a placeholder implementation. You would need to implement
  /// the actual API call to register a new invite code.
  static Future<String?> registerInviteCode(String groupId, String relay, String code) async {
    try {
      // TODO: Implement API call to register invite code
      // For now, just return the generated short code URL
      return generateShortCodeUrl(code);
    } catch (e) {
      log('Error registering invite code: $e', name: 'GroupInviteLinkUtil');
      return null;
    }
  }
  
  /// Generates a shareable invite link using the best approach
  /// 
  /// This is the recommended method to call when generating invite links.
  static String generateShareableLink(String groupId, String code, String relay) {
    // Use the universal link with embedded protocol URL approach as it's the most versatile
    return generateUniversalLink(groupId, code, relay);
  }
  
  /// Creates a new invite with a random code and returns the shareable link
  static String createNewInvite(String groupId, String relay, {int codeLength = 8}) {
    String code = generateRandomCode(codeLength);
    return generateShareableLink(groupId, code, relay);
  }
}