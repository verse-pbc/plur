import 'dart:convert';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:nostrmo/nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:provider/provider.dart';

import '../../component/appbar_back_btn_widget.dart';
import '../../component/cust_state.dart';
import '../../consts/base.dart';
import '../../generated/l10n.dart';
import '../../main.dart';
import '../../provider/relay_provider.dart';
import '../../util/router_util.dart';
import 'relays_item_widget.dart';

class RelaysWidget extends StatefulWidget {
  const RelaysWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return _RelaysWidgetState();
  }
}

class _RelaysWidgetState extends CustState<RelaysWidget> with WhenStopFunction {
  TextEditingController controller = TextEditingController();

  int relayType = RelayType.NORMAL;

  @override
  Widget doBuild(BuildContext context) {
    final localization = S.of(context);
    var _relayProvider = Provider.of<RelayProvider>(context);
    var relayAddrs = _relayProvider.relayAddrs;
    var relayStatusLocal = _relayProvider.relayStatusLocal;
    var relayStatusMap = _relayProvider.relayStatusMap;
    final themeData = Theme.of(context);
    var color = themeData.textTheme.bodyLarge!.color;
    var titleFontSize = themeData.textTheme.bodyLarge!.fontSize;

    List<Widget> list = [];

    if (relayStatusLocal != null) {
      list.add(RelaysItemWidget(
        addr: relayStatusLocal.addr,
        relayStatus: relayStatusLocal,
        editable: false,
      ));
    }

    list.add(Container(
      padding: EdgeInsets.only(
        left: Base.BASE_PADDING,
        bottom: Base.BASE_PADDING_HALF,
      ),
      child: Row(
        children: [
          Text(
            localization.MyRelays,
            style: TextStyle(
              fontSize: titleFontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          GestureDetector(
            onTap: testAllMyRelaysSpeed,
            child: Container(
              margin: EdgeInsets.only(left: Base.BASE_PADDING),
              child: Icon(Icons.speed),
            ),
          )
        ],
      ),
    ));
    for (var i = 0; i < relayAddrs.length; i++) {
      var addr = relayAddrs[i];
      var relayStatus = relayStatusMap[addr];
      relayStatus ??= RelayStatus(addr);

      var rwText = "W R";
      if (relayStatus.readAccess && !relayStatus.writeAccess) {
        rwText = "R";
      } else if (!relayStatus.readAccess && relayStatus.writeAccess) {
        rwText = "W";
      }

      list.add(RelaysItemWidget(
        addr: addr,
        relayStatus: relayStatus,
        rwText: rwText,
      ));
    }

    if (_relayProvider.cacheRelayAddrs.isNotEmpty) {
      list.add(Container(
        padding: EdgeInsets.only(
          left: Base.BASE_PADDING,
          bottom: Base.BASE_PADDING_HALF,
        ),
        child: Text(
          localization.Cache_Relay,
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ));

      for (var i = 0; i < _relayProvider.cacheRelayAddrs.length; i++) {
        var addr = _relayProvider.cacheRelayAddrs[i];
        var relayStatus = relayStatusMap[addr];
        relayStatus ??= RelayStatus(addr);

        var rwText = "W R";
        if (relayStatus.readAccess && !relayStatus.writeAccess) {
          rwText = "R";
        } else if (!relayStatus.readAccess && relayStatus.writeAccess) {
          rwText = "W";
        }

        list.add(RelaysItemWidget(
          addr: addr,
          relayStatus: relayStatus,
          rwText: rwText,
        ));
      }
    }

    var tempRelayStatus = _relayProvider.tempRelayStatus();
    if (tempRelayStatus.isNotEmpty) {
      list.add(Container(
        padding: EdgeInsets.only(
          left: Base.BASE_PADDING,
          bottom: Base.BASE_PADDING_HALF,
        ),
        child: Text(
          localization.TempRelays,
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ));
      for (var i = 0; i < tempRelayStatus.length; i++) {
        var relayStatus = tempRelayStatus[i];

        var rwText = "W R";
        if (relayStatus.readAccess && !relayStatus.writeAccess) {
          rwText = "R";
        } else if (!relayStatus.readAccess && relayStatus.writeAccess) {
          rwText = "W";
        }

        list.add(RelaysItemWidget(
          addr: relayStatus.addr,
          relayStatus: relayStatus,
          rwText: rwText,
          editable: false,
        ));
      }
    }

    return Scaffold(
      appBar: AppBar(
        leading: const AppbarBackBtnWidget(),
        title: Text(
          localization.Relays,
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () {
              RouterUtil.router(context, RouterPath.RELAYHUB);
            },
            child: Container(
              padding: EdgeInsets.only(right: Base.BASE_PADDING),
              child: Icon(
                Icons.cloud,
                color: themeData.appBarTheme.titleTextStyle!.color,
              ),
            ),
          ),
        ],
      ),
      body: Column(children: [
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(
              top: Base.BASE_PADDING,
            ),
            child: ListView(
              children: list,
            ),
          ),
        ),
        Row(children: [
          Container(
            padding: const EdgeInsets.only(left: Base.BASE_PADDING),
            child: const Icon(Icons.cloud),
          ),
          DropdownButton(
            underline: Container(
              height: 0,
            ),
            value: relayType,
            padding: const EdgeInsets.only(
                left: Base.BASE_PADDING, right: Base.BASE_PADDING_HALF),
            items: [
              DropdownMenuItem(
                value: RelayType.NORMAL,
                child: Text(localization.Normal),
              ),
              DropdownMenuItem(
                value: RelayType.CACHE,
                child: Text(localization.Cache),
              ),
            ],
            onChanged: (v) {
              if (v != null) {
                setState(() {
                  relayType = v;
                });
              }
            },
          ),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: localization.Input_relay_address,
                suffixIcon: IconButton(
                  icon: Icon(Icons.add),
                  onPressed: addRelay,
                ),
              ),
            ),
          ),
        ]),
      ]),
    );
  }

  void addRelay() {
    var addr = controller.text;
    addr = addr.trim();
    if (StringUtil.isBlank(addr)) {
      BotToast.showText(text: S.of(context).Address_can_t_be_null);
      return;
    }

    if (relayType == RelayType.NORMAL) {
      relayProvider.addRelay(addr);
    } else if (relayType == RelayType.CACHE) {
      relayProvider.addCacheRelay(addr);
    } else {
      return;
    }

    controller.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Future<void> onReady(BuildContext context) async {}

  void testAllMyRelaysSpeed() {
    var relayAddrs = relayProvider.relayAddrs;
    for (var i = 0; i < relayAddrs.length; i++) {
      var relayAddr = relayAddrs[i];
      urlSpeedProvider.testSpeed(relayAddr);
    }
  }
}
