import 'dart:convert';

import 'package:flutter/material.dart';

import '../../component/appbar_back_btn_widget.dart';
import '../../component/cust_state.dart';
import '../../consts/base.dart';
import '../../generated/l10n.dart';
import '../../util/dio_util.dart';
import '../../util/router_util.dart';
import 'package:nostr_sdk/utils/string_util.dart';
import 'web_util_item_widget.dart';

class WebUtilsWidget extends StatefulWidget {
  const WebUtilsWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return _WebUtilsWidgetState();
  }
}

class _WebUtilsWidgetState extends CustState<WebUtilsWidget> {
  @override
  Widget doBuild(BuildContext context) {
    final themeData = Theme.of(context);
    final localization = S.of(context);
    var titleFontSize = themeData.textTheme.bodyLarge!.fontSize;

    List<Widget> list = [
    ];

    for (var item in webUtils) {
      list.add(WebUtilItemWidget(link: item.link, des: item.des));
    }

    return Scaffold(
      appBar: AppBar(
        leading: const AppbarBackBtnWidget(),
        title: Text(
          localization.Web_Utils,
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: list,
        ),
      ),
    );
  }

  @override
  Future<void> onReady(BuildContext context) async {
    load();
  }

  List<WebUtilItem> webUtils = [];

  Future<void> load() async {
    var str = await DioUtil.getStr(Base.WEB_TOOLS);
    if (StringUtil.isNotBlank(str)) {
      var itfs = jsonDecode(str!);
      webUtils = [];
      for (var itf in itfs) {
        if (itf is Map) {
          webUtils.add(WebUtilItem(itf["link"], itf["des"]));
        }
      }
      setState(() {});
    }
  }
}

class WebUtilItem {
  String link;
  String des;

  WebUtilItem(this.link, this.des);
}
