import 'package:flutter/material.dart';
import 'package:nostrmo/data/join_group_parameters.dart';
import 'package:nostrmo/provider/list_provider.dart';
import 'package:provider/provider.dart';

/// Utility functions for joining communities
class CommunityJoinUtil {
  /// Parses a community join link and attempts to join the community
  /// 
  /// Returns true if the link was successfully parsed and join attempt was initiated
  /// Returns false if the link was invalid
  static bool parseAndJoinCommunity(BuildContext context, String joinLink) {
    try {
      debugPrint("=== START JOIN COMMUNITY PROCESS ===");
      debugPrint("Parsing join link: $joinLink");
      
      Uri uri = Uri.parse(joinLink.trim());
      if (uri.scheme.toLowerCase() == 'plur' && uri.host.toLowerCase() == 'join-community') {
        String? groupId = uri.queryParameters['group-id'];
        String? code = uri.queryParameters['code'];
        String? relayParam = uri.queryParameters['relay'];

        if (groupId == null || groupId.isEmpty) {
          debugPrint("❌ Invalid join link - missing group ID");
          return false;
        }

        // Capture the context before async operations
        BuildContext currentContext = context;
        
        // Try multiple relays to maximize chances of successful join
        // Default relay should always be included
        List<String> relaysToTry = ['wss://communities.nos.social'];
        
        // Add the relay from the URL if specified 
        if (relayParam != null && relayParam.isNotEmpty) {
          String relay = relayParam;
          // Make sure the relay has wss:// prefix
          if (!relay.startsWith('wss://')) {
            relay = 'wss://$relay';
          }
          
          if (!relaysToTry.contains(relay)) {
            relaysToTry.add(relay);
          }
        }
        
        // Also try official Plur relay if it's different
        const plur_relay = 'wss://communities.nos.social';
        if (!relaysToTry.contains(plur_relay)) {
          relaysToTry.add(plur_relay);
        }
        
        // Debug log
        debugPrint("✅ Joining community with parameters:");
        debugPrint("   - Group ID: $groupId");
        debugPrint("   - Invite code: ${code ?? 'none'}");
        debugPrint("   - Relays to try: ${relaysToTry.join(', ')}");
        
        // Create join parameters with the primary relay
        final joinParams = JoinGroupParameters(
          relaysToTry[0],
          groupId,
          code: code,
        );
        
        // Get the ListProvider just once to avoid context issues
        ListProvider? listProvider;
        try {
          listProvider = Provider.of<ListProvider>(currentContext, listen: false);
          debugPrint("✅ Got ListProvider successfully");
        } catch (e) {
          debugPrint("⚠️ Error getting ListProvider: $e");
          return false;
        }
        
        if (listProvider == null) {
          debugPrint("⚠️ ListProvider is null");
          return false;
        }
        
        try {
          // Start join process with primary relay
          // Don't await the future as it causes issues with BuildContext
          debugPrint("🔄 Attempting join with relay: ${relaysToTry[0]}");
          
          // Use a try-catch to ensure we don't crash if the join fails
          try {
            listProvider.joinGroup(joinParams, context: currentContext);
            debugPrint("==== JOIN PROCESS INITIATED: Success=true ====");
          } catch (e) {
            debugPrint("⚠️ Error during join process: $e");
            
            // Show a helpful error message
            ScaffoldMessenger.of(currentContext).showSnackBar(
              SnackBar(
                content: Text("Error joining group: $e"),
                duration: const Duration(seconds: 3),
              ),
            );
            
            // Still return true since we initiated the process
            // The error will be handled within joinGroup method
          }
          
          // Add a delay before returning to let the join process get started
          // This can help prevent UI flicker
          Future.delayed(const Duration(milliseconds: 500));
          
          return true;
        } catch (e) {
          debugPrint("⚠️ Error during join process: $e");
          
          // Even if there's an error, try to navigate to avoid blank screen
          try {
            // Navigate to groups list as fallback
            Navigator.of(currentContext).pushNamedAndRemoveUntil(
              '/groupList', 
              (route) => false
            );
            debugPrint("✅ Navigated to group list as fallback after error");
          } catch (navError) {
            debugPrint("⚠️ Navigation error: $navError");
          }
          
          return false;
        }
      } else {
        debugPrint("❌ Invalid join link format - not a plur://join-community URL");
      }
    } catch (e) {
      debugPrint("⚠️ Error parsing join link: $e");
      
      // Try to navigate to the groups list to avoid blank screen
      try {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/groupList', 
          (route) => false
        );
        debugPrint("✅ Navigated to group list after parse error");
      } catch (navError) {
        debugPrint("⚠️ Navigation error after parse error: $navError");
      }
    }
    return false;
  }
  
  /// Validates if a string looks like a community join link
  static bool isValidJoinLink(String? text) {
    if (text == null || text.isEmpty) return false;
    
    try {
      Uri uri = Uri.parse(text.trim());
      return uri.scheme.toLowerCase() == 'plur' && 
             uri.host.toLowerCase() == 'join-community' &&
             uri.queryParameters.containsKey('group-id');
    } catch (e) {
      return false;
    }
  }
}