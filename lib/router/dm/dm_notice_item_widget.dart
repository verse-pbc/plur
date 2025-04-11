import 'package:flutter/material.dart';
import 'package:get_time_ago/get_time_ago.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/provider/notice_provider.dart';

import '../../component/point_widget.dart';
import '../../consts/base.dart';
import '../../consts/router_path.dart';
import '../../util/router_util.dart';

class DMNoticeItemWidget extends StatelessWidget {
  static const double imageWidth = 34;

  final NoticeData newestNotice;

  final bool hasNewMessage;

  const DMNoticeItemWidget({
    super.key, 
    required this.newestNotice,
    this.hasNewMessage = false,
  });

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    var mainColor = themeData.primaryColor;
    var hintColor = themeData.hintColor;
    var smallTextSize = themeData.textTheme.bodySmall!.fontSize;

    var content = newestNotice.content;
    content = content.replaceAll("\r", " ");
    content = content.replaceAll("\n", " ");

    var leftWidget = Container(
      margin: const EdgeInsets.only(top: 4),
      child: Container(
        width: imageWidth,
        height: imageWidth,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(imageWidth / 2),
          color: hintColor,
        ),
        child: Image.asset(
          "assets/imgs/logo/logo512.png",
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.notifications,
              size: imageWidth * 0.7,
              color: Colors.white,
            );
          },
        ),
      ),
    );

    List<Widget> contentList = [
      Expanded(
        child: Text(
          StringUtil.breakWord(content),
          style: TextStyle(
            fontSize: smallTextSize,
            color: themeData.hintColor,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      )
    ];
    if (hasNewMessage) {
      contentList.add(PointWidget(color: mainColor));
    }

    var main = Container(
      padding: const EdgeInsets.all(Base.basePadding),
      decoration: BoxDecoration(
        border: Border(
            bottom: BorderSide(
          width: 1,
          color: hintColor,
        )),
        color: themeData.cardColor,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          leftWidget,
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(
                left: Base.basePadding,
                right: Base.basePadding,
                top: 4,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          newestNotice.url,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        alignment: Alignment.centerRight,
                        child: Text(
                          GetTimeAgo.parse(DateTime.fromMillisecondsSinceEpoch(
                              newestNotice.dateTime.millisecondsSinceEpoch)),
                          style: TextStyle(
                            fontSize: smallTextSize,
                            color: themeData.hintColor,
                          ),
                        ),
                      )
                    ],
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    child: Row(children: contentList),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    return GestureDetector(
      onTap: () {
        noticeProvider.setRead();
        RouterUtil.router(context, RouterPath.notices);
      },
      child: main,
    );
  }
}
