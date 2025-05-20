
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:provider/provider.dart';

import '../../component/appbar_back_btn_widget.dart';
import '../../component/cust_state.dart';
import '../../component/styled_input_field_widget.dart';
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

  int relayType = RelayType.normal;

  @override
  Widget doBuild(BuildContext context) {
    final localization = S.of(context);
    var relayProvider = Provider.of<RelayProvider>(context);
    var relayAddrs = relayProvider.relayAddrs;
    var relayStatusLocal = relayProvider.relayStatusLocal;
    var relayStatusMap = relayProvider.relayStatusMap;
    final themeData = Theme.of(context);
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
      padding: const EdgeInsets.only(
        left: Base.basePadding,
        bottom: Base.basePaddingHalf,
      ),
      child: Row(
        children: [
          Text(
            localization.myRelays,
            style: TextStyle(
              fontSize: titleFontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          GestureDetector(
            onTap: testAllMyRelaysSpeed,
            child: Container(
              margin: const EdgeInsets.only(left: Base.basePadding),
              child: const Icon(Icons.speed),
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

    if (relayProvider.cacheRelayAddrs.isNotEmpty) {
      list.add(Container(
        padding: const EdgeInsets.only(
          left: Base.basePadding,
          bottom: Base.basePaddingHalf,
        ),
        child: Text(
          localization.cacheRelay,
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ));

      for (var i = 0; i < relayProvider.cacheRelayAddrs.length; i++) {
        var addr = relayProvider.cacheRelayAddrs[i];
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

    var tempRelayStatus = relayProvider.tempRelayStatus();
    if (tempRelayStatus.isNotEmpty) {
      list.add(Container(
        padding: const EdgeInsets.only(
          left: Base.basePadding,
          bottom: Base.basePaddingHalf,
        ),
        child: Text(
          localization.tempRelays,
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
          localization.relays,
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () {
              RouterUtil.router(context, RouterPath.relayhub);
            },
            child: Container(
              padding: const EdgeInsets.only(right: Base.basePadding),
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
              top: Base.basePadding,
            ),
            child: ListView(
              children: list,
            ),
          ),
        ),
        Row(children: [
          Container(
            padding: const EdgeInsets.only(left: Base.basePadding),
            child: const Icon(Icons.cloud),
          ),
          DropdownButton(
            underline: Container(
              height: 0,
            ),
            value: relayType,
            padding: const EdgeInsets.only(
                left: Base.basePadding, right: Base.basePaddingHalf),
            items: [
              DropdownMenuItem(
                value: RelayType.normal,
                child: Text(localization.normal),
              ),
              DropdownMenuItem(
                value: RelayType.cache,
                child: Text(localization.cache),
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
            child: StyledInputFieldWidget(
              controller: controller,
              hintText: localization.inputRelayAddress,
              suffixIcon: IconButton(
                icon: const Icon(Icons.add),
                onPressed: addRelay,
              ),
              onSubmitted: (_) => addRelay(),
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
      BotToast.showText(text: S.of(context).addressCantBeNull);
      return;
    }

    if (relayType == RelayType.normal) {
      relayProvider.addRelay(addr);
    } else if (relayType == RelayType.cache) {
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
