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
      Uri uri = Uri.parse(joinLink.trim());
      if (uri.scheme.toLowerCase() == 'plur' && uri.host.toLowerCase() == 'join-community') {
        String? groupId = uri.queryParameters['group-id'];
        String? code = uri.queryParameters['code'];

        if (groupId == null || groupId.isEmpty) {
          return false;
        }

        final listProvider = Provider.of<ListProvider>(context, listen: false);
        
        // Join the group using the existing method
        listProvider.joinGroup(
          JoinGroupParameters(
            'wss://communities.nos.social', // Default relay
            groupId,
            code: code,
          ),
          context: context,
        );
        
        return true;
      }
    } catch (e) {
      // Error parsing the link
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