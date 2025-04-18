import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/main.dart';
import 'dart:developer';

import '../../component/appbar4stack.dart';
import '../../generated/l10n.dart';

class KeyBackupWidget extends StatefulWidget {
  const KeyBackupWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return _KeyBackupWidgetState();
  }
}

class _KeyBackupWidgetState extends State<KeyBackupWidget> {
  bool check0 = false;
  bool check1 = false;
  bool check2 = false;

  List<CheckboxItem>? checkboxItems;

  void initCheckBoxItems(BuildContext context) {
    if (checkboxItems == null) {
      final localization = S.of(context);
      checkboxItems = [];
      checkboxItems!.add(CheckboxItem(
          localization.Please_do_not_disclose_or_share_the_key_to_anyone, false));
      checkboxItems!.add(CheckboxItem(
          localization.Nostromo_developers_will_never_require_a_key_from_you, false));
      checkboxItems!.add(CheckboxItem(
          localization.Please_keep_the_key_properly_for_account_recovery, false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = S.of(context);
    final themeData = Theme.of(context);
    var cardColor = themeData.cardColor;
    var mainColor = themeData.primaryColor;

    initCheckBoxItems(context);

    Color? appbarBackgroundColor = Colors.transparent;
    var appBar = Appbar4Stack(
      backgroundColor: appbarBackgroundColor,
      // title: appbarTitle,
    );

    List<Widget> list = [];
    list.add(Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Text(
        localization.Backup_and_Safety_tips,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
    ));

    list.add(Container(
      margin: const EdgeInsets.only(bottom: Base.basePaddingHalf),
      child: Text(
        localization.The_key_is_a_random_string_that_resembles_,
      ),
    ));

    for (var item in checkboxItems!) {
      list.add(checkboxView(item));
    }

    list.add(Container(
      margin: const EdgeInsets.all(Base.basePadding),
      child: InkWell(
        onTap: copyKey,
        child: Container(
          height: 36,
          color: mainColor,
          alignment: Alignment.center,
          child: Text(
            localization.Copy_Key,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    ));

    list.add(GestureDetector(
      onTap: copyHexKey,
      child: Text(
        localization.Copy_Hex_Key,
        style: TextStyle(
          color: mainColor,
          decoration: TextDecoration.underline,
        ),
      ),
    ));

    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: mediaDataCache.size.width,
            height: mediaDataCache.size.height - mediaDataCache.padding.top,
            margin: EdgeInsets.only(top: mediaDataCache.padding.top),
            child: Container(
              color: cardColor,
              child: Center(
                child: SizedBox(
                  width: mediaDataCache.size.width * 0.8,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: list,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: mediaDataCache.padding.top,
            child: SizedBox(
              width: mediaDataCache.size.width,
              child: appBar,
            ),
          ),
        ],
      ),
    );
  }

  Widget checkboxView(CheckboxItem item) {
    return InkWell(
      child: Row(
        children: <Widget>[
          Checkbox(
            value: item.value,
            activeColor: Colors.blue,
            onChanged: (bool? val) {
              if (val != null) {
                setState(() {
                  item.value = val;
                });
              }
            },
          ),
          Expanded(
            child: Text(
              item.name,
              maxLines: 3,
            ),
          ),
        ],
      ),
      onTap: () {
        log(item.name);
        setState(() {
          item.value = !item.value;
        });
      },
    );
  }

  bool checkTips() {
    for (var item in checkboxItems!) {
      if (!item.value) {
        BotToast.showText(text: S.of(context).Please_check_the_tips);
        return false;
      }
    }

    return true;
  }

  void copyHexKey() {
    if (!checkTips()) {
      return;
    }

    doCopy(settingsProvider.privateKey);
  }

  void copyKey() {
    if (!checkTips()) {
      return;
    }

    if (nostr!.nostrSigner is LocalNostrSigner) {
      var pk = settingsProvider.privateKey;
      var nip19Key = Nip19.encodePrivateKey(pk!);
      doCopy(nip19Key);
    }
  }

  void doCopy(String? key) {
    if (StringUtil.isBlank(key)) {
      return;
    }

    final localization = S.of(context);
    Clipboard.setData(ClipboardData(text: key!)).then((_) {
      BotToast.showText(text: localization.key_has_been_copy);
    });
  }
}

class CheckboxItem {
  String name;

  bool value;

  CheckboxItem(this.name, this.value);
}
