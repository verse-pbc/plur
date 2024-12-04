import 'package:flutter/material.dart';

import 'events/globals_events_router.dart';
import 'tags/globals_tags_router.dart';
import 'users/globals_users_router.dart';

class GlobalsIndexWidget extends StatefulWidget {
  TabController tabController;

  GlobalsIndexWidget({super.key, required this.tabController});

  @override
  State<StatefulWidget> createState() {
    return _GlobalsIndexWidgetState();
  }
}

class _GlobalsIndexWidgetState extends State<GlobalsIndexWidget> {
  @override
  Widget build(BuildContext context) {
    return TabBarView(
      controller: widget.tabController,
      children: [
        const GlobalsEventsWidget(),
        GlobalsUsersWidget(),
        const GlobalsTagsWidget(),
      ],
    );
  }
}
