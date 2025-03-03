import 'package:flutter/material.dart';
import 'package:nostrmo/nostr_sdk/nostr_sdk.dart';

import '../../consts/base.dart';
import '../../data/event_find_util.dart';
import '../../util/router_util.dart';
import '../event/event_list_widget.dart';
import 'search_mention_widget.dart';

class SearchMentionEventWidget extends StatefulWidget {
  const SearchMentionEventWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return _SearchMentionEventWidgetState();
  }
}

class _SearchMentionEventWidgetState extends State<SearchMentionEventWidget>
    with WhenStopFunction {
  @override
  Widget build(BuildContext context) {
    return SearchMentionWidget(
      resultBuildFunc: resultBuild,
      handleSearchFunc: handleSearch,
    );
  }

  Widget resultBuild() {
    return Container(
      padding: const EdgeInsets.only(
        top: Base.BASE_PADDING_HALF,
        bottom: Base.BASE_PADDING_HALF,
      ),
      child: ListView.builder(
        itemBuilder: (context, index) {
          var event = events[index];
          return GestureDetector(
            onTap: () {
              RouterUtil.back(context, event.id);
            },
            child: EventListWidget(
              event: event,
              jumpable: false,
            ),
          );
        },
        itemCount: events.length,
      ),
    );
  }

  static const int searchMemLimit = 100;

  List<Event> events = [];

  Future<void> handleSearch(String? text) async {
    events.clear();
    if (StringUtil.isNotBlank(text)) {
      var list = await EventFindUtil.findEvent(text!, limit: searchMemLimit);
      setState(() {
        events = list;
      });
    }
  }
}
