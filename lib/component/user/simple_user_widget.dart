import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/component/user/follow_btn_widget.dart';
import 'package:nostrmo/component/user/name_widget.dart';
import 'package:nostrmo/component/user/user_pic_widget.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/data/user.dart';
import 'package:nostrmo/provider/user_provider.dart';
import 'package:provider/provider.dart';

import '../image_widget.dart';

class SimpleUserWidget extends StatefulWidget {
  String pubkey;

  User? user;

  bool showFollow;

  SimpleUserWidget({
    super.key,
    required this.pubkey,
    this.user,
    this.showFollow = false,
  });

  @override
  State<StatefulWidget> createState() {
    return _SimpleUserWidgetState();
  }
}

class _SimpleUserWidgetState extends State<SimpleUserWidget> {
  static const double IMAGE_WIDTH = 50;

  static const double HEIGHT = 64;

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    if (widget.user != null) {
      return buildWidget(themeData, widget.user!);
    }

    return Selector<UserProvider, User?>(
        builder: (context, user, child) {
      if (user == null) {
        return Container(
          height: HEIGHT,
          color: themeData.hintColor,
        );
      }

      return buildWidget(themeData, user);
    }, selector: (context, provider) {
      return provider.getUser(widget.pubkey);
    });
  }

  Widget buildWidget(ThemeData themeData, User user) {
    var cardColor = themeData.cardColor;

    Widget? bannerImage;
    if (StringUtil.isNotBlank(user.banner)) {
      bannerImage = ImageWidget(
        imageUrl: user.banner!,
        width: double.maxFinite,
        height: HEIGHT,
        fit: BoxFit.fitWidth,
      );
    } else {
      bannerImage = Container();
    }

    Widget userImageWidget = Container(
      margin: const EdgeInsets.only(
        right: Base.basePadding,
      ),
      child: UserPicWidget(
        pubkey: widget.pubkey,
        width: IMAGE_WIDTH,
        user: user,
      ),
    );

    List<Widget> list = [
      bannerImage,
      Container(
        height: HEIGHT,
        color: cardColor.withOpacity(0.4),
      ),
      Container(
        padding: const EdgeInsets.only(left: Base.basePadding),
        child: Row(
          children: [
            userImageWidget,
            NameWidget(
              pubkey: user.pubkey!,
              user: user,
            ),
          ],
        ),
      ),
    ];

    if (widget.showFollow) {
      list.add(Positioned(
        right: Base.basePadding,
        child: FollowBtnWidget(
          pubkey: widget.pubkey,
          followedBorderColor: themeData.primaryColor,
        ),
      ));
    }

    return SizedBox(
      height: HEIGHT,
      child: Stack(
        alignment: Alignment.center,
        children: list,
      ),
    );
  }
}
