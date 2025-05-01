import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:provider/provider.dart' as provider;

import '../../consts/router_path.dart';
import '../../data/group_metadata_repository.dart';
import '../../generated/l10n.dart';
import '../../provider/group_feed_provider.dart';
import '../../util/router_util.dart';
import '../../util/theme_util.dart';
import 'community_list_item_widget.dart';

/// A widget that displays a list of communities.
class CommunitiesListWidget extends ConsumerWidget {
  /// List of group identifiers to be displayed in the list.
  final List<GroupIdentifier> groupIds;

  const CommunitiesListWidget({super.key, required this.groupIds});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Log that this widget is being built/displayed
    debugPrint("🔍 SCREEN DISPLAYED: CommunitiesListWidget (Communities list)");
    
    final themeData = Theme.of(context);
    final localization = S.of(context);
    
    // Make sure we always have access to the group feed provider
    // This allows us to display the most recent posts in each community
    final groupFeedProvider = provider.Provider.of<GroupFeedProvider>(context, listen: false);
    
    // Pre-fetch metadata for all communities immediately
    // This will trigger a single batch of requests instead of loading one by one
    ref.watch(bulkGroupMetadataProvider(groupIds)); // Important: Don't remove this line - it triggers the loading
    
    // Sort groups to show those with recent activity first
    final sortedGroups = _getSortedGroups(groupIds, groupFeedProvider);
    
    // Determine if there's an active alert to show
    final hasAlert = _hasActiveAlerts(sortedGroups, groupFeedProvider);
    
    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 80), 
      itemCount: sortedGroups.length + (hasAlert ? 1 : 0), // +1 for the header item if there's an alert
      itemBuilder: (context, index) {
        // First item is the alert header (if we have one)
        if (hasAlert && index == 0) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.red[400],
                borderRadius: BorderRadius.circular(8.0),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    localization.alertsAvailable,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        
        // Adjust index to account for header if needed
        final itemIndex = hasAlert ? index - 1 : index;
        final groupIdentifier = sortedGroups[itemIndex];
        
        return InkWell(
          onTap: () {
            RouterUtil.router(
                context, RouterPath.groupDetail, groupIdentifier);
          },
          child: CommunityListItemWidget(
            groupIdentifier, 
            index: itemIndex + 1,
          ),
        );
      },
    );
  }
  
  // Sort groups based on activity (most recent posts first)
  List<GroupIdentifier> _getSortedGroups(List<GroupIdentifier> groups, GroupFeedProvider feedProvider) {
    // Make a copy we can modify
    final sortedGroups = List<GroupIdentifier>.from(groups);
    
    try {
      // Get all posts
      final allPosts = feedProvider.notesBox.all();
      if (allPosts.isEmpty) return sortedGroups;
      
      // Map of group IDs to their most recent post timestamp
      final groupLastActivity = <String, int>{};
      
      // Find the most recent post timestamp for each group
      for (final post in allPosts) {
        for (var tag in post.tags) {
          if (tag is List && tag.isNotEmpty && tag.length > 1 && tag[0] == "h") {
            final groupId = tag[1] as String;
            final currentLastActivity = groupLastActivity[groupId] ?? 0;
            if (post.createdAt > currentLastActivity) {
              groupLastActivity[groupId] = post.createdAt;
            }
          }
        }
      }
      
      // Sort based on activity, groups with recent posts first
      sortedGroups.sort((a, b) {
        final aActivity = groupLastActivity[a.groupId] ?? 0;
        final bActivity = groupLastActivity[b.groupId] ?? 0;
        return bActivity.compareTo(aActivity); // Reverse order - newest first
      });
      
      return sortedGroups;
    } catch (e) {
      debugPrint("Error sorting groups: $e");
      return sortedGroups;
    }
  }
  
  // Check if we should show the alert box at the top
  bool _hasActiveAlerts(List<GroupIdentifier> groups, GroupFeedProvider feedProvider) {
    // Simplified logic - check if any group has posts in the last hour
    try {
      // Get all posts
      final allPosts = feedProvider.notesBox.all();
      if (allPosts.isEmpty) return false;
      
      // Current time
      final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      // Look for any post with alert keywords in the last hour
      for (final post in allPosts) {
        // Check if recent (last hour)
        if (currentTime - post.createdAt < 3600) {
          // Check if it contains alert keywords
          final content = post.content.toLowerCase();
          if (content.contains('alert') || 
              content.contains('urgent') || 
              content.contains('emergency') ||
              content.contains('warning') ||
              content.contains('important')) {
            return true;
          }
        }
      }
      
      return false;
    } catch (e) {
      debugPrint("Error checking for alerts: $e");
      return false;
    }
  }
}