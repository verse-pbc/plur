import 'dart:convert';
import 'dart:math';

import 'package:dynamic_height_grid_view/dynamic_height_grid_view.dart';
import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/component/cust_state.dart';
import 'package:nostrmo/component/user/simple_user_widget.dart';

import '../../consts/base.dart';
import '../../generated/l10n.dart';
import '../../main.dart';
import '../../util/dio_util.dart';

import '../../util/table_mode_util.dart';

class FollowSuggestWidget extends StatefulWidget {
  const FollowSuggestWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return _FollowSuggestWidgetState();
  }
}

class _FollowSuggestWidgetState extends CustState<FollowSuggestWidget> {
  @override
  Widget doBuild(BuildContext context) {
    final localization = S.of(context);
    final themeData = Theme.of(context);
    var mainColor = themeData.primaryColor;

    var mediaData = MediaQuery.of(context);

    int crossAxisCount = 1;
    if (TableModeUtil.isTableMode()) {
      crossAxisCount = 2;
    }

    List<Widget> mainList = [];
    mainList.add(Container(
      margin: const EdgeInsets.only(
        top: Base.basePadding,
        bottom: 18,
      ),
      child: Text(
        localization.Popular_Users,
        style: TextStyle(
          fontSize: themeData.textTheme.bodyLarge!.fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    ));

    List<Widget> userWidgetList = [];
    for (var pubkey in pubkeys) {
      userWidgetList.add(SimpleUserWidget(
        pubkey: pubkey,
      ));
    }
    mainList.add(Expanded(
      child: DynamicHeightGridView(
        shrinkWrap: true,
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: Base.basePadding,
        crossAxisSpacing: Base.basePadding,
        itemCount: pubkeys.length,
        builder: (context, index) {
          var pubkey = pubkeys[index];
          return SimpleUserWidget(
            pubkey: pubkey,
            showFollow: true,
          );
        },
      ),
    ));

    mainList.add(Container(
      width: double.maxFinite,
      alignment: Alignment.centerRight,
      margin: const EdgeInsets.only(
        top: Base.basePadding * 2,
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: goToIndex,
        child: Text(
          "Go!",
          style: TextStyle(
            color: mainColor,
            decoration: TextDecoration.underline,
            decorationColor: mainColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ));

    return Scaffold(
      body: Container(
        padding: EdgeInsets.only(
          top: mediaData.padding.top + Base.basePadding,
          right: Base.basePadding * 2,
          bottom: Base.basePadding * 2,
          left: Base.basePadding * 2,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: mainList,
        ),
      ),
    );
  }

  void goToIndex() {
    newUser = false;
    settingsProvider.notify();
  }

  @override
  Future<void> onReady(BuildContext context) async {
    loadData();
  }

  List<String> pubkeys = [];

  Future<void> loadData() async {
    var str = await DioUtil.getStr(Base.indexsContacts);
    if (StringUtil.isNotBlank(str)) {
      pubkeys.clear();
      var itfs = jsonDecode(str!);
      for (var itf in itfs) {
        pubkeys.add(itf as String);
      }

      // Disorder
      for (var i = 1; i < pubkeys.length; i++) {
        var j = getRandomInt(0, i);
        var t = pubkeys[i];
        pubkeys[i] = pubkeys[j];
        pubkeys[j] = t;
      }

      // query the pre 20 pubkeys
      List<Map<String, dynamic>> filters = [];
      for (var i = 0; i < pubkeys.length && i < 10; i++) {
        var pubkey = pubkeys[i];
        var filter = Filter(kinds: [
          EventKind.metadata,
        ], authors: [
          pubkey
        ]);
        filters.add(filter.toJson());
      }
      if (filters.isNotEmpty) {
        nostr!.addInitQuery(filters, onEvent);
      }
      filters = [];
      for (var i = 10; i < pubkeys.length && i < 20; i++) {
        var pubkey = pubkeys[i];
        var filter = Filter(kinds: [
          EventKind.metadata,
        ], authors: [
          pubkey
        ]);
        filters.add(filter.toJson());
      }
      if (filters.isNotEmpty) {
        nostr!.addInitQuery(filters, onEvent);
      }

      setState(() {});
    }
  }

  void onEvent(Event e) {
    userProvider.onEvent(e);
  }

  int getRandomInt(int min, int max) {
    final random = Random();
    return random.nextInt((max - min).floor()) + min;
  }
}
