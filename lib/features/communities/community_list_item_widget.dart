import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:provider/provider.dart' as provider;

import '../../component/user/user_pic_widget.dart';
import '../../component/group/group_avatar_widget.dart';
import '../../data/group_metadata_repository.dart';
import '../../provider/group_feed_provider.dart';
import '../../provider/group_read_status_provider.dart';
import '../../theme/app_colors.dart';
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
    final customColors = context.colors;
    final localization = S.of(context);
    
    // If metadata is null or empty and we're trying to use the fallback,
    // try to fetch fresh metadata from the network instead of using cache
    if (controller is AsyncData && 
        (controller.value == null || controller.value?.name == null || controller.value!.name!.isEmpty)) {
      // Use a microtask to avoid triggering a build during the current build phase
      Future.microtask(() {
        // Try to refresh the metadata from network
        debugPrint("Refreshing metadata for group ${groupIdentifier.groupId} from network");
        ref.refresh(groupMetadataProvider(groupIdentifier));
        
        // Also try a delayed refresh in case it takes time for the metadata to propagate
        Future.delayed(const Duration(seconds: 2), () {
          debugPrint("Delayed refresh for group ${groupIdentifier.groupId}");
          ref.refresh(groupMetadataProvider(groupIdentifier));
        });
      });
    }
    
    // Get the GroupFeedProvider and GroupReadStatusProvider
    GroupFeedProvider? feedProvider;
    GroupReadStatusProvider? readStatusProvider;
    
    try {
      feedProvider = provider.Provider.of<GroupFeedProvider>(context, listen: true);
    } catch (e) {
      debugPrint("GroupFeedProvider not available: ${e.toString()}");
    }
    
    try {
      readStatusProvider = provider.Provider.of<GroupReadStatusProvider>(context, listen: true);
    } catch (e) {
      debugPrint("GroupReadStatusProvider not available: ${e.toString()}");
    }
    
    return controller.when(
      data: (metadata) {
        // Default values if providers are not available
        LatestPostInfo latestPostInfo = LatestPostInfo(content: "", pubkey: null);
        int postCount = 0;
        int unreadCount = 0;
        bool hasUnread = false;
        
        // Get data if providers are available
        if (feedProvider != null) {
          latestPostInfo = _getLatestPostInfo(feedProvider, metadata);
          
          // Handle read status
          if (readStatusProvider != null) {
            // Skip the warning about mismatched providers since we're now
            // manually managing providers in CommunitiesScreen
            
            // Get the counts from the provider
            postCount = readStatusProvider.getPostCount(groupIdentifier);
            unreadCount = readStatusProvider.getUnreadCount(groupIdentifier);
            hasUnread = readStatusProvider.hasUnread(groupIdentifier);
            
            // If the post count is 0 but we have posts in the feed, force an update
            if (postCount == 0) {
              int actualCount = _getNotificationCount(feedProvider, metadata);
              if (actualCount > 0) {
                debugPrint("⚙️ Forcing count update for ${groupIdentifier.groupId}: found $actualCount posts");
                // Try to trigger an update of counts
                Future.microtask(() {
                  // Get posts from feedProvider and update counts in readStatusProvider directly
                  final posts = _getPostsForGroup(feedProvider!, groupIdentifier);
                  final lastReadTime = readStatusProvider!.getLastReadTime(groupIdentifier) ?? 0;
                  
                  int realUnreadCount = 0;
                  for (final event in posts) {
                    if (event.createdAt > lastReadTime) {
                      realUnreadCount++;
                    }
                  }
                  
                  // Update the counts
                  readStatusProvider.updateCounts(
                    groupIdentifier, 
                    posts.length, 
                    realUnreadCount
                  );
                });
                
                // Use the actual count for this render
                postCount = actualCount;
                unreadCount = actualCount; // Assume all unread for now, will be updated on next render
                hasUnread = actualCount > 0;
              }
            }
          } else {
            // Fall back to old method of counting posts
            postCount = _getNotificationCount(feedProvider, metadata);
            // With the old method, all posts are treated as unread
            unreadCount = postCount;
            hasUnread = postCount > 0;
          }
        }
        
        return Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: customColors.divider,
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Group avatar on the left
              Container(
                width: 60,
                height: 80,
                alignment: Alignment.center,
                child: GroupAvatar(
                  imageUrl: metadata?.picture,
                  size: 40,
                  borderWidth: 2.0,
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
                        metadata?.name != null && metadata!.name!.isNotEmpty
                            ? "# ${metadata!.name}"
                            : "# ${groupIdentifier.groupId.substring(0, math.min(8, groupIdentifier.groupId.length))}",
                        style: TextStyle(
                          fontFamily: 'SF Pro Rounded',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: customColors.primaryText,
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
                                  fontFamily: 'SF Pro Rounded',
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
                                fontFamily: 'SF Pro Rounded',
                                color: customColors.secondaryText,
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
              
              // Post count on the right (always visible)
              Padding(
                padding: const EdgeInsets.only(top: 16.0, right: 16.0),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: hasUnread ? Colors.red : Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    postCount.toString(),
                    style: TextStyle(
                      fontFamily: 'SF Pro Rounded',
                      color: hasUnread ? Colors.white : Colors.black54,
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              shape: BoxShape.circle,
            ),
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.red[100],
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              "Error loading community",
              style: TextStyle(
                fontFamily: 'SF Pro Rounded',
                color: Colors.red,
              ),
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
  
  // Get all posts for a specific group
  List<Event> _getPostsForGroup(GroupFeedProvider feedProvider, GroupIdentifier groupId) {
    try {
      // Get all posts from the main box
      final result = <Event>[];
      final allPosts = feedProvider.notesBox.all();
      
      // Also check any posts in the new box
      final newPosts = feedProvider.newNotesBox.all();
      
      // Combine both lists
      final combinedPosts = [...allPosts, ...newPosts];
      
      // Filter for this specific group
      for (final event in combinedPosts) {
        // Check for this group's tag
        for (var tag in event.tags) {
          if (tag is List && tag.isNotEmpty && tag.length > 1 && 
              tag[0] == "h" && tag[1] == groupId.groupId) {
            // Make sure we don't add duplicates
            if (!result.any((e) => e.id == event.id)) {
              result.add(event);
            }
            break;
          }
        }
      }
      
      return result;
    } catch (e) {
      debugPrint("Error getting posts for group: $e");
      return [];
    }
  }

  // Get total post count for this community
  int _getNotificationCount(GroupFeedProvider feedProvider, GroupMetadata? metadata) {
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
      
      // Return total post count
      return groupPosts.length;
    } catch (e) {
      debugPrint("Error getting post count: $e");
      return 0;
    }
  }
}