import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/util/table_mode_util.dart';

import '../../consts/base.dart';
import '../../generated/l10n.dart';
import '../../router/index/index_app_bar.dart';
import '../../util/router_util.dart';
import '../../util/theme_util.dart';
import 'text_input_dialog_inner_widget.dart';

class TextInputAndSearchDialog extends StatefulWidget {
  final String searchTabName;

  final String title;

  final String? hintText;

  final String? value;

  final Widget searchWidget;

  final bool Function(BuildContext, String)? valueCheck;

  const TextInputAndSearchDialog(
    this.searchTabName,
    this.title,
    this.searchWidget, 
    {
      super.key, 
      this.hintText,
      this.value,
      this.valueCheck,
    }
  );

  static Future<String?> show(BuildContext context, String searchTabName,
      String title, Widget searchWidget,
      {String? value,
      String? hintText,
      bool Function(BuildContext, String)? valueCheck}) async {
    return await showDialog<String>(
        context: context,
        useRootNavigator: false,
        builder: (context) {
          return TextInputAndSearchDialog(
            searchTabName,
            StringUtil.breakWord(title),
            searchWidget,
            hintText: hintText,
            value: value,
            valueCheck: valueCheck,
          );
        });
  }

  @override
  State<StatefulWidget> createState() {
    return _TextInputAndSearchDialog();
  }
}

class _TextInputAndSearchDialog extends State<TextInputAndSearchDialog>
    with SingleTickerProviderStateMixin {
  late TabController tabController;

  @override
  void initState() {
    super.initState();
    tabController = TabController(initialIndex: 0, length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final localization = S.of(context);
    final themeData = Theme.of(context);
    var cardColro = themeData.cardColor;
    var mainColor = themeData.primaryColor;

    double mainHeight = 266;
    if (TableModeUtil.isTableMode()) {
      mainHeight = mediaDataCache.size.height / 2;
    }

    var textInputWidget = TextInputDialogInnerWidget(
      widget.title,
      hintText: widget.hintText,
      value: widget.value,
      valueCheck: widget.valueCheck,
    );

    List<Widget> list = [];
    list.add(Container(
      color: mainColor,
      child: TabBar(
        tabs: [
          Container(
            height: IndexAppBar.height,
            alignment: Alignment.center,
            child: Text(widget.searchTabName),
          ),
          Container(
            height: IndexAppBar.height,
            alignment: Alignment.center,
            child: Text(
              localization.Input,
              textAlign: TextAlign.center,
            ),
          ),
        ],
        controller: tabController,
      ),
    ));
    list.add(SizedBox(
      height: mainHeight,
      width: double.infinity,
      child: TabBarView(
        controller: tabController,
        children: [
          widget.searchWidget,
          textInputWidget,
        ],
      ),
    ));

    var main = Container(
      color: cardColro,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: list,
      ),
    );

    return Scaffold(
      backgroundColor: ThemeUtil.getDialogCoverColor(themeData),
      body: FocusScope(
        // autofocus: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            RouterUtil.back(context);
          },
          child: Container(
            width: double.infinity,
            height: double.infinity,
            padding: const EdgeInsets.only(
              left: Base.basePadding,
              right: Base.basePadding,
            ),
            alignment: Alignment.center,
            child: GestureDetector(
              onTap: () {},
              child: main,
            ),
          ),
        ),
      ),
    );
  }
}
