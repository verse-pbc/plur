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
import 'package:nostrmo/data/metadata.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/provider/metadata_provider.dart';
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

  double IMAGE_WIDTH = 45;

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
        top: Base.BASE_PADDING,
        bottom: Base.BASE_PADDING,
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
        bottom: Base.BASE_PADDING,
      ),
      padding: const EdgeInsets.only(
        left: Base.BASE_PADDING,
        right: Base.BASE_PADDING,
      ),
      child: Text(relayInfo.description),
    ));

    list.add(RelayInfoItemWidget(
      title: localization.Url,
      child: SelectableText(relay.url),
    ));

    list.add(RelayInfoItemWidget(
      title: localization.Owner,
      child: Selector<MetadataProvider, Metadata?>(
        builder: (context, metadata, child) {
          List<Widget> list = [];

          list.add(Container(
            alignment: Alignment.center,
            child: UserPicWidget(
              pubkey: relayInfo.pubkey,
              width: IMAGE_WIDTH,
              metadata: metadata,
            ),
          ));

          return GestureDetector(
            onTap: () {
              RouterUtil.router(context, RouterPath.USER, relayInfo.pubkey);
            },
            child: Row(
              children: list,
            ),
          );
        },
        selector: (_, provider) {
          return provider.getMetadata(relayInfo.pubkey);
        },
      ),
    ));

    list.add(RelayInfoItemWidget(
      title: localization.Contact,
      child: SelectableText(relayInfo.contact),
    ));

    list.add(RelayInfoItemWidget(
      title: localization.Soft,
      child: SelectableText(relayInfo.software),
    ));

    list.add(RelayInfoItemWidget(
      title: localization.Version,
      child: SelectableText(relayInfo.version),
    ));

    List<Widget> nipWidgets = [];
    for (var nip in relayInfo.nips) {
      nipWidgets.add(NipWidget(nip: nip));
    }
    list.add(RelayInfoItemWidget(
      title: "NIPs",
      child: Wrap(
        spacing: Base.BASE_PADDING,
        runSpacing: Base.BASE_PADDING,
        children: nipWidgets,
      ),
    ));

    if (relay is! RelayLocal && isMyRelay) {
      list.add(CheckboxListTile(
        title: Text(localization.Write),
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
        title: Text(localization.Read),
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
          title: Text(localization.Data_Length),
          trailing: Text(dataLength!.toString()),
        ));
      }

      if (dbFileSize != null) {
        list.add(ListTile(
          title: Text(localization.File_Size),
          trailing: Text(StoreUtil.bytesToShowStr(dbFileSize!)),
        ));
      }

      list.add(GestureDetector(
        onTap: clearAllData,
        child: ListTile(
          title: Text(localization.Clear_All_Data),
          mouseCursor: SystemMouseCursors.click,
        ),
      ));

      list.add(GestureDetector(
        onTap: clearNotMyData,
        child: ListTile(
          title: Text(localization.Clear_Not_My_Data),
          mouseCursor: SystemMouseCursors.click,
        ),
      ));

      list.add(CheckboxListTile(
        title: Text(localization.Data_Sync_Mode),
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
          title: Text(localization.Backup_my_notes),
          mouseCursor: SystemMouseCursors.click,
        ),
      ));

      list.add(GestureDetector(
        onTap: importNotes,
        child: ListTile(
          title: Text(localization.Import_notes),
          mouseCursor: SystemMouseCursors.click,
        ),
      ));
    }

    return Scaffold(
      appBar: AppBar(
        leading: const AppbarBackBtnWidget(),
        title: Text(
          localization.Relay_Info,
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
    var eventDatas = await relayLocalDB!.queryEventByPubkey(nostr!.publicKey);
    var jsonStr = jsonEncode(eventDatas);
    var result = await FileSaver.instance.saveFile(
      name: DateTime.now().millisecondsSinceEpoch.toString(),
      bytes: utf8.encode(jsonStr),
      ext: ".json",
    );

    BotToast.showText(text: "${S.of(context).File_save_success}: $result");
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
            log("importNotes error ${e}");
          }
        }
      }

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
        context, S.of(context).This_operation_cannot_be_undo);
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
  String title;

  Widget child;

  RelayInfoItemWidget({
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
        left: Base.BASE_PADDING,
        right: Base.BASE_PADDING,
      ),
      child: child,
    ));

    return Container(
      padding: const EdgeInsets.only(
        left: Base.BASE_PADDING,
        right: Base.BASE_PADDING,
      ),
      margin: const EdgeInsets.only(
        bottom: Base.BASE_PADDING,
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
  dynamic nip;

  NipWidget({super.key, required this.nip});

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
