import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';

import '../../../component/keep_alive_cust_state.dart';
import '../../../component/placeholder/tap_list_placeholder.dart';
import '../../../component/tag_widget.dart';
import '../../../consts/base.dart';
import '../../../util/dio_util.dart';

class GlobalsTagsWidget extends StatefulWidget {
  const GlobalsTagsWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return _GlobalsTagsWidgetState();
  }
}

class _GlobalsTagsWidgetState extends KeepAliveCustState<GlobalsTagsWidget> {
  List<String> topics = [];

  @override
  Widget doBuild(BuildContext context) {
    final themeData = Theme.of(context);

    if (topics.isEmpty) {
      return const TapListPlaceholder();
    } else {
      List<Widget> list = [];
      for (var topic in topics) {
        list.add(TagWidget(
          tag: topic,
        ));
      }

      return Container(
        color: themeData.cardColor,
        child: Center(
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 14,
              runSpacing: 14,
              alignment: WrapAlignment.center,
              children: list,
            ),
          ),
        ),
      );
    }
  }

  @override
  Future<void> onReady(BuildContext context) async {
    var str = await DioUtil.getStr(Base.indexsTopics);
    if (StringUtil.isNotBlank(str)) {
      topics.clear();
      var itfs = jsonDecode(str!);
      for (var itf in itfs) {
        topics.add(itf as String);
      }

      // Disorder
      for (var i = 1; i < topics.length; i++) {
        var j = getRandomInt(0, i);
        var t = topics[i];
        topics[i] = topics[j];
        topics[j] = t;
      }

      setState(() {});
    }
  }

  int getRandomInt(int min, int max) {
    final random = Random();
    return random.nextInt((max - min).floor()) + min;
  }
}
