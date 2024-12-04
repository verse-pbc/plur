import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../main.dart';
import '../../provider/dm_provider.dart';
import 'dm_known_list_router.dart';
import 'dm_session_list_item_component.dart';
import 'dm_unknown_list_router.dart';

class DMWidget extends StatefulWidget {
  TabController tabController;

  DMWidget({super.key, required this.tabController});

  @override
  State<StatefulWidget> createState() {
    return _DMWidgetState();
  }
}

class _DMWidgetState extends State<DMWidget> {
  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);

    return Container(
      color: themeData.scaffoldBackgroundColor,
      child: TabBarView(
        controller: widget.tabController,
        children: [
          DMKnownListWidget(),
          DMUnknownListWidget(),
        ],
      ),
    );
  }
}
