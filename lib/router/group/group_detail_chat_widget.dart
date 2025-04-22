import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/consts/plur_colors.dart';
import 'package:nostrmo/router/group/group_detail_provider.dart';
import 'package:nostrmo/router/group/no_chats_widget.dart';
import 'package:nostrmo/util/load_more_event.dart';
import 'package:nostrmo/util/time_util.dart';
import 'package:provider/provider.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

import '../../component/editor/custom_emoji_embed_builder.dart';
import '../../component/editor/editor_mixin.dart';
import '../../component/editor/lnbc_embed_builder.dart';
import '../../component/editor/mention_event_embed_builder.dart';
import '../../component/editor/mention_user_embed_builder.dart';
import '../../component/editor/pic_embed_builder.dart';
import '../../component/editor/tag_embed_builder.dart';
import '../../component/editor/video_embed_builder.dart';
import '../../component/keep_alive_cust_state.dart';
import '../../consts/base.dart';
import '../../generated/l10n.dart';
import '../../main.dart';
import '../dm/dm_detail_item_widget.dart';

class GroupDetailChatWidget extends StatefulWidget {
  final GroupIdentifier groupIdentifier;

  const GroupDetailChatWidget(this.groupIdentifier, {super.key});

  @override
  State<StatefulWidget> createState() {
    return GroupDetailChatWidgetState();
  }
}

