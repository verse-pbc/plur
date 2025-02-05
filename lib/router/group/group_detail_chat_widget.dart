import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/router/group/group_detail_provider.dart';
import 'package:nostrmo/util/load_more_event.dart';
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
  GroupIdentifier groupIdentifier;

  GroupDetailChatWidget(this.groupIdentifier, {super.key});

  @override
  State<StatefulWidget> createState() {
    return _GroupDetailChatWidgetState();
  }
}

class _GroupDetailChatWidgetState extends KeepAliveCustState<GroupDetailChatWidget>
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
    var textColor = themeData.textTheme.bodyMedium!.color;
    var cardColor = themeData.cardColor;

    final localization = S.of(context);

    groupDetailProvider = Provider.of<GroupDetailProvider>(context);
    var eventBox = groupDetailProvider!.chatsBox;
    var events = eventBox.all();
    preBuild();

    var localPubkey = nostr!.publicKey;

    List<Widget> list = [];

    var listWidget = ListView.builder(
      itemBuilder: (context, index) {
        if (index >= events.length) {
          return null;
        }

        var event = events[index];
        return DMDetailItemWidget(
          sessionPubkey: event.pubkey, // this pubkey maybe should set to null
          event: event,
          isLocal: localPubkey == event.pubkey,
        );
      },
      reverse: true,
      itemCount: events.length,
      dragStartBehavior: DragStartBehavior.down,
    );

    list.add(Expanded(
      child: Container(
        margin: const EdgeInsets.only(
          bottom: Base.BASE_PADDING,
        ),
        child: listWidget,
      ),
    ));

    list.add(Container(
      decoration: BoxDecoration(
        color: cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            offset: Offset(0, -5),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: quill.QuillEditor(
              configurations: quill.QuillEditorConfigurations(
                placeholder: localization.What_s_happening,
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
                  left: Base.BASE_PADDING,
                  right: Base.BASE_PADDING,
                ),
                maxHeight: 300, controller: editorController,
              ),
              scrollController: ScrollController(),
              focusNode: focusNode,
            ),
          ),
          TextButton(
            onPressed: send,
            style: const ButtonStyle(),
            child: Text(
              localization.Send,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
              ),
            ),
          )
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
        BotToast.showText(text: S.of(context).Send_fail);
        return;
      }

      editorController.clear();
      setState(() {});
    } finally {
      cancelFunc.call();
    }
  }

  @override
  Future<void> onReady(BuildContext context) async {}

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

  @override
  void doQuery() {
    preQuery();
    groupDetailProvider!.doQuery(until);
  }

  @override
  EventMemBox getEventBox() {
    return groupDetailProvider!.notesBox;
  }

  @override
  GroupIdentifier? getGroupIdentifier() {
    return widget.groupIdentifier;
  }

  @override
  int? getGroupEventKind() {
    return EventKind.GROUP_CHAT_MESSAGE;
  }
}
