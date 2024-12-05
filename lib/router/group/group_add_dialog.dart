import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:nostr_sdk/nip29/group_identifier.dart';
import 'package:nostr_sdk/utils/string_util.dart';
import 'package:nostrmo/main.dart';

import '../../consts/base.dart';
import '../../generated/l10n.dart';
import '../../util/router_util.dart';
import '../../util/theme_util.dart';

class GroupAddDailog extends StatefulWidget {
  static Future<String?> show(BuildContext context) async {
    return await showDialog<String>(
        context: context,
        useRootNavigator: false,
        builder: (_context) {
          return GroupAddDailog();
        });
  }

  @override
  State<StatefulWidget> createState() {
    return _GroupAddDailog();
  }
}

class _GroupAddDailog extends State<GroupAddDailog> {
  TextEditingController hostController = TextEditingController();
  TextEditingController groupIdController = TextEditingController();

  late S localization;

  // bool joinGroup = true;

  // String crateGroupRelay = "wss://groups.fiatjaf.com";

  @override
  Widget build(BuildContext context) {
    localization = S.of(context);
    final themeData = Theme.of(context);
    var mainColor = themeData.primaryColor;
    var titleFontSize = themeData.textTheme.bodyLarge!.fontSize;
    Color cardColor = themeData.cardColor;
    var hintColor = themeData.hintColor;

    List<Widget> list = [];

    list.add(Text(
      "${localization.Add} ${localization.Group}",
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: titleFontSize,
      ),
    ));

    list.add(Container(
      margin: EdgeInsets.only(top: Base.BASE_PADDING),
      child: TextField(
        controller: hostController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: "${localization.Please_input} ${localization.Relay}",
          border: OutlineInputBorder(borderSide: BorderSide(width: 1)),
        ),
      ),
    ));

    list.add(Container(
      margin: EdgeInsets.only(top: Base.BASE_PADDING),
      child: TextField(
        controller: groupIdController,
        decoration: InputDecoration(
          hintText: "${localization.Please_input} ${localization.GroupId}",
          border: OutlineInputBorder(borderSide: BorderSide(width: 1)),
        ),
      ),
    ));

    list.add(Container(
      margin: EdgeInsets.only(top: Base.BASE_PADDING),
      child: Ink(
        decoration: BoxDecoration(color: mainColor),
        child: InkWell(
          onTap: _onConfirm,
          highlightColor: mainColor.withOpacity(0.2),
          child: Container(
            color: mainColor,
            height: 40,
            alignment: Alignment.center,
            child: Text(
              S.of(context).Confirm,
              style: TextStyle(
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
              left: Base.BASE_PADDING,
              right: Base.BASE_PADDING,
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

  void _onConfirm() {
    var host = hostController.text;
    var groupId = groupIdController.text;

    if (StringUtil.isBlank(host) && StringUtil.isBlank(groupId)) {
      BotToast.showText(text: localization.Input_can_not_be_null);
      return;
    }

    listProvider.addGroup(GroupIdentifier(host, groupId));
    RouterUtil.back(context);
  }
}
