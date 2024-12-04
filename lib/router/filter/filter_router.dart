import 'package:flutter/material.dart';
import 'package:nostrmo/router/filter/filter_block_component.dart';
import 'package:nostrmo/router/filter/filter_dirtyword_component.dart';
import 'package:nostrmo/util/table_mode_util.dart';

import '../../component/appbar_back_btn_component.dart';
import '../../generated/l10n.dart';
import '../index/index_app_bar.dart';

class FilterWidget extends StatefulWidget {
  const FilterWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return _FilterWidgetState();
  }
}

class _FilterWidgetState extends State<FilterWidget>
    with SingleTickerProviderStateMixin {
  late TabController tabController;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    var s = S.of(context);
    var themeData = Theme.of(context);
    var titleTextColor = themeData.appBarTheme.titleTextStyle!.color;
    var titleTextStyle = TextStyle(
      fontWeight: FontWeight.bold,
      color: titleTextColor,
    );
    Color? indicatorColor = titleTextColor;
    if (TableModeUtil.isTableMode()) {
      indicatorColor = themeData.primaryColor;
    }

    return Scaffold(
      appBar: AppBar(
        leading: const AppbarBackBtnWidget(),
        title: TabBar(
          indicatorColor: indicatorColor,
          indicatorWeight: 3,
          controller: tabController,
          tabs: [
            Container(
              height: IndexAppBar.height,
              alignment: Alignment.center,
              child: Text(
                s.Blocks,
                style: titleTextStyle,
              ),
            ),
            Container(
              height: IndexAppBar.height,
              alignment: Alignment.center,
              child: Text(
                s.Dirtywords,
                style: titleTextStyle,
              ),
            )
          ],
        ),
        actions: [
          Container(
            width: 50,
          ),
        ],
      ),
      body: TabBarView(
        controller: tabController,
        children: const [
          FilterBlockWidget(),
          FilterDirtywordWidget(),
        ],
      ),
    );
  }
}
