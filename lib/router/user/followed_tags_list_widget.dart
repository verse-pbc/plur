import 'package:flutter/material.dart';
import 'package:nostrmo/nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/component/tag_info_widget.dart';
import 'package:nostrmo/consts/base.dart';

import '../../component/appbar_back_btn_widget.dart';
import '../../generated/l10n.dart';
import '../../util/router_util.dart';

class FollowedTagsListWidget extends StatefulWidget {
  const FollowedTagsListWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return _FollowedTagsListWidgetState();
  }
}

class _FollowedTagsListWidgetState extends State<FollowedTagsListWidget> {
  ContactList? contactList;

  @override
  Widget build(BuildContext context) {
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

    final localization = S.of(context);
    final themeData = Theme.of(context);
    var titleFontSize = themeData.textTheme.bodyLarge!.fontSize;

    var tagList = contactList!.tagList().toList();

    return Scaffold(
      appBar: AppBar(
        leading: const AppbarBackBtnWidget(),
        title: Text(
          localization.Followed_Tags,
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 3,
          crossAxisSpacing: Base.basePaddingHalf,
        ),
        itemBuilder: (context, index) {
          var tag = tagList[index];

          return TagInfoWidget(
            tag: tag,
            jumpable: true,
          );
        },
        itemCount: tagList.length,
      ),
    );
  }
}
