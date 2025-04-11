import 'package:flutter/material.dart';
import 'package:get_time_ago/get_time_ago.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/component/content/content_widget.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:provider/provider.dart';

import '../../component/user/user_pic_widget.dart';
import '../../consts/base.dart';
import '../../consts/base_consts.dart';
import '../../provider/settings_provider.dart';
import '../group/group_detail_chat_widget.dart';
import 'dm_plaintext_handle.dart';

class DMDetailItemWidget extends StatefulWidget {
  final String sessionPubkey;

  final Event event;

  final bool isLocal;
  
  final String? replyToId;

  const DMDetailItemWidget({
    super.key, 
    required this.sessionPubkey,
    required this.event,
    required this.isLocal,
    this.replyToId,
  });

  @override
  State<StatefulWidget> createState() {
    return _DMDetailItemWidgetState();
  }
}

class _DMDetailItemWidgetState extends State<DMDetailItemWidget>
    with DMPlaintextHandle {
  static const double imageWidth = 34;

  static const double blankWidth = 50;

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final themeData = Theme.of(context);
    var mainColor = themeData.primaryColor;
    Widget userHeadWidget = Container(
      margin: const EdgeInsets.only(top: 2),
      child: UserPicWidget(
        pubkey: widget.event.pubkey,
        width: imageWidth,
      ),
    );
    // var maxWidth = mediaDataCache.size.width;
    var smallTextSize = themeData.textTheme.bodySmall!.fontSize;
    var hintColor = themeData.hintColor;

    String timeStr = GetTimeAgo.parse(
        DateTime.fromMillisecondsSinceEpoch(widget.event.createdAt * 1000));

    if (currentPlainEventId != widget.event.id) {
      plainContent = null;
    }

    var content = widget.event.content;
    if (widget.event.kind == EventKind.directMessage &&
        StringUtil.isBlank(plainContent)) {
      handleEncryptedText(widget.event, widget.sessionPubkey);
    }
    if (StringUtil.isNotBlank(plainContent)) {
      content = plainContent!;
    }
    content = content.replaceAll("\r", " ");
    content = content.replaceAll("\n", " ");

    var timeWidget = Text(
      timeStr,
      style: TextStyle(
        color: hintColor,
        fontSize: smallTextSize,
      ),
    );
    Widget enhancedIcon = Container();
    if (widget.event.kind == EventKind.privateDirectMessage) {
      enhancedIcon = Container(
        margin: const EdgeInsets.only(
          left: Base.basePaddingHalf,
          right: Base.basePaddingHalf,
        ),
        child: Icon(
          Icons.enhanced_encryption,
          size: smallTextSize! + 2,
          color: hintColor,
        ),
      );
    }
    List<Widget> topList = [];
    if (widget.isLocal) {
      topList.add(enhancedIcon);
      topList.add(timeWidget);
    } else {
      topList.add(timeWidget);
      topList.add(enhancedIcon);
    }

    // Build the reply indicator if this is a reply
    Widget? replyIndicator;
    if (widget.replyToId != null) {
      replyIndicator = Container(
        margin: const EdgeInsets.only(bottom: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.reply,
              size: 14,
              color: hintColor,
            ),
            const SizedBox(width: 4),
            Text(
              'Reply',
              style: TextStyle(
                fontSize: 12,
                color: hintColor,
              ),
            ),
          ],
        ),
      );
    }

    var contentWidget = Container(
      margin: const EdgeInsets.only(
        left: Base.basePaddingHalf,
        right: Base.basePaddingHalf,
      ),
      child: Column(
        crossAxisAlignment:
            !widget.isLocal ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: topList,
          ),
          if (replyIndicator != null) replyIndicator,
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.only(
              top: Base.basePaddingHalf - 1,
              right: Base.basePaddingHalf,
              bottom: Base.basePaddingHalf,
              left: Base.basePaddingHalf + 1,
            ),
            // constraints:
            //     BoxConstraints(maxWidth: (maxWidth - imageWidth) * 0.85),
            decoration: BoxDecoration(
              // color: Colors.red,
              color: mainColor.withOpacity(0.3),
              borderRadius: const BorderRadius.all(Radius.circular(5)),
            ),
            // child: SelectableText(content),
            child: GestureDetector(
              onLongPress: () {
                // Show context menu with reply option
                final RenderBox renderBox = context.findRenderObject() as RenderBox;
                final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
                final RelativeRect position = RelativeRect.fromRect(
                  Rect.fromPoints(
                    renderBox.localToGlobal(Offset.zero, ancestor: overlay),
                    renderBox.localToGlobal(renderBox.size.bottomRight(Offset.zero), ancestor: overlay),
                  ),
                  Offset.zero & overlay.size,
                );
                
                showMenu(
                  context: context,
                  position: position,
                  items: [
                    PopupMenuItem(
                      value: 'reply',
                      child: Row(
                        children: const [
                          Icon(Icons.reply),
                          SizedBox(width: 8),
                          Text('Reply'),
                        ],
                      ),
                    ),
                  ],
                ).then((value) {
                  if (value == 'reply') {
                    // Notify parent to set up reply
                    final chatWidget = context.findAncestorStateOfType<GroupDetailChatWidgetState>();
                    if (chatWidget != null) {
                      chatWidget.setReplyToEvent(widget.event);
                    }
                  }
                });
              },
              child: Column(
                crossAxisAlignment: widget.isLocal
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ContentWidget(
                    content: content,
                    event: widget.event,
                    showLinkPreview: settingsProvider.linkPreview == OpenStatus.open,
                    showImage: true,  // Enable image display
                    showVideo: true,  // Enable video display
                    smallest: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    // if (!widget.isLocal) {
    userHeadWidget = GestureDetector(
      onTap: () {
        RouterUtil.router(context, RouterPath.user, widget.event.pubkey);
      },
      child: userHeadWidget,
    );
    // }

    List<Widget> list = [];
    if (widget.isLocal) {
      list.add(Container(width: blankWidth));
      list.add(Expanded(child: contentWidget));
      list.add(userHeadWidget);
    } else {
      list.add(userHeadWidget);
      list.add(Expanded(child: contentWidget));
      list.add(Container(width: blankWidth));
    }

    return Container(
      padding: const EdgeInsets.all(Base.basePaddingHalf),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: list,
      ),
    );
  }
}
