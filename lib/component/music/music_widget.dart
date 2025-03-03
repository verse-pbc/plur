import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:nostrmo/nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/component/webview_widget.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/util/duartion_tool.dart';
import 'package:provider/provider.dart';
import 'package:widget_size/widget_size.dart';

import '../../provider/music_provider.dart';
import '../image_widget.dart';

class MusicWidget extends StatefulWidget {
  MusicInfo musicInfo;

  bool clearAble;

  MusicWidget(this.musicInfo, {super.key, this.clearAble = false});

  @override
  State<StatefulWidget> createState() {
    return _MusicWidgetState();
  }
}

class _MusicWidgetState extends State<MusicWidget> {
  double progressBarWidth = -1;

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    var cardColor = themeData.cardColor;
    var titleFontSize = themeData.textTheme.bodyMedium!.fontSize;
    var nameFontSize = themeData.textTheme.bodySmall!.fontSize;
    var hintColor = themeData.hintColor;

    var subInfoTextStyle = TextStyle(
      fontSize: nameFontSize,
      fontWeight: FontWeight.w500,
      color: hintColor,
    );

    var musicProvider = Provider.of<MusicProvider>(context);
    var currentDuration = musicProvider.currentDuration;
    var currentPosition = musicProvider.currentPosition;
    bool isCurrent = false;
    if (musicProvider.musicInfo != null &&
        musicProvider.musicInfo!.sourceUrl == widget.musicInfo.sourceUrl) {
      isCurrent = true;
    }

    var imageHeight = (titleFontSize! + nameFontSize!) * 1.7;

    Widget? imageWidget;
    if (StringUtil.isNotBlank(widget.musicInfo.imageUrl)) {
      imageWidget = ImageWidget(
        imageUrl: widget.musicInfo.imageUrl!,
        width: imageHeight,
        height: imageHeight,
      );
    } else {
      imageWidget = Container(
        width: imageHeight,
        height: imageHeight,
        color: themeData.hintColor.withOpacity(0.5),
      );
    }

    var btnIcon = Icons.play_circle_outline;
    if (isCurrent && musicProvider.isPlaying) {
      btnIcon = Icons.pause_circle_outline;
    }

    List<Widget> musicSubInfos = [];
    if (StringUtil.isNotBlank(widget.musicInfo.icon)) {
      musicSubInfos.add(Container(
        margin: const EdgeInsets.only(right: Base.BASE_PADDING_HALF),
        child: Image.asset(
          widget.musicInfo.icon!,
          width: 18,
          height: 18,
        ),
      ));
    }
    if (StringUtil.isNotBlank(widget.musicInfo.name)) {
      musicSubInfos.add(Text(
        widget.musicInfo.name!,
        style: subInfoTextStyle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ));
    }

    if (isCurrent &&
        currentDuration != null &&
        currentPosition != null &&
        currentPosition.inSeconds > 0 &&
        currentDuration.inSeconds > 0) {
      if (StringUtil.isNotBlank(widget.musicInfo.name)) {
        musicSubInfos.add(Text(
          "  •  ",
          style: subInfoTextStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ));
      }
      musicSubInfos.add(Text(
        "${currentPosition.prettyDuration()} / ${currentDuration.prettyDuration()}",
        style: subInfoTextStyle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ));
    }

    List<Widget> topList = [
      imageWidget,
      Expanded(
          child: Container(
        padding: const EdgeInsets.only(
          left: Base.BASE_PADDING,
          right: Base.BASE_PADDING,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.musicInfo.title != null ? widget.musicInfo.title! : "",
              style: TextStyle(
                fontSize: titleFontSize,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Row(
              children: musicSubInfos,
            ),
          ],
        ),
      )),
      SizedBox(
        width: imageHeight,
        height: imageHeight,
        child: GestureDetector(
          onTap: () {
            if (isCurrent) {
              musicProvider.playOrPause();
            } else {
              musicProvider.play(widget.musicInfo);
            }
          },
          child: Icon(btnIcon),
        ),
      ),
    ];
    if (widget.clearAble) {
      topList.add(SizedBox(
        width: imageHeight,
        height: imageHeight,
        child: GestureDetector(
          onTap: () {
            musicProvider.stop();
          },
          child: const Icon(Icons.clear),
        ),
      ));
    }

    var topWidget = Row(
      children: topList,
    );

    Widget progressBar = Container(
      height: 4,
    );
    if (musicProvider.isPlaying && isCurrent) {
      double? value;
      if (currentDuration != null &&
          currentPosition != null &&
          currentPosition.inSeconds > 0 &&
          currentDuration.inSeconds > 0) {
        value = currentPosition.inSeconds / currentDuration.inSeconds;
      }
      progressBar = WidgetSize(
        onChange: (size) {
          progressBarWidth = size.width;
        },
        child: LinearProgressIndicator(
          value: value,
        ),
      );

      progressBar = GestureDetector(
        onTapUp: (detail) {
          if (progressBarWidth > 0) {
            musicProvider.seek(detail.localPosition.dx / progressBarWidth);
          }
        },
        child: progressBar,
      );
    }

    return GestureDetector(
      onTap: () {
        if (widget.musicInfo.sourceUrl != null &&
            widget.musicInfo.sourceUrl!.indexOf("http") == 0) {
          WebViewWidget.open(context, widget.musicInfo.sourceUrl!);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            color: cardColor,
            height: imageHeight,
            child: topWidget,
          ),
          progressBar,
        ],
      ),
    );
  }
}
