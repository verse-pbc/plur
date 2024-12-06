import 'package:flutter/material.dart';
import 'package:nostr_sdk/event.dart';
import 'package:provider/provider.dart';

import '../../component/appbar_back_btn_widget.dart';
import '../../component/event/zap_event_list_widget.dart';
import '../../component/user/metadata_widget.dart';
import '../../consts/base.dart';
import '../../consts/router_path.dart';
import '../../data/metadata.dart';
import '../../generated/l10n.dart';
import '../../provider/metadata_provider.dart';
import '../../util/router_util.dart';

class UserZapListWidget extends StatefulWidget {
  const UserZapListWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return _UserZapListWidgetState();
  }
}

class _UserZapListWidgetState extends State<UserZapListWidget> {
  List<Event>? zapList;

  @override
  Widget build(BuildContext context) {
    if (zapList == null) {
      var arg = RouterUtil.routerArgs(context);
      if (arg != null) {
        zapList = arg as List<Event>;
      }
    }
    if (zapList == null) {
      RouterUtil.back(context);
      return Container();
    }

    final themeData = Theme.of(context);
    var titleFontSize = themeData.textTheme.bodyLarge!.fontSize;

    return Scaffold(
      appBar: AppBar(
        leading: const AppbarBackBtnWidget(),
        title: Text(
          "⚡Zaps⚡",
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView.builder(
        itemBuilder: (context, index) {
          var zapEvent = zapList![index];
          return ZapEventListWidget(event: zapEvent);
        },
        itemCount: zapList!.length,
      ),
    );
  }
}
