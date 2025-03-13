import 'package:flutter/material.dart';
import 'package:nostrmo/nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/component/keep_alive_cust_state.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/provider/mention_me_new_provider.dart';
import 'package:nostrmo/provider/mention_me_provider.dart';
import 'package:nostrmo/util/load_more_event.dart';
import 'package:provider/provider.dart';

import '../../component/badge_award_widget.dart';
import '../../component/event/event_list_widget.dart';
import '../../component/event/zap_event_list_widget.dart';
import '../../component/new_notes_updated_widget.dart';
import '../../component/placeholder/event_list_placeholder.dart';
import '../../consts/base.dart';
import '../../consts/base_consts.dart';
import '../../provider/settings_provider.dart';
import '../../util/table_mode_util.dart';

class MentionMeWidget extends StatefulWidget {
  const MentionMeWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return _MentionMeWidgetState();
  }
}

class _MentionMeWidgetState extends KeepAliveCustState<MentionMeWidget>
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
    var mentionMeProvider = Provider.of<MentionMeProvider>(context);
    var eventBox = mentionMeProvider.eventBox;
    var events = eventBox.all();
    if (events.isEmpty) {
      return EventListPlaceholder(
        onRefresh: () {
          mentionMeProvider.refresh();
        },
      );
    }
    indexProvider.setMentionedScrollController(_controller);
    preBuild();

    var main = ListView.builder(
      controller: _controller,
      itemBuilder: (BuildContext context, int index) {
        var event = events[index];
        if (event.kind == EventKind.BADGE_AWARD) {
          return BadgeAwardWidget(event: event);
        } else {
          if (event.kind == EventKind.ZAP) {
            if (StringUtil.isBlank(event.content)) {
              var innerZapContent = EventRelation.getInnerZapContent(event);
              if (StringUtil.isBlank(innerZapContent)) {
                return ZapEventListWidget(event: event);
              }
            }
          }

          return EventListWidget(
            event: event,
            showVideo: settingsProvider.videoPreviewInList != OpenStatus.CLOSE,
          );
        }
      },
      itemCount: events.length,
    );

    Widget ri = RefreshIndicator(
      onRefresh: () async {
        mentionMeProvider.refresh();
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
      child: Selector<MentionMeNewProvider, int>(
        builder: (context, newEventNum, child) {
          if (newEventNum <= 0) {
            return Container();
          }

          return NewNotesUpdatedWidget(
            num: newEventNum,
            onTap: () {
              mentionMeProvider.mergeNewEvent();
              _controller.jumpTo(0);
            },
          );
        },
        selector: (_, provider) {
          return provider.eventMemBox.length();
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
    mentionMeProvider.doQuery(until: until);
  }

  @override
  EventMemBox getEventBox() {
    return mentionMeProvider.eventBox;
  }

  @override
  Future<void> onReady(BuildContext context) async {}
}
