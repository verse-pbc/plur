import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/provider/group_feed_provider.dart';
import 'package:nostrmo/provider/group_read_status_provider.dart';
import 'package:nostrmo/provider/list_provider.dart';

/// A utility class for diagnosing issues with group feeds and read status
class GroupFeedDiagnostics {
  static const String _logTag = "GroupFeedDiagnostics";

  /// Run a full diagnostic on the group feed system
  static void diagnoseGroupFeeds({
    required GroupFeedProvider feedProvider,
    required GroupReadStatusProvider readStatusProvider,
    required ListProvider listProvider,
  }) {
    log("============= GROUP FEED DIAGNOSTICS =============", name: _logTag);
    
    // 1. Check providers
    _checkProviders(feedProvider, readStatusProvider, listProvider);
    
    // 2. Check groups
    _checkGroups(listProvider);
    
    // 3. Check posts
    _checkPosts(feedProvider);
    
    // 4. Check read status
    _checkReadStatus(feedProvider, readStatusProvider, listProvider);
    
    // 5. Update counts and show results
    log("Updating all group read counts...", name: _logTag);
    feedProvider.updateAllGroupReadCounts();
    
    // 6. Final verification
    _verifyReadStatus(readStatusProvider, listProvider);
    
    log("============= DIAGNOSTICS COMPLETE =============", name: _logTag);
  }

  /// Check if all providers are properly initialized
  static void _checkProviders(
    GroupFeedProvider feedProvider,
    GroupReadStatusProvider readStatusProvider,
    ListProvider listProvider,
  ) {
    log("CHECKING PROVIDERS:", name: _logTag);
    
    // Check ListProvider
    log("List Provider: ${listProvider.runtimeType}", name: _logTag);
    final groupIds = listProvider.groupIdentifiers;
    log("  Group count: ${groupIds.length}", name: _logTag);
    
    // Check FeedProvider
    log("Feed Provider: ${feedProvider.runtimeType}", name: _logTag);
    log("  Has read status provider: ${feedProvider.readStatusProvider != null}", name: _logTag);
    log("  Notes box size: ${feedProvider.notesBox.length()}", name: _logTag);
    log("  New notes box size: ${feedProvider.newNotesBox.length()}", name: _logTag);
    log("  Static cache size: ${feedProvider.staticEventCache.length}", name: _logTag);
    
    // Check ReadStatusProvider
    log("Read Status Provider: ${readStatusProvider.runtimeType}", name: _logTag);
    log("  Is initialized: ${readStatusProvider.isInitialized}", name: _logTag);
    
    // Check if FeedProvider's readStatusProvider is the same instance
    final isSameInstance = identical(feedProvider.readStatusProvider, readStatusProvider);
    log("FeedProvider and ReadStatusProvider are same instance: $isSameInstance", name: _logTag);
    if (!isSameInstance) {
      log("⚠️ WARNING: Different ReadStatusProvider instances detected!", name: _logTag);
    }
  }

  /// Check all groups in the ListProvider
  static void _checkGroups(ListProvider listProvider) {
    final groups = listProvider.groupIdentifiers;
    log("CHECKING GROUPS (${groups.length}):", name: _logTag);
    
    if (groups.isEmpty) {
      log("⚠️ NO GROUPS FOUND! This will cause feed to be empty.", name: _logTag);
      return;
    }
    
    for (int i = 0; i < groups.length; i++) {
      final group = groups[i];
      log("  Group ${i+1}: ${group.groupId} at ${group.host}", name: _logTag);
    }
  }

