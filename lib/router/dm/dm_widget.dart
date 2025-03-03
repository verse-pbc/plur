import 'package:flutter/material.dart';

import 'dm_known_list_widget.dart';
import 'dm_unknown_list_widget.dart';

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
    final themeData = Theme.of(context);

    return Container(
      color: themeData.scaffoldBackgroundColor,
      child: TabBarView(
        controller: widget.tabController,
        children: [
          const DMKnownListWidget(),
          const DMUnknownListWidget(),
        ],
      ),
    );
  }
}
