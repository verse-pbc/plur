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

        final listProvider = Provider.of<ListProvider>(context, listen: false);
        
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
        
        // Try joining with each relay
        for (final relay in relaysToTry) {
          debugPrint("🔄 Attempting join with relay: $relay");
          
          // Join the group using the existing method
          listProvider.joinGroup(
            JoinGroupParameters(
              relay,
              groupId,
              code: code,
            ),
            context: context,
          );
        }
        
        debugPrint("==== JOIN PROCESS INITIATED ====");
        return true;
      } else {
        debugPrint("❌ Invalid join link format - not a plur://join-community URL");
      }
    } catch (e) {
      debugPrint("⚠️ Error parsing join link: $e");
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