  /// Check posts in the feed provider
  static void _checkPosts(GroupFeedProvider feedProvider) {
    final allPosts = feedProvider.notesBox.all();
    final newPosts = feedProvider.newNotesBox.all();
    
    log("CHECKING POSTS:", name: _logTag);
    log("  Main box posts: ${allPosts.length}", name: _logTag);
    log("  New box posts: ${newPosts.length}", name: _logTag);
    
    if (allPosts.isEmpty && newPosts.isEmpty) {
      log("⚠️ NO POSTS FOUND IN EITHER BOX!", name: _logTag);
      
      // Check static cache
      final cachedEvents = feedProvider.staticEventCache;
      log("  Static cache has ${cachedEvents.length} events", name: _logTag);
      
      if (cachedEvents.isNotEmpty) {
        log("⚠️ WARNING: Static cache has posts but they weren't loaded into the notes box!", name: _logTag);
        log("  This suggests a caching issue.", name: _logTag);
      }
      return;
    }
    
    // Count posts by group
    final groupCounts = <String, int>{};
    for (final post in allPosts) {
      for (final tag in post.tags) {
        if (tag is List && tag.isNotEmpty && tag.length > 1 && tag[0] == "h") {
          final groupId = tag[1] as String;
          groupCounts[groupId] = (groupCounts[groupId] ?? 0) + 1;
          break;
        }
      }
    }
    
    log("POSTS BY GROUP:", name: _logTag);
    groupCounts.forEach((groupId, count) {
      log("  Group $groupId: $count posts", name: _logTag);
    });
  }

  /// Check read status for all groups
  static void _checkReadStatus(
    GroupFeedProvider feedProvider,
    GroupReadStatusProvider readStatusProvider,
    ListProvider listProvider,
  ) {
    final groups = listProvider.groupIdentifiers;
    
    log("CHECKING READ STATUS:", name: _logTag);
    
    if (!readStatusProvider.isInitialized) {
      log("⚠️ ReadStatusProvider is not initialized!", name: _logTag);
      return;
    }
    
    for (final group in groups) {
      final readInfo = readStatusProvider.getReadInfo(group);
      final realPostCount = _countGroupPosts(feedProvider, group);
      
      log("Group ${group.groupId}:", name: _logTag);
      log("  Stored post count: ${readInfo.postCount}", name: _logTag);
      log("  Actual post count: $realPostCount", name: _logTag);
      log("  Unread count: ${readInfo.unreadCount}", name: _logTag);
      log("  Last read: ${DateTime.fromMillisecondsSinceEpoch(readInfo.lastReadTime * 1000)}", name: _logTag);
      log("  Last viewed: ${DateTime.fromMillisecondsSinceEpoch(readInfo.lastViewedAt * 1000)}", name: _logTag);
      
      if (readInfo.postCount != realPostCount) {
        log("⚠️ WARNING: Stored post count (${readInfo.postCount}) doesn't match actual post count ($realPostCount)!", name: _logTag);
      }
    }
  }
  
  /// Count actual posts for a group in the feed provider
  static int _countGroupPosts(GroupFeedProvider feedProvider, GroupIdentifier groupId) {
    int count = 0;
    final allPosts = feedProvider.notesBox.all();
    
    for (final post in allPosts) {
      for (final tag in post.tags) {
        if (tag is List && tag.isNotEmpty && tag.length > 1 && 
            tag[0] == "h" && tag[1] == groupId.groupId) {
          count++;
          break;
        }
      }
    }
    
    return count;
  }
  
  /// Final verification of read status
  static void _verifyReadStatus(
    GroupReadStatusProvider readStatusProvider,
    ListProvider listProvider,
  ) {
    final groups = listProvider.groupIdentifiers;
    
    log("FINAL READ STATUS VERIFICATION:", name: _logTag);
    int totalPosts = 0;
    int totalUnread = 0;
    
    for (final group in groups) {
      final readInfo = readStatusProvider.getReadInfo(group);
      totalPosts += readInfo.postCount;
      totalUnread += readInfo.unreadCount;
      
      log("Group ${group.groupId}: ${readInfo.postCount} posts, ${readInfo.unreadCount} unread", name: _logTag);
    }
    
    log("TOTAL: $totalPosts posts, $totalUnread unread", name: _logTag);
  }
  
  /// Run this method to force a full update of all group read counts
  static void forceUpdateAllReadCounts({
    required GroupFeedProvider feedProvider,
    required GroupReadStatusProvider readStatusProvider,
    required ListProvider listProvider,
  }) {
    log("Forcing update of all group read counts...", name: _logTag);
    
    // Update the counts
    feedProvider.updateAllGroupReadCounts();
    
    // Verify the results
    _verifyReadStatus(readStatusProvider, listProvider);
    
    log("Read count update complete", name: _logTag);
  }
}