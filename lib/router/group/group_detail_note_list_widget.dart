import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/router/group/group_detail_provider.dart';
import 'package:provider/provider.dart';
import 'package:nostrmo/router/group/no_notes_widget.dart';
import 'package:nostrmo/main.dart';
import 'dart:developer';

import '../../component/event/event_list_widget.dart';
import '../../component/keep_alive_cust_state.dart';
import '../../component/new_notes_updated_widget.dart';
import '../../consts/base.dart';
import '../../consts/base_consts.dart';
import '../../provider/settings_provider.dart';
import '../../util/load_more_event.dart';
import '../../util/theme_util.dart';
import '../../util/time_util.dart';
import '../../provider/relay_provider.dart';

class GroupDetailNoteListWidget extends StatefulWidget {
  final GroupIdentifier groupIdentifier;
  final String groupName;

  const GroupDetailNoteListWidget(this.groupIdentifier, this.groupName,
      {super.key});

  @override
  State<StatefulWidget> createState() {
    return _GroupDetailNoteListWidgetState();
  }
}

class _GroupDetailNoteListWidgetState
    extends KeepAliveCustState<GroupDetailNoteListWidget>
    with LoadMoreEvent, PendingEventsLaterFunction {
  final ScrollController _controller = ScrollController();

  ScrollController scrollController = ScrollController();
  final subscribeId = StringUtil.rndNameStr(16);

  @override
  void initState() {
    super.initState();
    bindLoadMoreScroll(_controller);
  }

  GroupDetailProvider? groupDetailProvider;

  @override
  Widget doBuild(BuildContext context) {
    var settingsProvider = Provider.of<SettingsProvider>(context);
    groupDetailProvider = Provider.of<GroupDetailProvider>(context);
    final themeData = Theme.of(context);
    var eventBox = groupDetailProvider!.notesBox;
    var events = eventBox.all();

    Widget content;
    if (events.isEmpty) {
      content = NoNotesWidget(
        groupName: widget.groupName,
        onRefresh: onRefresh,
      );
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
              showVideo:
                  settingsProvider.videoPreviewInList != OpenStatus.close,
            );
          },
          itemCount: events.length,
        ),
      );

      var newNotesLength = groupDetailProvider!.newNotesBox.length();
      if (newNotesLength <= 0) {
        content = main;
      } else {
        List<Widget> stackList = [main];
        stackList.add(Positioned(
          top: Base.basePadding,
          child: NewNotesUpdatedWidget(
            num: newNotesLength,
            onTap: () {
              groupDetailProvider!.mergeNewEvent();
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

  // Track if we've already initialized
  bool _hasInitialized = false;
  
  @override
  Future<void> onReady(BuildContext context) async {
    // Only initialize once to avoid expensive operations when switching tabs
    if (!_hasInitialized) {
      _subscribe();
      _hasInitialized = true;
    }
  }

  void _subscribe() {
    if (StringUtil.isNotBlank(subscribeId)) {
      _unsubscribe();
    }

    final currentTime = currentUnixTimestamp();
    final filters = [
      {
        // Listen for group notes
        // Use #h tag to match how notes are created
        "kinds": [EventKind.groupNote],
        "#h": [widget.groupIdentifier.groupId],
        "since": currentTime
      },
      {
        // Listen for group note replies
        // Use #h tag to match how notes are created
        "kinds": [EventKind.groupNoteReply],
        "#h": [widget.groupIdentifier.groupId],
        "since": currentTime
      },
      {
        // Listen for group chat messages (NIP-29)
        "kinds": [EventKind.groupChatMessage],
        "#h": [widget.groupIdentifier.groupId],
        "since": currentTime
      },
      {
        // Listen for group chat replies (NIP-29)
        "kinds": [EventKind.groupChatReply],
        "#h": [widget.groupIdentifier.groupId],
        "since": currentTime
      }
    ];

    try {
      nostr!.subscribe(
        filters,
        _handleSubscriptionEvent,
        id: subscribeId,
        relayTypes: [RelayType.temp],
        tempRelays: [RelayProvider.defaultGroupsRelayAddress],
        sendAfterAuth: true,
      );
    } catch (e) {
      // log("Error in subscription: $e");
    }
  }

  /// Handles events received from group note subscription.
  void _handleSubscriptionEvent(Event event) {
    later(event, (list) {
      for (final e in list) {
        groupDetailProvider!.onNewEvent(e);
      }
    }, null);
  }

  Future<void> refresh() async {
    _subscribe();
  }

  void _unsubscribe() {
    try {
      nostr!.unsubscribe(subscribeId);
    } catch (e) {
      // log("Error unsubscribing: $e");
    }
  }

  @override
  void dispose() {
    _unsubscribe();
    disposeLater();
    super.dispose();
  }

  @override
  void doQuery() {
    preQuery();
    groupDetailProvider!.doQuery(until);
  }

  @override
  EventMemBox getEventBox() {
    return groupDetailProvider!.notesBox;
  }

  Future<void> onRefresh() async {
    groupDetailProvider!.refresh();
  }
}
