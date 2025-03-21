import 'package:flutter/material.dart';
import 'package:nostrmo/nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/component/keep_alive_cust_state.dart';
import 'package:nostrmo/component/new_notes_updated_widget.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/consts/base_consts.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/provider/follow_event_provider.dart';
import 'package:nostrmo/provider/follow_new_event_provider.dart';
import 'package:nostrmo/util/table_mode_util.dart';
import 'package:provider/provider.dart';

import '../../component/event/event_list_widget.dart';
import '../../component/placeholder/event_list_placeholder.dart';
import '../../provider/settings_provider.dart';
import '../../util/load_more_event.dart';

class FollowPostsWidget extends StatefulWidget {
  const FollowPostsWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return _FollowPostsWidgetState();
  }
}

class _FollowPostsWidgetState extends KeepAliveCustState<FollowPostsWidget>
    with LoadMoreEvent {
  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    bindLoadMoreScroll(_controller);
  }

  @override
  Widget doBuild(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    var followEventProvider = Provider.of<FollowEventProvider>(context);

    var eventBox = followEventProvider.postsBox;
    var events = eventBox.all();
    if (events.isEmpty) {
      return EventListPlaceholder(
        onRefresh: () {
          followEventProvider.refresh();
        },
      );
    }
    indexProvider.setFollowPostsScrollController(_controller);
    preBuild();

    var main = ListView.builder(
      controller: _controller,
      itemBuilder: (BuildContext context, int index) {
        var event = events[index];
        return EventListWidget(
          event: event,
          showVideo: settingsProvider.videoPreviewInList != OpenStatus.CLOSE,
        );
      },
      itemCount: events.length,
    );

    Widget ri = RefreshIndicator(
      onRefresh: () async {
        followEventProvider.refresh();
      },
      child: main,
    );

    if (TableModeUtil.isTableMode()) {
      ri = GestureDetector(
        onVerticalDragUpdate: (detail) {
          _controller.jumpTo(_controller.offset - detail.delta.dy);
        },
        behavior: HitTestBehavior.translucent,
        child: ri,
      );
    }

    List<Widget> stackList = [ri];
    stackList.add(Positioned(
      top: Base.basePadding,
      child: Selector<FollowNewEventProvider, int>(
        builder: (context, newEventNum, child) {
          if (newEventNum <= 0) {
            return Container();
          }

          return NewNotesUpdatedWidget(
            num: newEventNum,
            onTap: () {
              followEventProvider.mergeNewEvent();
              _controller.jumpTo(0);
            },
          );
        },
        selector: (_, provider) {
          return provider.eventPostMemBox.length();
        },
      ),
    ));
    return Stack(
      alignment: Alignment.center,
      children: stackList,
    );
  }

  @override
  void doQuery() {
    preQuery();
    followEventProvider.doQuery(until: until, forceUserLimit: forceUserLimit);
  }

  @override
  EventMemBox getEventBox() {
    return followEventProvider.postsBox;
  }

  @override
  Future<void> onReady(BuildContext context) async {}
}
