import 'dart:developer';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/provider/relay_provider.dart';
import 'package:provider/provider.dart';

import '../consts/base.dart';
import '../generated/l10n.dart';
import '../main.dart';
import '../util/router_util.dart';
import '../util/theme_util.dart';

class SyncUploadDialog extends StatefulWidget {
  final List<Event> events;

  const SyncUploadDialog({super.key, required this.events});

  static Future<void> show(BuildContext context, List<Event> events) async {
    await showDialog(
      context: context,
      useRootNavigator: false,
      builder: (context) {
        return SyncUploadDialog(
          events: events,
        );
      },
    );
  }

  @override
  State<StatefulWidget> createState() {
    return _SyncUploadDialog();
  }
}

class _SyncUploadDialog extends State<SyncUploadDialog> {
  final Map<String, bool?> _relaySelected = {};

  int sendInterval = 10;

  @override
  Widget build(BuildContext context) {
    final localization = S.of(context);
    final themeData = Theme.of(context);
    var mainColor = themeData.primaryColor;
    var titleFontSize = themeData.textTheme.bodyLarge!.fontSize;
    Color cardColor = themeData.cardColor;

    var relayProvider = Provider.of<RelayProvider>(context);

    List<Widget> list = [];
    list.add(Text(
      localization.Sync_Upload,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: titleFontSize,
      ),
    ));

    list.add(Container(
      margin: const EdgeInsets.only(top: Base.basePadding),
      child: Row(
        children: [
          Text("${localization.Upload_num}: ${widget.events.length}"),
          Container(
            margin: const EdgeInsets.only(
              left: Base.basePadding,
              right: Base.basePaddingHalf,
            ),
            child: Text("${localization.Send_interval}: "),
          ),
          DropdownButton<int>(
            isDense: true,
            value: sendInterval,
            items: const [
              DropdownMenuItem<int>(
                value: 0,
                child: Text("0ms"),
              ),
              DropdownMenuItem<int>(
                value: 10,
                child: Text("10ms"),
              ),
              DropdownMenuItem<int>(
                value: 100,
                child: Text("100ms"),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  sendInterval = value;
                });
              }
            },
          ),
        ],
      ),
    ));

    List<Widget> subList = [];
    List<String> addrs = [RelayLocal.localUrl, ...relayProvider.relayAddrs]
      
      ;
    for (var relayAddr in addrs) {
      var relayStatus = relayProvider.relayStatusMap[relayAddr];
      if (relayStatus == null) {
        if (relayAddr == RelayLocal.localUrl) {
          subList.add(SyncUploadItem(
              relayAddr, _relaySelected[relayAddr] == true, onItemTap));
        }
        continue;
      }

      subList.add(SyncUploadItem(
          relayAddr, _relaySelected[relayAddr] == true, onItemTap));
    }
    list.add(Container(
      margin: const EdgeInsets.only(top: Base.basePadding),
      child: Text(localization.Select_relay_to_upload),
    ));
    list.add(Container(
      margin: const EdgeInsets.only(top: Base.basePaddingHalf),
      child: Wrap(
        spacing: Base.basePaddingHalf,
        runSpacing: Base.basePaddingHalf,
        children: subList,
      ),
    ));

    list.add(Container(
      margin: const EdgeInsets.only(
        top: Base.basePadding * 2,
      ),
      child: Ink(
        decoration: BoxDecoration(color: mainColor),
        child: InkWell(
          onTap: () {
            beginToUpload();
          },
          highlightColor: mainColor.withOpacity(0.2),
          child: Container(
            color: mainColor,
            height: 40,
            alignment: Alignment.center,
            child: Text(
              S.of(context).Confirm,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    ));

    var main = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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

  onItemTap(String addr, bool value) {
    setState(() {
      _relaySelected[addr] = value;
    });
  }

  Future<void> beginToUpload() async {
    RouterUtil.back(context);

    var cancelFunc = BotToast.showLoading();
    try {
      List<Relay> selectedRelays = [];
      for (var entry in _relaySelected.entries) {
        if (entry.value == true) {
          var relay = nostr!.getRelay(entry.key);
          if (relay != null) {
            selectedRelays.add(relay);
          }
        }
      }

      if (selectedRelays.isEmpty) {
        BotToast.showText(text: S.of(context).Please_select_relays);
        return;
      }

      log("begin to broadcastAll");
      // var index = 0;
      for (var event in widget.events) {
        var message = ["EVENT", event.toJson()];

        // find the relays not contain this event and send (broadcast) to it.
        int count = 0;
        for (var relay in selectedRelays) {
          if (!event.sources.contains(relay.url)) {
            try {
              count++;
              relay.send(message);
            } catch (_) {}
          }
        }
        // log("note ${index} send to ${count} relays");

        // nostr!.broadcast(event);
        if (count > 0) {
          await Future.delayed(Duration(milliseconds: sendInterval));
        }
        // index++;
      }
      log("broadcastAll complete");
    } finally {
      cancelFunc.call();
    }
  }
}

class SyncUploadItem extends StatefulWidget {
  final String addr;

  final bool check;

  final Function(String, bool) onTap;

  const SyncUploadItem(this.addr, this.check, this.onTap, {super.key});

  @override
  State<StatefulWidget> createState() {
    return _SyncUploadItem();
  }
}

class _SyncUploadItem extends State<SyncUploadItem> {
  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    var hintColor = themeData.hintColor;
    var mainColor = themeData.primaryColor;

    return GestureDetector(
      onTap: () {
        widget.onTap(widget.addr, !widget.check);
      },
      child: Container(
        padding: const EdgeInsets.only(
          left: Base.basePadding,
          right: Base.basePadding,
          top: Base.basePaddingHalf,
          bottom: Base.basePaddingHalf,
        ),
        decoration: BoxDecoration(
          color: widget.check ? mainColor.withOpacity(0.2) : null,
          border: Border.all(
            width: 1,
            color: hintColor.withOpacity(0.5),
          ),
          borderRadius: BorderRadius.circular(Base.basePaddingHalf),
        ),
        child: Text(widget.addr),
      ),
    );
  }
}
