import 'package:flutter/material.dart';
import 'package:nostrmo/router/group/all_group_posts_widget.dart';

/// Widget that displays a feed of posts from all communities the user belongs to.
class CommunitiesFeedWidget extends StatelessWidget {
  const CommunitiesFeedWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Provider is already initialized in the parent widget
    return const AllGroupPostsWidget();
  }
}