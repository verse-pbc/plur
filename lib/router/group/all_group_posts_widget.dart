import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/component/event/group_event_list_widget.dart';
import 'package:nostrmo/component/keep_alive_cust_state.dart';
import 'package:nostrmo/component/new_notes_updated_widget.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/consts/base_consts.dart';
import 'package:nostrmo/provider/group_feed_provider.dart';
import 'package:nostrmo/provider/group_provider.dart';
import 'package:nostrmo/provider/settings_provider.dart';
import 'package:nostrmo/router/group/no_notes_widget.dart';
import 'package:nostrmo/util/theme_util.dart';
import 'package:provider/provider.dart';

class AllGroupPostsWidget extends StatefulWidget {
  const AllGroupPostsWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return _AllGroupPostsWidgetState();
  }
}

class _AllGroupPostsWidgetState extends KeepAliveCustState<AllGroupPostsWidget> {
  final ScrollController scrollController = ScrollController();

  GroupFeedProvider? groupFeedProvider;

  @override
  Widget doBuild(BuildContext context) {
    var settingsProvider = Provider.of<SettingsProvider>(context);
    groupFeedProvider = Provider.of<GroupFeedProvider>(context);
    final themeData = Theme.of(context);
    var eventBox = groupFeedProvider!.notesBox;
    var events = eventBox.all();

    Widget content;
    if (events.isEmpty) {
      content = NoNotesWidget(
        groupName: "your communities",
        onRefresh: onRefresh,
      );
    } else {
      var main = RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView.builder(
          padding: EdgeInsets.zero,
          controller: scrollController,
          itemBuilder: (context, index) {
            var event = events[index];
            return GroupEventListWidget(
              event: event,
              showVideo: settingsProvider.videoPreviewInList != OpenStatus.CLOSE,
            );
          },
          itemCount: events.length,
        ),
      );

      var newNotesLength = groupFeedProvider!.newNotesBox.length();
      if (newNotesLength <= 0) {
        content = main;
      } else {
        List<Widget> stackList = [main];
        stackList.add(Positioned(
          top: Base.basePadding,
          child: NewNotesUpdatedWidget(
            num: newNotesLength,
            onTap: () {
              groupFeedProvider!.mergeNewEvent();
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

  @override
  Future<void> onReady(BuildContext context) async {
    groupFeedProvider!.subscribe();
    groupFeedProvider!.doQuery(null);
  }

  Future<void> onRefresh() async {
    groupFeedProvider!.refresh();
  }
}