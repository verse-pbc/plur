import 'package:flutter/material.dart';
import 'package:nostr_sdk/event_mem_box.dart';
import 'package:nostr_sdk/nip29/group_identifier.dart';
import 'package:nostr_sdk/utils/peddingevents_later_function.dart';
import 'package:nostrmo/router/group/group_detail_provider.dart';
import 'package:provider/provider.dart';
import 'package:nostrmo/router/group/no_notes_widget.dart';
import 'package:nostr_sdk/utils/string_util.dart';
import 'package:nostr_sdk/event_kind.dart';
import 'package:nostr_sdk/filter.dart';
import 'package:nostr_sdk/relay/relay_type.dart';
import 'package:nostr_sdk/event.dart';
import 'package:nostrmo/main.dart';

import '../../component/event/event_list_widget.dart';
import '../../component/keep_alive_cust_state.dart';
import '../../component/new_notes_updated_widget.dart';
import '../../consts/base.dart';
import '../../consts/base_consts.dart';
import '../../provider/setting_provider.dart';
import '../../util/load_more_event.dart';
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
    with LoadMoreEvent, PenddingEventsLaterFunction {
  final ScrollController _controller = ScrollController();

  ScrollController scrollController = ScrollController();
  var subscribeId = StringUtil.rndNameStr(16);

  @override
  void initState() {
    super.initState();
    bindLoadMoreScroll(_controller);
  }

  GroupDetailProvider? groupDetailProvider;

  @override
  Widget doBuild(BuildContext context) {
    var settingProvider = Provider.of<SettingProvider>(context);
    groupDetailProvider = Provider.of<GroupDetailProvider>(context);

    var eventBox = groupDetailProvider!.notesBox;
    var events = eventBox.all();

    if (events.isEmpty) {
      return NoNotesWidget(
        groupName: widget.groupName,
        onRefresh: onRefresh,
      );
    }
    preBuild();

    var main = RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        controller: scrollController,
        itemBuilder: (context, index) {
          var event = events[index];
          return EventListWidget(
            event: event,
            showVideo: settingProvider.videoPreviewInList != OpenStatus.CLOSE,
          );
        },
        itemCount: events.length,
      ),
    );

    var newNotesLength = groupDetailProvider!.newNotesBox.length();
    if (newNotesLength <= 0) {
      return main;
    }

    List<Widget> stackList = [main];
    stackList.add(Positioned(
      top: Base.BASE_PADDING,
      child: NewNotesUpdatedWidget(
        num: newNotesLength,
        onTap: () {
          groupDetailProvider!.mergeNewEvent();
          scrollController.jumpTo(0);
        },
      ),
    ));

    return Stack(
      alignment: Alignment.center,
      children: stackList,
    );
  }

  @override
  Future<void> onReady(BuildContext context) async {
    _subscribe();
  }

  void _subscribe() {
    if (StringUtil.isNotBlank(subscribeId)) {
      _unsubscribe();
    }

    final noteFilter = Filter(kinds: [EventKind.GROUP_NOTE]);
    final noteFilterMap = noteFilter.toJson();
    // Use #h tag to match how notes are created
    noteFilterMap["#h"] = [widget.groupIdentifier.groupId];

    final noteReplyFilter = Filter(kinds: [EventKind.GROUP_NOTE_REPLY]);
    final noteReplyFilterMap = noteReplyFilter.toJson();
    // Use #h tag to match how notes are created
    noteReplyFilterMap["#h"] = [widget.groupIdentifier.groupId];

    try {
      nostr!.subscribe(
        [
          noteFilterMap,
          noteReplyFilterMap,
        ],
        _handleSubscriptionEvent,
        id: subscribeId,
        relayTypes: [RelayType.TEMP],
        tempRelays: [RelayProvider.defaultGroupsRelayAddress],
        sendAfterAuth: true,
      );
    } catch (e) {
      print("Error in subscription: $e");
    }
  }

  /// Handles events received from group note subscription.
  void _handleSubscriptionEvent(Event event) {
    later(event, (list) {
      for (var e in list) {
        groupDetailProvider!.onNewEvent(e);
      }
    }, null);
  }

  /// Handles events created by the current user.
  void handleDirectEvent(Event event) {
    groupDetailProvider?.handleDirectEvent(event);
  }

  Future<void> refresh() async {
    _subscribe();
  }

  void _unsubscribe() {
    try {
      nostr!.unsubscribe(subscribeId);
    } catch (e) {
      print("Error unsubscribing: $e");
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
