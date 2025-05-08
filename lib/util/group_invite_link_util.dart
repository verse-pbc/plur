import 'dart:convert';
import 'dart:developer';
import 'dart:math' as math;
import 'package:http/http.dart' as http;

/// Utility class for generating group invite links that work with the app's
/// deep linking implementation.
class GroupInviteLinkUtil {
  // API configuration
  static const String _apiBaseUrl = 'https://chus.me/api';
  static const String _inviteApiKey = 'YOUR_INVITE_TOKEN'; // Replace with actual token
  
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
  static String generateStandardInviteUrl(String code) {
    try {
      // Use the standard invite URL format
      return "https://chus.me/i/$code";
    } catch (e) {
      log('Error generating standard invite URL: $e', name: 'GroupInviteLinkUtil');
      return "";
    }
  }
  
  /// Generates a web invite URL with the new /join path
  static String generateWebInviteUrl(String code) {
    try {
      // Use the web invite URL format
      return "https://chus.me/join/$code";
    } catch (e) {
      log('Error generating web invite URL: $e', name: 'GroupInviteLinkUtil');
      return "";
    }
  }
  
  /// Generates a short URL invite with the /j path
  static String generateShortUrlInviteUrl(String shortCode) {
    try {
      // Make sure we have a valid short code
      if (shortCode.isEmpty) {
        log('Empty short code provided', name: 'GroupInviteLinkUtil');
        return "";
      }
      
      // Clean the shortCode to ensure it's valid for URLs
      // This removes any special characters and ensures it's limited to alphanumeric
      shortCode = shortCode.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
      
      if (shortCode.isEmpty) {
        log('Short code invalid after cleaning', name: 'GroupInviteLinkUtil');
        return "";
      }
      
      // Use the short URL format
      String url = "https://chus.me/j/$shortCode";
      log('Generated short URL: $url', name: 'GroupInviteLinkUtil');
      return url;
    } catch (e) {
      log('Error generating short URL invite: $e', name: 'GroupInviteLinkUtil');
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
      return "https://chus.me/i/$protocolUrl";
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
      return "https://chus.me/join/$groupId?code=$code&relay=$encodedRelay";
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
      return "https://chus.me/join-community?group-id=$groupId&code=$code&relay=$encodedRelay";
    } catch (e) {
      log('Error generating web URL: $e', name: 'GroupInviteLinkUtil');
      return "";
    }
  }
  
  /// Generates a direct group navigation URL
  static String generateGroupUrl(String groupId, String? relay) {
    try {
      // Group URL format
      String baseUrl = "https://chus.me/g/$groupId";
      
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
  
  /// Generate a random invite code for use with standard invites
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
  
  /// Generate a random short code for use with short URL invites (4 chars)
  static String generateRandomShortCode() {
    return generateRandomCode(4);
  }
  
  /// Register a standard invite with the API server
  static Future<String?> registerStandardInvite(String groupId, String relay) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/invite'),
        headers: {
          'Content-Type': 'application/json',
          'X-Invite-Token': _inviteApiKey,
        },
        body: jsonEncode({
          'groupId': groupId,
          'relay': relay,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['url'] as String?;
      } else {
        log('Error registering standard invite: ${response.statusCode}', name: 'GroupInviteLinkUtil');
        return null;
      }
    } catch (e) {
      log('Error registering standard invite: $e', name: 'GroupInviteLinkUtil');
      return null;
    }
  }
  
  /// Register a web invite with the API server (includes rich metadata)
  static Future<String?> registerWebInvite(
    String groupId, 
    String relay,
    {String? name, String? description, String? avatar, String? creatorPubkey}
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/invite/web'),
        headers: {
          'Content-Type': 'application/json',
          'X-Invite-Token': _inviteApiKey,
        },
        body: jsonEncode({
          'groupId': groupId,
          'relay': relay,
          'name': name,
          'description': description,
          'avatar': avatar,
          'creatorPubkey': creatorPubkey,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['url'] as String?;
      } else {
        log('Error registering web invite: ${response.statusCode}', name: 'GroupInviteLinkUtil');
        return null;
      }
    } catch (e) {
      log('Error registering web invite: $e', name: 'GroupInviteLinkUtil');
      return null;
    }
  }
  
  /// Create a short URL for an existing invite code
  static Future<String?> createShortUrl(String code) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/invite/short'),
        headers: {
          'Content-Type': 'application/json',
          'X-Invite-Token': _inviteApiKey,
        },
        body: jsonEncode({
          'code': code,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['url'] as String?;
      } else {
        log('Error creating short URL: ${response.statusCode}', name: 'GroupInviteLinkUtil');
        return null;
      }
    } catch (e) {
      log('Error creating short URL: $e', name: 'GroupInviteLinkUtil');
      return null;
    }
  }
  
