import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:provider/provider.dart';

import '../../../component/keep_alive_cust_state.dart';
import '../../../component/placeholder/metadata_list_placeholder.dart';
import '../../../component/user/user_metadata_widget.dart';
import '../../../consts/base.dart';
import '../../../consts/router_path.dart';
import '../../../data/user.dart';
import '../../../main.dart';
import '../../../provider/user_provider.dart';
import '../../../util/dio_util.dart';
import '../../../util/router_util.dart';
import '../../../util/table_mode_util.dart';

class GlobalsUsersWidget extends StatefulWidget {
  const GlobalsUsersWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return _GlobalsUsersWidgetState();
  }
}

class _GlobalsUsersWidgetState extends KeepAliveCustState<GlobalsUsersWidget> {
  ScrollController scrollController = ScrollController();

  List<String> pubkeys = [];

  @override
  Widget doBuild(BuildContext context) {
    final themeData = Theme.of(context);
    if (pubkeys.isEmpty) {
      return MetadataListPlaceholder(
        onRefresh: refresh,
      );
    }

    var main = ListView.builder(
      controller: scrollController,
      itemBuilder: (context, index) {
        var pubkey = pubkeys[index];
        if (StringUtil.isBlank(pubkey)) {
          return Container();
        }

        return Container(
          color: themeData.cardColor,
          padding: const EdgeInsets.only(bottom: Base.basePadding),
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
      itemCount: pubkeys.length,
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

  @override
  Future<void> onReady(BuildContext context) async {
    indexProvider.setUserScrollController(scrollController);
    refresh();
  }

  Future<void> refresh() async {
    var str = await DioUtil.getStr(Base.indexsContacts);
    if (StringUtil.isNotBlank(str)) {
      pubkeys.clear();
      var itfs = jsonDecode(str!);
      for (var itf in itfs) {
        pubkeys.add(itf as String);
      }

      // Disorder
      for (var i = 1; i < pubkeys.length; i++) {
        var j = getRandomInt(0, i);
        var t = pubkeys[i];
        pubkeys[i] = pubkeys[j];
        pubkeys[j] = t;
      }

      setState(() {});
    }
  }

  int getRandomInt(int min, int max) {
    final random = Random();
    return random.nextInt((max - min).floor()) + min;
  }
}
