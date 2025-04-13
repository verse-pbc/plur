import 'package:flutter/material.dart';
import 'package:nostrmo/router/group/all_group_posts_widget.dart';

/// Widget that displays a feed of posts from all communities the user belongs to.
class CommunitiesFeedWidget extends StatelessWidget {
  const CommunitiesFeedWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Log that this widget is being built/displayed
    debugPrint("🔍 SCREEN DISPLAYED: CommunitiesFeedWidget (wrapper for AllGroupPostsWidget)");
    
    // Provider is already initialized in the parent widget
    return const AllGroupPostsWidget();
  }
}