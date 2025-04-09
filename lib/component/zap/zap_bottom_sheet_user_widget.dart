import 'package:flutter/material.dart';
import 'package:nostrmo/component/user/simple_name_widget.dart';
import 'package:provider/provider.dart';

import '../../consts/base.dart';
import '../../data/user.dart';
import '../../provider/user_provider.dart';
import '../user/user_pic_widget.dart';

class ZapBottomSheetUserWidget extends StatefulWidget {
  final String pubkey;

  final bool configMaxWidth;

  const ZapBottomSheetUserWidget(
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
  static const double imageBorder = 3;

  static const double imageWidth = 60;

  static const double halfImageWidth = 30;

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
          height: imageWidth + imageBorder * 2,
          width: imageWidth + imageBorder * 2,
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(halfImageWidth + imageBorder),
            border: Border.all(
              width: imageBorder,
              color: scaffoldBackgroundColor,
            ),
          ),
          child: UserPicWidget(
            pubkey: widget.pubkey,
            width: imageWidth,
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
