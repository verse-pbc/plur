import 'dart:async';
import 'dart:developer';

import 'package:logging/logging.dart';
import 'package:nostr_sdk/nostr_sdk.dart';

import '../main.dart';
import '../provider/relay_provider.dart';

/// A utility class that provides methods for community relay operations with fallbacks
class CommunityRelayUtil {
  /// Name used when logging
  static const _logName = "CommunityRelayUtil";

  /// Attempts to send an event to multiple relays, trying each one in sequence until successful
  /// 
  /// Returns the result event if successful, null otherwise
  static Future<Event?> sendEventWithFallbacks(Event event) async {
    // Start with the default relay
    final relays = [RelayProvider.defaultGroupsRelayAddress];
    
    // Add backup relays
    relays.addAll(RelayProvider.backupGroupsRelayAddresses);
    
    Event? resultEvent;
    String? lastError;
    
    // Try each relay in sequence until we get a successful result
    for (final relay in relays) {
      try {
        log("Attempting to send event to relay: $relay", 
          level: Level.INFO.value, name: _logName);
        
        // Set a timeout for the operation
        resultEvent = await nostr!.sendEvent(
          event,
          tempRelays: [relay],
          targetRelays: [relay],
        ).timeout(const Duration(seconds: 8), onTimeout: () {
          log("Timeout sending event to relay: $relay", 
            level: Level.WARNING.value, name: _logName);
          return null;
        });
        
        if (resultEvent != null) {
          log("Successfully sent event to relay: $relay", 
            level: Level.INFO.value, name: _logName);
          return resultEvent;
        } else {
          log("Failed to send event to relay: $relay", 
            level: Level.WARNING.value, name: _logName);
        }
      } catch (e, stackTrace) {
        lastError = e.toString();
        log("Error sending event to relay $relay: $e", 
          level: Level.WARNING.value, name: _logName);
        log(stackTrace.toString(), level: Level.FINE.value, name: _logName);
      }
    }
    
    // If we got here, all relays failed
    log("Failed to send event to any relay. Last error: $lastError", 
      level: Level.SEVERE.value, name: _logName);
    return null;
  }
  
  /// Attempts to create a group using multiple relays as fallbacks
  static Future<GroupIdentifier?> createGroup(String groupId) async {
    // Start with the default relay
    final relays = [RelayProvider.defaultGroupsRelayAddress];
    
    // Add backup relays
    relays.addAll(RelayProvider.backupGroupsRelayAddresses);
    
    String? lastError;
    
    // Try each relay in sequence until we get a successful result
    for (final relay in relays) {
      try {
        log("Attempting to create group on relay: $relay", 
          level: Level.INFO.value, name: _logName);
        
        // Create the event for creating a group
        final createGroupEvent = Event(
          nostr!.publicKey,
          EventKind.groupCreateGroup,
          [
            ["h", groupId]
          ],
          "",
        );
        
        // Set a timeout for the operation
        final resultEvent = await nostr!.sendEvent(
          createGroupEvent,
          tempRelays: [relay],
          targetRelays: [relay],
        ).timeout(const Duration(seconds: 8), onTimeout: () {
          log("Timeout creating group on relay: $relay", 
            level: Level.WARNING.value, name: _logName);
          return null;
        });
        
        if (resultEvent != null) {
          log("Successfully created group on relay: $relay", 
            level: Level.INFO.value, name: _logName);
          return GroupIdentifier(relay, groupId);
        } else {
          log("Failed to create group on relay: $relay", 
            level: Level.WARNING.value, name: _logName);
        }
      } catch (e, stackTrace) {
        lastError = e.toString();
        log("Error creating group on relay $relay: $e", 
          level: Level.WARNING.value, name: _logName);
        log(stackTrace.toString(), level: Level.FINE.value, name: _logName);
      }
    }
    
    // If we got here, all relays failed
    log("Failed to create group on any relay. Last error: $lastError", 
      level: Level.SEVERE.value, name: _logName);
    return null;
  }
}