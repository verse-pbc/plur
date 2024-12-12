import 'package:flutter/material.dart';
import 'package:nostrmo/router/follow/mention_me_widget.dart';

import 'follow_posts_widget.dart';
import 'follow_widget.dart';

class FollowIndexWidget extends StatefulWidget {
  TabController tabController;

  FollowIndexWidget({super.key, required this.tabController});

  @override
  State<StatefulWidget> createState() {
    return _FollowIndexWidgetState();
  }
}

class _FollowIndexWidgetState extends State<FollowIndexWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: TabBarView(
        controller: widget.tabController,
        children: [
          FollowPostsWidget(),
          FollowWidget(),
          MentionMeWidget(),
        ],
      ),
    );
  }
}
