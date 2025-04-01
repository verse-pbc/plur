import 'package:flutter/material.dart';
import 'package:nostrmo/component/user/simple_name_widget.dart';
import 'package:provider/provider.dart';

import '../../consts/base.dart';
import '../../data/user.dart';
import '../../provider/user_provider.dart';
import '../user/user_pic_widget.dart';

class ZapBottomSheetUserWidget extends StatefulWidget {
  String pubkey;

  bool configMaxWidth;

  ZapBottomSheetUserWidget(
    this.pubkey, {
      super.key,
    this.configMaxWidth = false,
  });

  @override
  State<StatefulWidget> createState() {
    return _ZapBottomSheetUserWidgetState();
  }
}

class _ZapBottomSheetUserWidgetState extends State<ZapBottomSheetUserWidget> {
  static const double IMAGE_BORDER = 3;

  static const double IMAGE_WIDTH = 60;

  static const double HALF_IMAGE_WIDTH = 30;

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    var scaffoldBackgroundColor = themeData.scaffoldBackgroundColor;

    return Selector<UserProvider, User?>(
      builder: (context, user, child) {
        Widget userNameWidget = Container(
          width: widget.configMaxWidth ? 100 : null,
          margin: const EdgeInsets.only(
            left: Base.basePadding,
            right: Base.basePadding,
            bottom: Base.basePaddingHalf,
          ),
          alignment: Alignment.center,
          child: SimpleNameWidget(
            pubkey: widget.pubkey,
            user: user,
            maxLines: 1,
            textOverflow: TextOverflow.ellipsis,
          ),
        );

        Widget userImageWidget = Container(
          height: IMAGE_WIDTH + IMAGE_BORDER * 2,
          width: IMAGE_WIDTH + IMAGE_BORDER * 2,
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(HALF_IMAGE_WIDTH + IMAGE_BORDER),
            border: Border.all(
              width: IMAGE_BORDER,
              color: scaffoldBackgroundColor,
            ),
          ),
          child: UserPicWidget(
            pubkey: widget.pubkey,
            width: IMAGE_WIDTH,
            user: user,
          ),
        );

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            userImageWidget,
            Container(
              child: userNameWidget,
            ),
          ],
        );
      },
      selector: (_, provider) {
        return provider.getUser(widget.pubkey);
      },
    );
  }
}
