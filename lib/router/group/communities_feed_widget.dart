import 'package:flutter/material.dart';
import 'package:nostrmo/provider/group_feed_provider.dart';
import 'package:nostrmo/provider/list_provider.dart';
import 'package:nostrmo/router/group/all_group_posts_widget.dart';
import 'package:provider/provider.dart';

/// Widget that displays a feed of posts from all communities the user belongs to.
class CommunitiesFeedWidget extends StatelessWidget {
  const CommunitiesFeedWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final listProvider = Provider.of<ListProvider>(context);
    final groupFeedProvider = Provider.of<GroupFeedProvider>(context);
    
    // If no communities, show a message
    if (listProvider.groupIdentifiers.isEmpty) {
      return const Center(
        child: Text("Join a community to see posts here"),
      );
    }

    // Initialize feed if needed
    if (groupFeedProvider.notesBox.isEmpty()) {
      groupFeedProvider.subscribe();
      groupFeedProvider.doQuery(null);
    }

    // Display all posts from all communities
    return const AllGroupPostsWidget();
  }
}