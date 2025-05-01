import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:provider/provider.dart' as provider;

import '../../component/user/user_pic_widget.dart';
import '../../data/group_metadata_repository.dart';
import '../../provider/group_feed_provider.dart';
import '../../util/theme_util.dart';
import '../../generated/l10n.dart';

// Class to hold latest post information
class LatestPostInfo {
  final String content;
  final String? pubkey;
  
  LatestPostInfo({required this.content, this.pubkey});
}

class CommunityListItemWidget extends ConsumerWidget {
  final GroupIdentifier groupIdentifier;
  final int index;
  
  const CommunityListItemWidget(this.groupIdentifier, {
    super.key,
    required this.index,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get group metadata using Riverpod
    final controller = ref.watch(cachedGroupMetadataProvider(groupIdentifier));
    final themeData = Theme.of(context);
    final customColors = themeData.customColors;
    final localization = S.of(context);
    
    // Get the GroupFeedProvider using Provider package (not Riverpod) since it's registered that way
    final groupFeedProvider = provider.Provider.of<GroupFeedProvider>(context, listen: false);
    
    return controller.when(
      data: (metadata) {
        // Get the latest post content from the group using real data
        final latestPostInfo = _getLatestPostInfo(groupFeedProvider, metadata);
        final notificationCount = _getNotificationCount(groupFeedProvider, metadata);
        
        return Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: customColors.separatorColor,
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Index column on the left
              Container(
                width: 40,
                height: 80,
                alignment: Alignment.center,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: index == 3 ? Colors.orange[200] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    index.toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ),
              
              // Community info in the middle
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Community name with hashtag
                      Text(
                        "# ${metadata?.name ?? groupIdentifier.groupId.substring(0, math.min(8, groupIdentifier.groupId.length))}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: customColors.primaryForegroundColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Latest post preview with actual user avatar
                      Row(
                        children: [
                          if (latestPostInfo.pubkey != null)
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: UserPicWidget(
                                pubkey: latestPostInfo.pubkey!,
                                width: 20,
                              ),
                            )
                          else
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.grey[400],
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                "?",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              latestPostInfo.content.isNotEmpty 
                                  ? latestPostInfo.content 
                                  : localization.noRecentPosts,
                              style: TextStyle(
                                color: customColors.secondaryForegroundColor,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              // Notification count on the right (if there are any)
              if (notificationCount > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0, right: 16.0),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      notificationCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => _buildLoadingItem(),
      error: (error, stackTrace) => _buildErrorItem(error),
    );
  }
  
  Widget _buildLoadingItem() {
    return Container(
      height: 80,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withAlpha(51), // 0.2 * 255 = 51
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
            alignment: Alignment.center,
            child: Text(index.toString()),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 16,
                  width: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  width: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildErrorItem(Object error) {
    return Container(
      height: 80,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withAlpha(51), // 0.2 * 255 = 51
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
            alignment: Alignment.center,
            child: Text(index.toString()),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              "Error loading community",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
  
  // Get latest post information with real data from the feed
  LatestPostInfo _getLatestPostInfo(GroupFeedProvider feedProvider, GroupMetadata? metadata) {
    // Default empty result
    final emptyResult = LatestPostInfo(content: "", pubkey: null);
    
    try {
      // Get all posts from the feed
      final allPosts = feedProvider.notesBox.all();
      if (allPosts.isEmpty) return emptyResult;
      
      // Filter posts for this specific group
      final groupPosts = allPosts.where((event) {
        // Check if event has this group's tag
        for (var tag in event.tags) {
          if (tag is List && tag.isNotEmpty && tag.length > 1 && 
              tag[0] == "h" && tag[1] == groupIdentifier.groupId) {
            return true;
          }
        }
        return false;
      }).toList();
      
      // If no posts for this group, return default
      if (groupPosts.isEmpty) return emptyResult;
      
      // Sort by creation time (newest first)
      groupPosts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      // Get the most recent post
      final latestPost = groupPosts.first;
      
      // Extract and sanitize content
      String content = latestPost.content;
      
      // Remove newlines for preview
      content = content.replaceAll('\n', ' ');
      
      // Limit to reasonable length
      if (content.length > 50) {
        content = "${content.substring(0, 47)}...";
      }
      
      return LatestPostInfo(content: content, pubkey: latestPost.pubkey);
    } catch (e) {
      debugPrint("Error getting latest post: $e");
      return emptyResult;
    }
  }
  
  // Get notification count with estimated unread messages
  int _getNotificationCount(GroupFeedProvider feedProvider, GroupMetadata? metadata) {
    // For now, we'll use a simplified approach for notifications
    // In a real implementation, you'd track last-read timestamps per group
    try {
      // Get all posts from the feed
      final allPosts = feedProvider.notesBox.all();
      if (allPosts.isEmpty) return 0;
      
      // Filter posts for this specific group
      final groupPosts = allPosts.where((event) {
        // Check for this group's tag
        for (var tag in event.tags) {
          if (tag is List && tag.isNotEmpty && tag.length > 1 && 
              tag[0] == "h" && tag[1] == groupIdentifier.groupId) {
            return true;
          }
        }
        return false;
      }).toList();
      
      // If no posts for this group, no notifications
      if (groupPosts.isEmpty) return 0;
      
      // For now, use a simple formula based on recent posts
      // In a real app, you'd compare to the last read timestamp
      final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final recentPosts = groupPosts.where((event) {
        // Posts in the last hour are "recent"
        return currentTime - event.createdAt < 3600;
      }).length;
      
      return recentPosts;
    } catch (e) {
      debugPrint("Error getting notification count: $e");
      return 0;
    }
  }
}