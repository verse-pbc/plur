import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:nostrmo/nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/main.dart';

import '../../consts/base.dart';
import '../../generated/l10n.dart';
import '../../provider/relay_provider.dart';
import '../../util/router_util.dart';
import '../../util/theme_util.dart';
import '../../data/join_group_parameters.dart';

class GroupAddDialog extends StatefulWidget {
  const GroupAddDialog({super.key});

  static Future<String?> show(BuildContext context) async {
    return await showDialog<String>(
        context: context,
        useRootNavigator: false,
        builder: (_) {
          return const GroupAddDialog();
        });
  }

  @override
  State<StatefulWidget> createState() {
    return _GroupAddDialog();
  }
}

class _GroupAddDialog extends State<GroupAddDialog> {
  TextEditingController hostController =
      TextEditingController(text: RelayProvider.defaultGroupsRelayAddress);
  TextEditingController groupIdController = TextEditingController();

  late S localization;

  @override
  Widget build(BuildContext context) {
    localization = S.of(context);
    final themeData = Theme.of(context);
    var mainColor = themeData.primaryColor;
    var titleFontSize = themeData.textTheme.bodyLarge!.fontSize;
    Color cardColor = themeData.cardColor;

    List<Widget> list = [];

    list.add(Text(
      "${localization.Add} ${localization.Group}",
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: titleFontSize,
      ),
    ));

    list.add(Container(
      margin: const EdgeInsets.only(top: Base.BASE_PADDING),
      child: TextField(
        controller: hostController,
        decoration: InputDecoration(
          hintText: "${localization.Please_input} ${localization.Relay}",
          border: const OutlineInputBorder(borderSide: BorderSide(width: 1)),
        ),
      ),
    ));

    list.add(Container(
      margin: const EdgeInsets.only(top: Base.BASE_PADDING),
      child: TextField(
        controller: groupIdController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: "${localization.Please_input} ${localization.GroupId}",
          border: const OutlineInputBorder(borderSide: BorderSide(width: 1)),
        ),
      ),
    ));

    list.add(Container(
      margin: const EdgeInsets.only(top: Base.BASE_PADDING),
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
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    ));

    return Scaffold(
      backgroundColor: ThemeUtil.getDialogCoverColor(themeData),
      body: FocusScope(
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
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: list,
                ),
              ),
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

    listProvider.joinGroup(JoinGroupParameters(host, groupId),
        context: context);
    RouterUtil.back(context);
  }
}
