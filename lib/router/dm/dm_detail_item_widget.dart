import 'package:flutter/material.dart';
import 'package:get_time_ago/get_time_ago.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/component/content/content_widget.dart';
import 'package:nostrmo/component/content/content_image_widget.dart';
import 'package:nostrmo/component/content/content_video_widget.dart';
import 'package:nostrmo/component/json_view_dialog.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostrmo/util/router_util.dart';
import 'dart:convert';
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
    
    // Check if content contains image or video URLs
    bool containsMedia = false;
    String? mediaUrl;
    String contentType = "text";
    
    // Simple URL detection for images and videos
    final urlPattern = RegExp(r'https?:\/\/[^\s]+\.(jpg|jpeg|png|gif|mp4|webm|mov)');
    final match = urlPattern.firstMatch(content);
    if (match != null) {
      mediaUrl = match.group(0);
      final extension = match.group(1)?.toLowerCase();
      
      if (extension == 'jpg' || extension == 'jpeg' || extension == 'png' || extension == 'gif') {
        contentType = "image";
        containsMedia = true;
      } else if (extension == 'mp4' || extension == 'webm' || extension == 'mov') {
        contentType = "video";
        containsMedia = true;
      }
    }
    
    // Create message metadata row with time and encryption indicator
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
    
    // Format for display in message bubble
    String displayContent = content;
    if (containsMedia) {
      // Remove the media URL from the text content to avoid duplication
      displayContent = content.replaceAll(mediaUrl!, '').trim();
    }
    displayContent = displayContent.replaceAll("\r", " ");
    displayContent = displayContent.replaceAll("\n", " ");

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
            decoration: BoxDecoration(
              color: mainColor.withOpacity(0.3),
              borderRadius: const BorderRadius.all(Radius.circular(5)),
            ),
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
                    PopupMenuItem(
                      value: 'view_raw',
                      child: Row(
                        children: const [
                          Icon(Icons.code),
                          SizedBox(width: 8),
                          Text('View Raw Event'),
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
                  } else if (value == 'view_raw') {
                    // Show the raw event in a JSON viewer
                    _showRawEvent();
                  }
                });
              },
              child: Column(
                crossAxisAlignment: widget.isLocal
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Show text content if available
                  if (displayContent.isNotEmpty)
                    ContentWidget(
                      content: displayContent,
                      event: widget.event,
                      showLinkPreview: settingsProvider.linkPreview == OpenStatus.open,
                      showImage: false,  // Don't show images in the text content
                      showVideo: false,  // Don't show videos in the text content
                      smallest: true,
                    ),
                  
                  // Add spacing if we have both text and media
                  if (displayContent.isNotEmpty && containsMedia)
                    const SizedBox(height: 8),
                  
                  // Show inline media if available
                  if (containsMedia && mediaUrl != null)
                    contentType == "image" 
                      ? ContentImageWidget(
                          imageUrl: mediaUrl,
                          width: 200,  // Set reasonable width for chat bubble
                          height: 150,  // Set reasonable height for chat bubble
                          imageBoxFix: BoxFit.cover,
                        )
                      : ContentVideoWidget(
                          url: mediaUrl,
                          width: 200,  // Set reasonable width for chat bubble
                          height: 150,  // Set reasonable height for chat bubble
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
  
  void _showRawEvent() {
    // Convert event to a map that can be easily viewed
    final eventMap = {
      'id': widget.event.id,
      'pubkey': widget.event.pubkey,
      'created_at': widget.event.createdAt,
      'kind': widget.event.kind,
      'tags': widget.event.tags,
      'content': widget.event.content,
      'sig': widget.event.sig,
    };
    
    // Convert to pretty-printed JSON
    final prettyJson = JsonEncoder.withIndent('  ').convert(eventMap);
    
    // Show dialog with the JSON content
    JsonViewDialog.show(context, prettyJson);
  }
}
