import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/component/keep_alive_cust_state.dart';
import 'package:nostrmo/component/new_notes_updated_widget.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/consts/base_consts.dart';
import 'package:nostrmo/provider/group_feed_provider.dart';
import 'package:nostrmo/provider/settings_provider.dart';
import 'package:nostrmo/util/load_more_event.dart';
import 'package:nostrmo/util/theme_util.dart';
import 'package:provider/provider.dart';

import '../event/event_list_widget.dart';

/// Widget that displays event items from multiple communities
class GroupEventListWidget extends StatefulWidget {
  const GroupEventListWidget({super.key});

  @override
  State<GroupEventListWidget> createState() => _GroupEventListWidgetState();
}

class _GroupEventListWidgetState extends KeepAliveCustState<GroupEventListWidget>
    with LoadMoreEvent, PendingEventsLaterFunction {
  final ScrollController _controller = ScrollController();
  ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    bindLoadMoreScroll(_controller);
  }

  GroupFeedProvider? _groupFeedProvider;

  @override
  Widget doBuild(BuildContext context) {
    var settingsProvider = Provider.of<SettingsProvider>(context);
    _groupFeedProvider = Provider.of<GroupFeedProvider>(context);
    final themeData = Theme.of(context);
    
    var eventBox = _groupFeedProvider!.notesBox;
    var events = eventBox.all();

    Widget content;
    if (events.isEmpty) {
      content = _buildEmptyState();
    } else {
      preBuild();

      var main = RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView.builder(
          padding: EdgeInsets.zero,
          controller: scrollController,
          itemBuilder: (context, index) {
            var event = events[index];
            return EventListWidget(
              event: event,
              showVideo: settingsProvider.videoPreviewInList != OpenStatus.close,
            );
          },
          itemCount: events.length,
        ),
      );

      var newNotesLength = _groupFeedProvider!.newNotesBox.length();
      if (newNotesLength <= 0) {
        content = main;
      } else {
        List<Widget> stackList = [main];
        stackList.add(Positioned(
          top: Base.basePadding,
          child: NewNotesUpdatedWidget(
            num: newNotesLength,
            onTap: () {
              _groupFeedProvider!.mergeNewEvent();
              scrollController.jumpTo(0);
            },
          ),
        ));
        content = Stack(
          alignment: Alignment.center,
          children: stackList,
        );
      }
    }

    return Container(
      color: themeData.customColors.feedBgColor,
      child: content,
    );
  }
  
  // Show a message when no posts are available
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.forum_outlined, size: 70, color: Colors.grey),
          const SizedBox(height: 20),
          Text(
            'No posts from your communities yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Posts from all your communities will appear here',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 25),
          ElevatedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Future<void> onReady(BuildContext context) async {
    _groupFeedProvider!.refresh();
  }

  @override
  void doQuery() {
    preQuery();
    if (until != null) {
      _groupFeedProvider!.doQuery(until!);
    }
  }

  @override
  EventMemBox getEventBox() {
    return _groupFeedProvider!.notesBox;
  }

  Future<void> onRefresh() async {
    _groupFeedProvider!.refresh();
  }
}