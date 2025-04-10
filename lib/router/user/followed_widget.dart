import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:provider/provider.dart';

import '../../component/appbar_back_btn_widget.dart';
import '../../component/user/user_metadata_widget.dart';
import '../../consts/base.dart';
import '../../consts/router_path.dart';
import '../../data/user.dart';
import '../../generated/l10n.dart';
import '../../provider/user_provider.dart';
import '../../util/router_util.dart';

import '../../util/table_mode_util.dart';

class FollowedWidget extends StatefulWidget {
  const FollowedWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return _FollowedWidgetState();
  }
}

class _FollowedWidgetState extends State<FollowedWidget> {
  ScrollController scrollController = ScrollController();

  List<String>? pubkeys;

  @override
  Widget build(BuildContext context) {
    final localization = S.of(context);

    if (pubkeys == null) {
      var arg = RouterUtil.routerArgs(context);
      if (arg != null) {
        pubkeys = arg as List<String>;
      }
    }
    if (pubkeys == null) {
      RouterUtil.back(context);
      return Container();
    }
    final themeData = Theme.of(context);
    var titleFontSize = themeData.textTheme.bodyLarge!.fontSize;

    var listView = ListView.builder(
      controller: scrollController,
      itemBuilder: (context, index) {
        var pubkey = pubkeys![index];
        if (StringUtil.isBlank(pubkey)) {
          return Container();
        }

        return Container(
          margin: const EdgeInsets.only(bottom: Base.basePaddingHalf),
          child: Selector<UserProvider, User?>(
            builder: (context, user, child) {
              return GestureDetector(
                onTap: () {
                  RouterUtil.router(context, RouterPath.user, pubkey);
                },
                behavior: HitTestBehavior.translucent,
                child: UserMetadataWidget(
                  pubkey: pubkey,
                  user: user,
                  jumpable: true,
                ),
              );
            },
            selector: (_, provider) {
              return provider.getUser(pubkey);
            },
          ),
        );
      },
      itemCount: pubkeys!.length,
    );

    var main = Scaffold(
      appBar: AppBar(
        leading: const AppbarBackBtnWidget(),
        title: Text(
          localization.Followed,
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: listView,
    );

    if (TableModeUtil.isTableMode()) {
      return GestureDetector(
        onVerticalDragUpdate: (detail) {
          scrollController.jumpTo(scrollController.offset - detail.delta.dy);
        },
        behavior: HitTestBehavior.translucent,
        child: main,
      );
    }

    return main;
  }
}
