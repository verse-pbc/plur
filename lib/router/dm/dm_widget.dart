import 'package:flutter/material.dart';

import '../../generated/l10n.dart';
import '../index/index_tab_item_widget.dart';
import 'dm_known_list_widget.dart';
import 'dm_unknown_list_widget.dart';

class DMWidget extends StatefulWidget {
  final TabController tabController;

  const DMWidget({super.key, required this.tabController});

  @override
  State<StatefulWidget> createState() {
    return _DMWidgetState();
  }
}

class _DMWidgetState extends State<DMWidget> {
  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final localization = S.of(context);
    final indicatorColor = themeData.primaryColor;
    final titleTextColor = themeData.appBarTheme.titleTextStyle!.color;
    final titleTextStyle = TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: titleTextColor,
    );
    return Column(
        children: [
          TabBar(
            indicatorColor: indicatorColor,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.tab,
            dividerHeight: 0,
            tabs: [
              IndexTabItemWidget(
                localization.DMs,
                titleTextStyle,
                omitText: "DM",
              ),
              IndexTabItemWidget(
                localization.Request,
                titleTextStyle,
                omitText: "R",
              ),
            ],
            controller: widget.tabController,
          ),
          Expanded(
            child: TabBarView(
              controller: widget.tabController,
              children: const [
                DMKnownListWidget(),
                DMUnknownListWidget(),
              ],
            ),
          ),
        ],
      );
  }
}
