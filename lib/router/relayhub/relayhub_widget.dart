import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:nostr_sdk/relay/relay_status.dart';
import 'package:nostrmo/component/cust_state.dart';
import 'package:nostrmo/component/placeholder/user_relay_placeholder.dart';
import 'package:nostrmo/generated/l10n.dart';
import 'package:nostrmo/main.dart';
import 'package:provider/provider.dart';

import '../../component/appbar_back_btn_widget.dart';
import '../../consts/base.dart';
import '../../provider/relay_provider.dart';
import '../../util/dio_util.dart';
import '../../util/router_util.dart';
import 'package:nostr_sdk/utils/string_util.dart';
import '../user/user_relays_widget.dart';

class RelayhubWidget extends StatefulWidget {
  const RelayhubWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return _RelayhubWidgetState();
  }
}

class _RelayhubWidgetState extends CustState<RelayhubWidget> {
  List<String> addrs = [];

  @override
  Widget doBuild(BuildContext context) {
    final themeData = Theme.of(context);
    var titleFontSize = themeData.textTheme.bodyLarge!.fontSize;

    Widget mainWidget;
    if (addrs.isNotEmpty) {
      mainWidget = ListView.builder(
        itemBuilder: (context, index) {
          var relayAddr = addrs[index];
          return Selector<RelayProvider, RelayStatus?>(
              builder: (context, relayStatus, child) {
            return RelayMetadataWidget(
              addr: relayAddr,
              addAble: relayStatus == null,
            );
          }, selector: (_, provider) {
            return provider.getRelayStatus(relayAddr);
          });
        },
        itemCount: addrs.length,
      );
    } else {
      mainWidget = ListView.builder(
        itemBuilder: (context, index) {
          return UserRelayPlaceholder();
        },
        itemCount: 10,
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: const AppbarBackBtnWidget(),
        title: Text(
          "Relayhub",
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          GestureDetector(
            onTap: testAllSpeed,
            child: Container(
              padding: EdgeInsets.only(right: Base.BASE_PADDING),
              child: Icon(
                Icons.speed,
                color: themeData.appBarTheme.titleTextStyle!.color,
              ),
            ),
          ),
        ],
      ),
      body: Container(
        margin: const EdgeInsets.only(
          top: Base.BASE_PADDING,
        ),
        child: mainWidget,
      ),
    );
  }

  @override
  Future<void> onReady(BuildContext context) async {
    var str = await DioUtil.getStr(Base.INDEXS_RELAYS);
    // print(str);
    if (StringUtil.isNotBlank(str)) {
      addrs.clear();
      var itfs = jsonDecode(str!);
      for (var itf in itfs) {
        addrs.add(itf as String);
      }
    }

    setState(() {});
  }

  Future<void> testAllSpeed() async {
    for (var addr in addrs) {
      await urlSpeedProvider.testSpeed(addr);
    }
  }
}
