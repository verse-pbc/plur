import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get_time_ago/get_time_ago.dart';
import 'package:nostrmo/nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/component/user/name_widget.dart';
import 'package:nostrmo/component/point_widget.dart';
import 'package:nostrmo/component/user/user_pic_widget.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostrmo/data/metadata.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/provider/dm_provider.dart';
import 'package:nostrmo/provider/metadata_provider.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:provider/provider.dart';
import 'package:pointycastle/export.dart' as pointycastle;

import 'dm_plaintext_handle.dart';

class DMSessionListItemWidget extends StatefulWidget {
  DMSessionDetail detail;

  DMSessionListItemWidget({
    super.key,
    required this.detail,
  });

  @override
  State<StatefulWidget> createState() {
    return _DMSessionListItemWidgetState();
  }
}

class _DMSessionListItemWidgetState extends State<DMSessionListItemWidget>
    with DMPlaintextHandle {
  static const double IMAGE_WIDTH = 34;

  static const double HALF_IMAGE_WIDTH = 17;

  @override
  Widget build(BuildContext context) {
    var main = Selector<MetadataProvider, Metadata?>(
      builder: (context, metadata, child) {
        final themeData = Theme.of(context);
        var mainColor = themeData.primaryColor;
        var hintColor = themeData.hintColor;
        var smallTextSize = themeData.textTheme.bodySmall!.fontSize;

        var dmSession = widget.detail.dmSession;

        var content = dmSession.newestEvent!.content;
        if (dmSession.newestEvent!.kind == EventKind.DIRECT_MESSAGE &&
            StringUtil.isBlank(plainContent)) {
          handleEncryptedText(dmSession.newestEvent!, dmSession.pubkey);
        }
        if (StringUtil.isNotBlank(plainContent)) {
          content = plainContent!;
        }
        content = content.replaceAll("\r", " ");
        content = content.replaceAll("\n", " ");

        var leftWidget = Container(
          margin: EdgeInsets.only(top: 4),
          child: UserPicWidget(
            pubkey: dmSession.pubkey,
            width: IMAGE_WIDTH,
          ),
        );

        var lastEvent = dmSession.newestEvent!;

        bool hasNewMessage = widget.detail.hasNewMessage();

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

        return Container(
          padding: const EdgeInsets.all(Base.BASE_PADDING),
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
                    left: Base.BASE_PADDING,
                    right: Base.BASE_PADDING,
                    top: 4,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: NameWidget(
                              pubkey: dmSession.pubkey,
                              metadata: metadata,
                              maxLines: 1,
                              textOverflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            alignment: Alignment.centerRight,
                            child: Text(
                              GetTimeAgo.parse(
                                  DateTime.fromMillisecondsSinceEpoch(
                                      lastEvent.createdAt * 1000)),
                              style: TextStyle(
                                fontSize: smallTextSize,
                                color: themeData.hintColor,
                              ),
                            ),
                          ),
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
      },
      selector: (_, provider) {
        return provider.getMetadata(widget.detail.dmSession.pubkey);
      },
    );

    return GestureDetector(
      onTap: () {
        RouterUtil.router(context, RouterPath.DM_DETAIL, widget.detail);
      },
      child: main,
    );
  }
}
