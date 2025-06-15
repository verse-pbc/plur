import 'package:flutter/foundation.dart';
import 'package:nostr_sdk/nip29/group_identifier.dart';
import 'app_logger.dart';

/// Utility functions for working with group identifiers in different formats
class GroupIdUtil {
  /// Formats a GroupIdentifier for use in h-tags (used in asks/offers)
  /// Uses the format "host:groupId" with a colon separator
  static String formatForHTag(GroupIdentifier groupIdentifier) {
    return "${groupIdentifier.host}:${groupIdentifier.groupId}";
  }

  /// Parses a string in "host:groupId" format (from h-tag) into a GroupIdentifier
  static GroupIdentifier parseFromHTag(String hTagValue) {
    if (hTagValue.contains(':')) {
      final parts = hTagValue.split(':');
      if (parts.length >= 2) {
        final host = parts[0];
        final groupId = parts[1];
        return GroupIdentifier(host, groupId);
      }
    }
    
    // Fallback if the format doesn't contain a colon or is invalid
    return GroupIdentifier('relay', hTagValue);
  }
  
  /// Standardizes a group ID string to the h-tag format (host:id)
  static String standardizeGroupIdString(String rawGroupId) {
    // If already in h-tag format (host:id), return as-is
    if (rawGroupId.contains(':')) {
      // Special case: make sure the format is "wss://host:id" not just "host:id"
      if (rawGroupId.startsWith("wss://")) {
        return rawGroupId;
      } else if (!rawGroupId.contains("://")) {
        // If it has a colon but no protocol, assume it's host:id and add wss:// prefix
        final parts = rawGroupId.split(':');
        if (parts.length >= 2) {
          return "wss://${parts[0]}:${parts[1]}";
        }
      }
      return rawGroupId;
    }
    
    // If in GroupIdentifier.toString() format (host'id), convert to wss://host:id
    if (rawGroupId.contains("'")) {
      final parts = rawGroupId.split("'");
      if (parts.length >= 2) {
        return "wss://${parts[0]}:${parts[1]}";
      }
    }
    
    // Special case: if it looks like just an ID part, add standard communities host
    if (rawGroupId.length >= 8 && !rawGroupId.contains(":") && !rawGroupId.contains("/")) {
      return "wss://communities.nos.social:$rawGroupId";
    }
    
    // Fallback: return as-is if we can't parse it
    return rawGroupId;
  }
  
  /// Extracts just the ID part from a group ID string, handling different formats
  static String extractIdPart(String? rawGroupId) {
    if (rawGroupId == null) return '';
    
    // Special case for URLs with wss:// and a colon after the domain
    if (rawGroupId.startsWith("wss://")) {
      final lastColonIndex = rawGroupId.lastIndexOf(':');
      if (lastColonIndex != -1 && lastColonIndex > 5) { // > 5 to ensure we're not just getting the colon in wss://
        return rawGroupId.substring(lastColonIndex + 1);
      }
    }
    
    // If in standard h-tag format (host:id), extract the ID part
    if (rawGroupId.contains(':')) {
      final parts = rawGroupId.split(':');
      if (parts.length >= 2) {
        return parts.last; // Use last part to handle multiple colons
      }
    }
    
    // If in GroupIdentifier.toString() format (host'id), extract the ID part
    if (rawGroupId.contains("'")) {
      final parts = rawGroupId.split("'");
      if (parts.length >= 2) {
        return parts[1];
      }
    }
    
    // If no special format, assume it's already just the ID
    return rawGroupId;
  }
  
  /// Checks if two group IDs match, regardless of their format
  static bool doGroupIdsMatch(String? groupId1, String? groupId2) {
    if (groupId1 == null || groupId2 == null) return false;
    
    // Check for exact match first
    if (groupId1 == groupId2) return true;
    
    // Extract ID parts and compare
    final id1 = extractIdPart(groupId1);
    final id2 = extractIdPart(groupId2);
    
    // Debug log the extraction results
    if (kDebugMode) {
      logger.d("doGroupIdsMatch DEBUG - ID extraction:");
      logger.d("  groupId1: '$groupId1' → id1: '$id1'");
      logger.d("  groupId2: '$groupId2' → id2: '$id2'");
      
      // Only match if both extracted IDs are non-empty and equal
      final matches = id1.isNotEmpty && id2.isNotEmpty && id1 == id2;
      logger.d("  Match result: $matches");
      
      return matches;
    }
    
    return id1.isNotEmpty && id2.isNotEmpty && id1 == id2;
  }
}