class GroupDetailChatWidgetState extends KeepAliveCustState<GroupDetailChatWidget>
    with LoadMoreEvent, EditorMixin {
  GroupDetailProvider? groupDetailProvider;

  @override
  void initState() {
    super.initState();
    handleFocusInit();
  }

  @override
  Widget doBuild(BuildContext context) {
    final themeData = Theme.of(context);
    var cardColor = themeData.cardColor;

    final localization = S.of(context);

    groupDetailProvider = Provider.of<GroupDetailProvider>(context);
    var eventBox = groupDetailProvider!.chatsBox;
    var events = eventBox.all();
    preBuild();

    var localPubkey = nostr!.publicKey;

    List<Widget> list = [];
    
    Widget contentWidget;
    if (events.isEmpty) {
      contentWidget = NoChatsWidget(
        groupName: widget.groupIdentifier.groupId,
        onRefresh: () async {
          groupDetailProvider!.refresh();
        },
      );
    } else {
      contentWidget = ListView.builder(
        itemBuilder: (context, index) {
          if (index >= events.length) {
            return null;
          }

          var event = events[index];
          // Check if this is a reply to show proper threading
          bool isReply = event.kind == EventKind.groupChatReply;
          String? replyId;
          
          if (isReply) {
            // Get the event being replied to from e tags
            for (final tag in event.tags) {
              if (tag.length > 1 && tag[0] == "e") {
                replyId = tag[1];
                break;
              }
            }
          }
          
          return DMDetailItemWidget(
            sessionPubkey: event.pubkey,
            event: event,
            isLocal: localPubkey == event.pubkey,
            replyToId: replyId,
          );
        },
        reverse: true,
        itemCount: events.length,
        dragStartBehavior: DragStartBehavior.down,
      );
    }

    list.add(Expanded(
      child: Container(
        margin: const EdgeInsets.only(
          bottom: Base.basePadding,
        ),
        child: contentWidget,
      ),
    ));

    // Build reply indicator if we're replying to a message
    Widget? replyIndicator;
    if (replyToEvent != null) {
      replyIndicator = Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Base.basePadding,
          vertical: 8,
        ),
        color: themeData.brightness == Brightness.dark
          ? themeData.highlightColor.withValues(alpha: 0.2 * 255)
          : Colors.grey.withValues(alpha: 0.1 * 255),
        child: Row(
          children: [
            Icon(Icons.reply, 
              size: 18, 
              color: themeData.brightness == Brightness.dark ? null : PlurColors.lightSecondaryText
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "Replying to ${StringUtil.isNotBlank(replyToEvent!.content) ? 
                  StringUtil.breakLongText(replyToEvent!.content, 30) : 
                  'message'}",
                style: TextStyle(
                  fontSize: 14,
                  color: themeData.brightness == Brightness.dark 
                    ? themeData.hintColor 
                    : PlurColors.lightSecondaryText,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: Icon(Icons.close, 
                size: 18,
                color: themeData.brightness == Brightness.dark ? null : PlurColors.lightSecondaryText,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: clearReplyToEvent,
            ),
          ],
        ),
      );
    }
    
    list.add(Container(
      decoration: BoxDecoration(
        color: cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(51),
            offset: const Offset(0, -5),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          if (replyIndicator != null) replyIndicator,
          Row(
            children: [
              Expanded(
                child: quill.QuillEditor(
                  controller: editorController,
                  configurations: quill.QuillEditorConfigurations(
                    placeholder: replyToEvent != null ? 
                      "Write a reply..." : 
                      localization.whatSHappening,
                    embedBuilders: [
                      MentionUserEmbedBuilder(),
                      MentionEventEmbedBuilder(),
                      PicEmbedBuilder(),
                      VideoEmbedBuilder(),
                      LnbcEmbedBuilder(),
                      TagEmbedBuilder(),
                      CustomEmojiEmbedBuilder(),
                    ],
                    scrollable: true,
                    autoFocus: false,
                    expands: false,
                    padding: const EdgeInsets.only(
                      left: Base.basePadding,
                      right: Base.basePadding,
                    ),
                    maxHeight: 300,
                  ),
                  scrollController: ScrollController(),
                  focusNode: focusNode,
                ),
              ),
              TextButton(
                onPressed: send,
                style: const ButtonStyle(),
                child: Text(
                  localization.send,
                  style: TextStyle(
                    color: PlurColors.textColor(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            ],
          ),
        ],
      ),
    ));

    list.add(buildEditorBtns(showShadow: false, height: null));
    if (emojiShow) {
      list.add(buildEmojiSelector());
    }
    if (customEmojiShow) {
      list.add(buildEmojiListsWidget());
    }

    return SizedBox(
      width: double.maxFinite,
      height: double.maxFinite,
      child: Column(children: list),
    );
  }

  Future<void> send() async {
    var cancelFunc = BotToast.showLoading();
    try {
      var event = await doDocumentSave();
      if (event == null) {
        if (!mounted) return;
        BotToast.showText(text: S.of(context).sendFail);
        return;
      }

      editorController.clear();
      setState(() {});
    } finally {
      cancelFunc.call();
    }
  }

  String subscribeId = StringUtil.rndNameStr(16);
  
  @override
  Future<void> onReady(BuildContext context) async {
    _subscribe();
  }
  
  void _subscribe() {
    if (StringUtil.isNotBlank(subscribeId)) {
      _unsubscribe();
    }

    final currentTime = currentUnixTimestamp();
    final filters = [
      {
        // Listen for group chat messages (NIP-29)
        "kinds": [EventKind.groupChatMessage],
        "#h": [widget.groupIdentifier.groupId],
        "since": currentTime
      },
      {
        // Listen for group chat replies (NIP-29)
        "kinds": [EventKind.groupChatReply],
        "#h": [widget.groupIdentifier.groupId],
        "since": currentTime
      }
    ];

    try {
      nostr!.subscribe(
        filters,
        _handleSubscriptionEvent,
        id: subscribeId,
        relayTypes: [RelayType.temp],
        tempRelays: [widget.groupIdentifier.host],
        sendAfterAuth: true,
      );
    } catch (e) {
      debugPrint("Error in chat subscription: $e");
    }
  }

  void _handleSubscriptionEvent(Event event) {
    if (groupDetailProvider != null) {
      groupDetailProvider!.onNewEvent(event);
    }
  }

  void _unsubscribe() {
    try {
      nostr!.unsubscribe(subscribeId);
    } catch (e) {
      debugPrint("Error unsubscribing from chat: $e");
    }
  }
  
  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  @override
  BuildContext getContext() {
    return context;
  }

  @override
  List getTags() {
    return [];
  }

  @override
  List getTagsAddedWhenSend() {
    List<dynamic> tags = [];
    var previousTag = ["previous", ...groupDetailProvider!.chatsPrevious()];
    tags.add(previousTag);
    
    // Add reply tag if we're replying to a message
    if (replyToEvent != null) {
      tags.add(["e", replyToEvent!.id, "", "reply"]);
      tags.add(["p", replyToEvent!.pubkey]);
      
      // After sending, clear the reply state
      Future.delayed(Duration.zero, () {
        clearReplyToEvent();
      });
    }
    
    return tags;
  }

  @override
  void updateUI() {
    setState(() {});
  }

  @override
  bool isDM() {
    return false;
  }

  @override
  String? getPubkey() {
    return null;
  }
  
  Event? replyToEvent;
  
  // Public method to set reply to event
  void setReplyToEvent(Event event) {
    setState(() {
      replyToEvent = event;
    });
  }
  
  // Public method to clear reply state
  void clearReplyToEvent() {
    setState(() {
      replyToEvent = null;
    });
  }

  @override
  void doQuery() {
    preQuery();
    groupDetailProvider!.doQuery(until);
  }

  @override
  EventMemBox getEventBox() {
    return groupDetailProvider!.chatsBox;
  }

  @override
  GroupIdentifier? getGroupIdentifier() {
    return widget.groupIdentifier;
  }

  @override
  int? getGroupEventKind() {
    // If replying to a message, use groupChatReply, otherwise use groupChatMessage
    return replyToEvent != null ? EventKind.groupChatReply : EventKind.groupChatMessage;
  }
}
