import 'package:flutter/material.dart';
import 'package:nostrmo/component/event/group_event_list_widget.dart';
import 'package:nostrmo/provider/group_feed_provider.dart';
import 'package:nostrmo/router/group/community_title_widget.dart';
import 'package:provider/provider.dart';

/// Widget that displays a feed of posts from all communities the user has joined
class CommunitiesFeedWidget extends StatefulWidget {
  const CommunitiesFeedWidget({super.key});

  @override
  State<CommunitiesFeedWidget> createState() => _CommunitiesFeedWidgetState();
}

class _CommunitiesFeedWidgetState extends State<CommunitiesFeedWidget> {
  final GroupFeedProvider _groupFeedProvider = GroupFeedProvider();

  @override
  void initState() {
    super.initState();
    _groupFeedProvider.refresh();
  }

  @override
  void dispose() {
    _groupFeedProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return ChangeNotifierProvider<GroupFeedProvider>.value(
      value: _groupFeedProvider,
      child: Scaffold(
        appBar: AppBar(
          title: const CommunityTitleWidget(),
          centerTitle: true,
          elevation: 0.5,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: "Refresh",
              onPressed: () {
                _groupFeedProvider.refresh();
              },
            ),
          ],
        ),
        body: const GroupEventListWidget(),
      ),
    );
  }
}