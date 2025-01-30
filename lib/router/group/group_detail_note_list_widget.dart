import 'package:flutter/material.dart';
import 'package:nostr_sdk/event_mem_box.dart';
import 'package:nostr_sdk/nip29/group_identifier.dart';
import 'package:nostr_sdk/utils/peddingevents_later_function.dart';
import 'package:nostrmo/router/group/group_detail_provider.dart';
import 'package:provider/provider.dart';
import 'package:nostrmo/router/group/no_notes_widget.dart';

import '../../component/event/event_list_widget.dart';
import '../../component/keep_alive_cust_state.dart';
import '../../component/new_notes_updated_widget.dart';
import '../../consts/base.dart';
import '../../consts/base_consts.dart';
import '../../provider/setting_provider.dart';
import '../../util/load_more_event.dart';
import '../../util/theme_util.dart';

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
              showVideo: settingProvider.videoPreviewInList != OpenStatus.CLOSE,
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
          top: Base.BASE_PADDING,
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

  @override
  Future<void> onReady(BuildContext context) async {}

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