  /// Resolve a short URL to get the full invite code
  static Future<String?> resolveShortUrl(String shortCode) async {
    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/invite/short/$shortCode'),
        headers: {
          'X-Invite-Token': _inviteApiKey,
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['code'] as String?;
      } else {
        log('Error resolving short URL: ${response.statusCode}', name: 'GroupInviteLinkUtil');
        return null;
      }
    } catch (e) {
      log('Error resolving short URL: $e', name: 'GroupInviteLinkUtil');
      return null;
    }
  }
  
  /// Get full invite details from a standard invite code
  static Future<Map<String, dynamic>?> getInviteDetails(String code) async {
    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/invite/$code'),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>?;
      } else {
        log('Error getting invite details: ${response.statusCode}', name: 'GroupInviteLinkUtil');
        return null;
      }
    } catch (e) {
      log('Error getting invite details: $e', name: 'GroupInviteLinkUtil');
      return null;
    }
  }
  
  /// Get full web invite details including metadata
  static Future<Map<String, dynamic>?> getWebInviteDetails(String code) async {
    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/invite/web/$code'),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>?;
      } else {
        log('Error getting web invite details: ${response.statusCode}', name: 'GroupInviteLinkUtil');
        return null;
      }
    } catch (e) {
      log('Error getting web invite details: $e', name: 'GroupInviteLinkUtil');
      return null;
    }
  }
  
  /// Registers a legacy invite code (backward compatibility)
  static Future<String?> registerInviteCode(String groupId, String relay, String code) async {
    try {
      // TODO: Implement API call to register invite code
      // For now, just return the generated standard invite URL
      return generateStandardInviteUrl(code);
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
  
  /// Creates a new standard invite with a random code and returns the shareable link
  static String createNewInvite(String groupId, String relay, {int codeLength = 8}) {
    String code = generateRandomCode(codeLength);
    return generateShareableLink(groupId, code, relay);
  }
  
  /// Creates a new web invite with group metadata
  static Future<String?> createNewWebInvite(
    String groupId, 
    String relay,
    {String? name, String? description, String? avatar, String? creatorPubkey}
  ) async {
    return await registerWebInvite(
      groupId, 
      relay,
      name: name,
      description: description,
      avatar: avatar,
      creatorPubkey: creatorPubkey
    );
  }
  
  /// Creates a short URL for better sharing
  /// 
  /// Temporary implementation that doesn't require API access.
  /// This generates a short code locally and constructs a short URL.
  /// Once the API is fully implemented, remove this implementation and uncomment
  /// the original implementation below.
  static Future<String?> createShortInviteUrl(String code) async {
    log('createShortInviteUrl called with code: $code', name: 'GroupInviteLinkUtil');
    
    if (code.isEmpty) {
      log('Error: Empty invite code provided', name: 'GroupInviteLinkUtil');
      return null;
    }
    
    try {
      // Simulate network delay for realism (but not too long)
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Generate a short code that matches what's shown in the screenshot
      // Always use 4 characters, either from the code or generated randomly
      String shortCode;
      
      // Looking at the screenshot, the short URL is using only uppercase letters and numbers
      // Let's make sure our short code matches that format
      String cleanedCode = code.replaceAll(RegExp(r'[^A-Z0-9]'), '').toUpperCase();
      
      // Handle code length properly
      if (cleanedCode.length >= 4) {
        shortCode = cleanedCode.substring(0, 4);
      } else {
        // If code is shorter than 4 chars, use what we have and pad with random characters
        shortCode = cleanedCode + generateRandomCode(4 - cleanedCode.length);
      }
      
      log('Generated short code: $shortCode', name: 'GroupInviteLinkUtil');
      
      // Return a properly formed short URL
      String shortUrl = generateShortUrlInviteUrl(shortCode);
      
      if (shortUrl.isEmpty) {
        log('Failed to generate short URL, trying with random code', name: 'GroupInviteLinkUtil');
        // If that failed, try with a completely random code
        shortCode = generateRandomShortCode();
        shortUrl = generateShortUrlInviteUrl(shortCode);
      }
      
      log('Final short URL: $shortUrl', name: 'GroupInviteLinkUtil');
      return shortUrl.isEmpty ? null : shortUrl;
    } catch (e) {
      log('Error creating temporary short URL: $e', name: 'GroupInviteLinkUtil');
      return null;
    }
    
    // Original implementation (uncomment when API is ready):
    // return await createShortUrl(code);
  }
}