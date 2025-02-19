import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/component/tag_info_widget.dart';
import 'package:nostrmo/util/store_util.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../consts/base.dart';
import '../../generated/l10n.dart';
import '../main_btn_widget.dart';
import '../tag_widget.dart';

class EventTorrentWidget extends StatefulWidget {
  TorrentInfo torrentInfo;

  EventTorrentWidget(this.torrentInfo);

  @override
  State<StatefulWidget> createState() {
    return _EventTorrentWidgetState();
  }
}

class _EventTorrentWidgetState extends State<EventTorrentWidget> {
  bool showAllFile = false;

  @override
  Widget build(BuildContext context) {
    final localization = S.of(context);
    final themeData = Theme.of(context);
    var largeTextSize = themeData.textTheme.bodyLarge!.fontSize;

    var cardColor = themeData.cardColor;
    var boxDecoration = BoxDecoration(
      color: cardColor,
      boxShadow: [
        BoxShadow(
          color: themeData.shadowColor,
          offset: const Offset(0, 0),
          blurRadius: 10,
          spreadRadius: 0,
        ),
      ],
    );

    int totalSize = 0;
    for (var file in widget.torrentInfo.files!) {
      totalSize += file.size;
    }

    List<Widget> list = [];
    if (StringUtil.isNotBlank(widget.torrentInfo.title)) {
      list.add(Container(
        margin: const EdgeInsets.only(bottom: Base.BASE_PADDING_HALF),
        child: Text(
          widget.torrentInfo.title!,
          style: TextStyle(
            fontSize: largeTextSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ));
    }

    List<Widget> tagWidgets = [];
    tagWidgets.add(TagWidget(
      tag: StoreUtil.bytesToShowStr(totalSize),
      jumpable: false,
    ));
    for (var tag in widget.torrentInfo.tags!) {
      tagWidgets.add(TagWidget(tag: tag));
    }
    list.add(Container(
      margin: const EdgeInsets.only(bottom: Base.BASE_PADDING_HALF),
      child: Wrap(
        spacing: Base.BASE_PADDING_HALF,
        children: tagWidgets,
      ),
    ));

    var fileLength = widget.torrentInfo.files!.length;
    var showFileLimitNum = 4;
    if (showAllFile || fileLength.bitLength < showFileLimitNum) {
      for (var i = 0; i < fileLength; i++) {
        list.add(
            buildTorrentFileWidget(themeData, widget.torrentInfo.files![i]));
      }
    } else {
      for (var i = 0; i < showFileLimitNum; i++) {
        list.add(
            buildTorrentFileWidget(themeData, widget.torrentInfo.files![i]));
      }
      list.add(GestureDetector(
        onTap: () {
          setState(() {
            showAllFile = true;
          });
        },
        child: Text(
          localization.Show_more,
          style: TextStyle(
            color: themeData.primaryColor,
          ),
        ),
      ));
    }

    list.add(Container(
      margin: const EdgeInsets.only(top: Base.BASE_PADDING_HALF),
      child: MainBtnWidget(
        text: localization.Download,
        onTap: () {
          var link = "magnet:?xt=urn:btih:${widget.torrentInfo.btih}";
          if (widget.torrentInfo.trackers != null &&
              widget.torrentInfo.trackers!.isNotEmpty) {
            for (var tracker in widget.torrentInfo.trackers!) {
              link += "&tr=$tracker";
            }
          }

          Clipboard.setData(ClipboardData(text: link)).then((_) {
            BotToast.showText(text: S.of(context).Copy_success);
          });

          var url = Uri.parse(link);
          launchUrl(url);
        },
      ),
    ));

    return Container(
      padding: const EdgeInsets.all(Base.BASE_PADDING),
      margin: const EdgeInsets.all(Base.BASE_PADDING),
      decoration: boxDecoration,
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: list,
      ),
    );
  }

  Widget buildTorrentFileWidget(
      ThemeData themeData, TorrentFileInfo torrentFileInfo) {
    var hintColor = themeData.hintColor;

    return Text.rich(TextSpan(children: [
      TextSpan(
          text: torrentFileInfo.file,
          style: TextStyle(
            color: hintColor,
          )),
      TextSpan(text: " "),
      TextSpan(
          text: StoreUtil.bytesToShowStr(torrentFileInfo.size),
          style: TextStyle(
            color: hintColor,
            fontSize: themeData.textTheme.bodySmall!.fontSize,
          ))
    ]));
  }
}
