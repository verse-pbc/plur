import 'dart:convert';
import 'dart:developer';

import 'package:bot_toast/bot_toast.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/component/confirm_dialog.dart';
import 'package:nostrmo/component/cust_state.dart';
import 'package:nostrmo/component/sync_upload_dialog.dart';
import 'package:nostrmo/component/user/user_pic_widget.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostrmo/data/user.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/provider/user_provider.dart';
import 'package:nostrmo/util/store_util.dart';
import 'package:provider/provider.dart';

import '../../component/appbar_back_btn_widget.dart';
import '../../component/webview_widget.dart';
import '../../generated/l10n.dart';
import '../../util/router_util.dart';

class RelayInfoWidget extends StatefulWidget {
  const RelayInfoWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return _RelayInfoWidgetState();
  }
}

class _RelayInfoWidgetState extends CustState<RelayInfoWidget> {
  bool isMyRelay = false;

  double imageWidth = 45;

  int? dataLength;

  int? dbFileSize;

  @override
  Widget doBuild(BuildContext context) {
    final themeData = Theme.of(context);
    var titleFontSize = themeData.textTheme.bodyLarge!.fontSize;
    final localization = S.of(context);

    var relayItf = RouterUtil.routerArgs(context);
    if (relayItf == null || relayItf is! Relay) {
      RouterUtil.back(context);
      return Container();
    }

    var relay = relayItf;
    var relayInfo = relay.info!;
    if (nostr!.getRelay(relay.relayStatus.addr) != null) {
      isMyRelay = true;
    }

    List<Widget> list = [];

    list.add(Container(
      margin: const EdgeInsets.only(
        top: Base.basePadding,
        bottom: Base.basePadding,
      ),
      child: Text(
        relayInfo.name,
        style: TextStyle(
          fontSize: titleFontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    ));

    list.add(Container(
      margin: const EdgeInsets.only(
        bottom: Base.basePadding,
      ),
      padding: const EdgeInsets.only(
        left: Base.basePadding,
        right: Base.basePadding,
      ),
      child: Text(relayInfo.description),
    ));

    list.add(RelayInfoItemWidget(
      title: localization.url,
      child: SelectableText(relay.url),
    ));

    list.add(RelayInfoItemWidget(
      title: localization.owner,
      child: Selector<UserProvider, User?>(
        builder: (context, user, child) {
          List<Widget> list = [];

          list.add(Container(
            alignment: Alignment.center,
            child: UserPicWidget(
              pubkey: relayInfo.pubkey,
              width: imageWidth,
              user: user,
            ),
          ));

          return GestureDetector(
            onTap: () {
              RouterUtil.router(context, RouterPath.user, relayInfo.pubkey);
            },
            child: Row(
              children: list,
            ),
          );
        },
        selector: (_, provider) {
          return provider.getUser(relayInfo.pubkey);
        },
      ),
    ));

    list.add(RelayInfoItemWidget(
      title: localization.contact,
      child: SelectableText(relayInfo.contact),
    ));

    list.add(RelayInfoItemWidget(
      title: localization.soft,
      child: SelectableText(relayInfo.software),
    ));

    list.add(RelayInfoItemWidget(
      title: localization.version,
      child: SelectableText(relayInfo.version),
    ));

    List<Widget> nipWidgets = [];
    for (var nip in relayInfo.nips) {
      nipWidgets.add(NipWidget(nip: nip));
    }
    list.add(RelayInfoItemWidget(
      title: "NIPs",
      child: Wrap(
        spacing: Base.basePadding,
        runSpacing: Base.basePadding,
        children: nipWidgets,
      ),
    ));

    if (relay is! RelayLocal && isMyRelay) {
      list.add(CheckboxListTile(
        title: Text(localization.write),
        value: relay.relayStatus.writeAccess,
        onChanged: (bool? value) {
          if (value != null) {
            relay.relayStatus.writeAccess = value;
            setState(() {});
            relayProvider.saveRelay();
          }
        },
      ));

      list.add(CheckboxListTile(
        title: Text(localization.read),
        value: relay.relayStatus.readAccess,
        onChanged: (bool? value) {
          if (value != null) {
            relay.relayStatus.readAccess = value;
            setState(() {});
            relayProvider.saveRelay();
          }
        },
      ));
    }

    if (relay is RelayLocal) {
      if (dataLength != null) {
        list.add(ListTile(
          title: Text(localization.dataLength),
          trailing: Text(dataLength!.toString()),
        ));
      }

      if (dbFileSize != null) {
        list.add(ListTile(
          title: Text(localization.fileSize),
          trailing: Text(StoreUtil.bytesToShowStr(dbFileSize!)),
        ));
      }

      list.add(GestureDetector(
        onTap: clearAllData,
        child: ListTile(
          title: Text(localization.clearAllData),
          mouseCursor: SystemMouseCursors.click,
        ),
      ));

      list.add(GestureDetector(
        onTap: clearNotMyData,
        child: ListTile(
          title: Text(localization.clearNotMyData),
          mouseCursor: SystemMouseCursors.click,
        ),
      ));

      list.add(CheckboxListTile(
        title: Text(localization.dataSyncMode),
        value: dataSyncMode,
        onChanged: (bool? value) {
          if (value != null) {
            dataSyncMode = value;
            setState(() {});
          }
        },
      ));

      list.add(GestureDetector(
        onTap: backMyNotes,
        child: ListTile(
          title: Text(localization.backupMyNotes),
          mouseCursor: SystemMouseCursors.click,
        ),
      ));

      list.add(GestureDetector(
        onTap: importNotes,
        child: ListTile(
          title: Text(localization.importNotes),
          mouseCursor: SystemMouseCursors.click,
        ),
      ));
    }

    return Scaffold(
      appBar: AppBar(
        leading: const AppbarBackBtnWidget(),
        title: Text(
          localization.relayInfo,
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: SizedBox(
          width: double.maxFinite,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: list,
          ),
        ),
      ),
    );
  }

  void backMyNotes() async {
    final localization = S.of(context);
    var eventDatas = await relayLocalDB!.queryEventByPubkey(nostr!.publicKey);
    var jsonStr = jsonEncode(eventDatas);
    var result = await FileSaver.instance.saveFile(
      name: DateTime.now().millisecondsSinceEpoch.toString(),
      bytes: utf8.encode(jsonStr),
      ext: ".json",
    );

    BotToast.showText(text: "${localization.fileSaveSuccess}: $result");
  }

  Future<void> importNotes() async {
    var result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      allowedExtensions: ["json"],
      withData: true,
    );
    if (result != null) {
      List<Event> events = [];

      var platformFile = result.files.first;
      var jsonObj = jsonDecode(utf8.decode(platformFile.bytes!));
      if (jsonObj is List) {
        for (var eventJson in jsonObj) {
          try {
            var event = Event.fromJson(eventJson);
            events.add(event);
          } catch (e) {
            log("importNotes error $e");
          }
        }
      }

      if (!mounted) return;
      SyncUploadDialog.show(context, events);
    }
  }

  @override
  Future<void> onReady(BuildContext context) async {
    if (isMyRelay) {
      updateMyRelayData();
    }
  }

  Future<void> updateMyRelayData() async {
    dataLength = await relayLocalDB!.allDataCount();
    dbFileSize = await RelayLocalDB.getDBFileSize();
    setState(() {});
  }

  Future<void> clearAllData() async {
    await doClearData();
  }

  Future<void> clearNotMyData() async {
    await doClearData(pubkey: nostr!.publicKey);
  }

  Future<void> doClearData({String? pubkey}) async {
    var result = await ConfirmDialog.show(
        context, S.of(context).thisOperationCannotBeUndo);
    if (result != true) {
      return;
    }

    var cancelFunc = BotToast.showLoading();
    try {
      dataLength = null;
      dbFileSize = null;
      await relayLocalDB!.deleteData(pubkey: pubkey);
    } finally {
      updateMyRelayData();
      cancelFunc.call();
    }
  }
}

class RelayInfoItemWidget extends StatelessWidget {
  final String title;

