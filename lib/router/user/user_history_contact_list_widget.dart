import 'package:flutter/material.dart';
import 'package:nostrmo/nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/main.dart';

import '../../component/appbar_back_btn_widget.dart';
import '../../generated/l10n.dart';
import '../../util/router_util.dart';
import 'contact_list_widget.dart';

class UserHistoryContactListWidget extends StatefulWidget {
  const UserHistoryContactListWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return _UserHistoryContactListWidgetState();
  }
}

class _UserHistoryContactListWidgetState extends State<UserHistoryContactListWidget> {
  ContactList? contactList;

  @override
  Widget build(BuildContext context) {
    final localization = S.of(context);

    if (contactList == null) {
      var arg = RouterUtil.routerArgs(context);
      if (arg != null) {
        contactList = arg as ContactList;
      }
    }
    if (contactList == null) {
      RouterUtil.back(context);
      return Container();
    }
    final themeData = Theme.of(context);
    var titleFontSize = themeData.textTheme.bodyLarge!.fontSize;
    var titleTextColor = themeData.appBarTheme.titleTextStyle!.color;

    return Scaffold(
      appBar: AppBar(
        leading: const AppbarBackBtnWidget(),
        title: Text(
          localization.Following,
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: doRecovery,
            style: const ButtonStyle(),
            child: Text(
              localization.Recovery,
              style: TextStyle(
                color: titleTextColor,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: ContactListWidget(contactList: contactList!),
    );
  }

  void doRecovery() {
    contactListProvider.updateContacts(contactList!);
    RouterUtil.back(context);
  }
}
