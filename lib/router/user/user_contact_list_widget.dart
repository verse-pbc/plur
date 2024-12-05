import 'package:flutter/material.dart';
import 'package:nostr_sdk/nip02/contact_list.dart';

import '../../component/appbar_back_btn_widget.dart';
import '../../generated/l10n.dart';
import '../../util/router_util.dart';
import 'contact_list_widget.dart';

class UserContactListWidget extends StatefulWidget {
  const UserContactListWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return _UserContactListWidgetState();
  }
}

class _UserContactListWidgetState extends State<UserContactListWidget> {
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
      ),
      body: ContactListWidget(contactList: contactList!),
    );
  }
}