  final Widget child;

  const RelayInfoItemWidget({super.key,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> list = [];

    list.add(Text(
      "$title :",
      style: const TextStyle(
        fontWeight: FontWeight.bold,
      ),
    ));

    list.add(Container(
      padding: const EdgeInsets.only(
        left: Base.basePadding,
        right: Base.basePadding,
      ),
      child: child,
    ));

    return Container(
      padding: const EdgeInsets.only(
        left: Base.basePadding,
        right: Base.basePadding,
      ),
      margin: const EdgeInsets.only(
        bottom: Base.basePadding,
      ),
      width: double.maxFinite,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: list,
      ),
    );
  }
}

class NipWidget extends StatelessWidget {
  final dynamic nip;

  const NipWidget({super.key, required this.nip});

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    var mainColor = themeData.primaryColor;

    var nipStr = nip.toString();
    if (nipStr == "1") {
      nipStr = "01";
    } else if (nipStr == "2") {
      nipStr = "02";
    } else if (nipStr == "3") {
      nipStr = "03";
    } else if (nipStr == "4") {
      nipStr = "04";
    } else if (nipStr == "5") {
      nipStr = "05";
    } else if (nipStr == "6") {
      nipStr = "06";
    } else if (nipStr == "7") {
      nipStr = "07";
    } else if (nipStr == "8") {
      nipStr = "08";
    } else if (nipStr == "9") {
      nipStr = "09";
    }

    return GestureDetector(
      onTap: () {
        var url =
            "https://github.com/nostr-protocol/nips/blob/master/$nipStr.md";
        WebViewWidget.open(context, url);
      },
      child: Text(
        nipStr,
        style: TextStyle(
          color: mainColor,
          decoration: TextDecoration.underline,
          decorationColor: mainColor,
        ),
      ),
    );
  }
}
