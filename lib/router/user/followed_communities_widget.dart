import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostrmo/provider/contact_list_provider.dart';
import 'package:provider/provider.dart';

import '../../component/appbar_back_btn_widget.dart';
import '../../consts/base.dart';
import '../../generated/l10n.dart';
import '../../main.dart';
import '../../util/router_util.dart';

class FollowedCommunitiesWidget extends StatefulWidget {
  const FollowedCommunitiesWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return _FollowedCommunitiesWidgetState();
  }
}

class _FollowedCommunitiesWidgetState extends State<FollowedCommunitiesWidget> {
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
    var hintColor = themeData.hintColor;

    var communitiesList = contactList!.followedCommunitiesList().toList();

    var main = ListView.builder(
      itemBuilder: (context, index) {
        var id = AId.fromString(communitiesList[index]);
        if (id == null) {
          return Container();
        }

        var item = Container(
          padding: const EdgeInsets.only(
            left: Base.BASE_PADDING,
            right: Base.BASE_PADDING,
          ),
          child: Container(
              padding: const EdgeInsets.only(
                left: Base.BASE_PADDING,
                right: Base.BASE_PADDING,
                top: Base.BASE_PADDING,
                bottom: Base.BASE_PADDING,
              ),
              decoration: BoxDecoration(
                  border: Border(
                      bottom: BorderSide(
                color: hintColor,
              ))),
              child: Row(children: [
                Text(id.title),
                Expanded(child: Container()),
                Selector<ContactListProvider, bool>(
                    builder: (context, exist, child) {
                  IconData iconData = Icons.star_border;
                  Color? color;
                  if (exist) {
                    iconData = Icons.star;
                    color = Colors.yellow;
                  }
                  return GestureDetector(
                    onTap: () {
                      if (exist) {
                        contactListProvider.removeCommunity(id.toAString());
                      } else {
                        contactListProvider.addCommunity(id.toAString());
                      }
                    },
                    child: Container(
                      margin:
                          const EdgeInsets.only(left: Base.BASE_PADDING_HALF),
                      child: Icon(
                        iconData,
                        color: color,
                      ),
                    ),
                  );
                }, selector: (_, provider) {
                  return provider.containCommunity(id.toAString());
                })
              ])),
        );

        return GestureDetector(
          onTap: () {
            RouterUtil.router(context, RouterPath.COMMUNITY_DETAIL, id);
          },
          child: item,
        );
      },
      itemCount: communitiesList.length,
    );

    return Scaffold(
      appBar: AppBar(
        leading: const AppbarBackBtnWidget(),
        title: Text(
          localization.Followed_Communities,
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        child: main,
      ),
    );
  }
}
