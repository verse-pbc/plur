import 'dart:developer';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:intl/intl.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/component/editor/lnbc_embed_builder.dart';
import 'package:nostrmo/component/editor/mention_event_embed_builder.dart';
import 'package:nostrmo/component/editor/mention_user_embed_builder.dart';
import 'package:nostrmo/component/editor/pic_embed_builder.dart';
import 'package:nostrmo/component/editor/tag_embed_builder.dart';
import 'package:nostrmo/component/editor/video_embed_builder.dart';
import 'package:nostrmo/component/editor/zap_goal_input_widget.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/router/index/index_app_bar.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:provider/provider.dart';

import '../../component/appbar_back_btn_widget.dart';
import '../../component/cust_state.dart';
import '../../component/editor/custom_emoji_embed_builder.dart';
import '../../component/editor/editor_mixin.dart';
import '../../component/editor/poll_input_widget.dart';
import '../../component/editor/zap_split_input_widget.dart';
import '../../generated/l10n.dart';
import '../../provider/group_provider.dart';
import 'editor_notify_item_widget.dart';
import '../../component/info_message_widget.dart';
import '../../component/appbar_bottom_border.dart';

class EditorWidget extends StatefulWidget {
  static double appbarHeight = 56;

  // dm arg
  final String? pubkey;
  final GroupIdentifier? groupIdentifier;
  final int? groupEventKind;
  final List<dynamic> tags;
  final List<dynamic> tagsAddedWhenSend;
  final List<dynamic> tagPs;
  final List<BlockEmbed>? initEmbeds;
  final bool isLongForm;
  final bool isPoll;
  final bool isZapGoal;

  const EditorWidget({
    super.key,
    required this.tags,
    required this.tagsAddedWhenSend,
    required this.tagPs,
    this.pubkey,
    this.initEmbeds,
    this.groupIdentifier,
    this.groupEventKind,
    this.isLongForm = false,
    this.isPoll = false,
    this.isZapGoal = false,
  });

  static Future<Event?> open(
    BuildContext context, {
    List<dynamic>? tags,
    List<dynamic>? tagsAddedWhenSend,
    List<dynamic>? tagPs,
    String? pubkey,
    List<BlockEmbed>? initEmbeds,
    GroupIdentifier? groupIdentifier,
    int? groupEventKind,
    bool isLongForm = false,
    bool isPoll = false,
    bool isZapGoal = false,
  }) {
    tags ??= [];
    tagsAddedWhenSend ??= [];
    tagPs ??= [];

    var editor = EditorWidget(
      tags: tags,
      tagsAddedWhenSend: tagsAddedWhenSend,
      tagPs: tagPs,
      pubkey: pubkey,
      initEmbeds: initEmbeds,
      groupIdentifier: groupIdentifier,
      groupEventKind: groupEventKind,
      isLongForm: isLongForm,
      isPoll: isPoll,
      isZapGoal: isZapGoal,
    );

    return RouterUtil.push(context, MaterialPageRoute(builder: (context) {
      return editor;
    }));
  }

  @override
  State<StatefulWidget> createState() {
    return _EditorWidgetState();
  }
}

class _EditorWidgetState extends CustState<EditorWidget> with EditorMixin {
  List<EditorNotifyItem>? notifyItems;

  List<EditorNotifyItem> editorNotifyItems = [];

  var _hasMedia = false;

  @override
  void initState() {
    super.initState();
    inputPoll = widget.isPoll;
    inputZapGoal = widget.isZapGoal;
    handleFocusInit();
    _setUpListener();
  }

  void _setUpListener() {
    editorController.addListener(_editorControllerListener);
  }

  void _editorControllerListener() {
    // Check for media
    final delta = editorController.document.toDelta();
    var updated = false;

    try {
      final operations = delta.toList();
      final newHasMedia = operations.any((operation) =>
          operation.key == "insert" &&
          operation.data is Map &&
          _isMediaData(operation.data as Map));
      if (_hasMedia != newHasMedia) {
        _hasMedia = newHasMedia;
        updated = true;
      }

      // Process mentions
      Map<String, int> mentionUserMap = {};
      editorNotifyItems = [];

      for (final operation in operations) {
        if (operation.key == "insert" && operation.data is Map) {
          final m = operation.data as Map;
          final value = m["mentionUser"];
          if (StringUtil.isNotBlank(value)) {
            mentionUserMap[value] = 1;
          }
        }
      }

      // Handle deletions
      List<EditorNotifyItem> itemsToDelete = [];
      for (final item in editorNotifyItems) {
        final exist = mentionUserMap.remove(item.pubkey);
        if (exist == null) {
          itemsToDelete.add(item);
          updated = true;
        }
      }
      editorNotifyItems.removeWhere((element) => itemsToDelete.contains(element));

      // Handle additions
      if (mentionUserMap.isNotEmpty) {
        for (final entry in mentionUserMap.entries) {
          editorNotifyItems.add(EditorNotifyItem(pubkey: entry.key));
          updated = true;
        }
      }
    } catch (e) {
      log(e.toString());
    }

    if (updated) {
      setState(() {});
    }
  }

  bool _isMediaData(Map data) =>
      data.containsKey("image") || data.containsKey("video");

  @override
  GroupIdentifier? getGroupIdentifier() {
    return widget.groupIdentifier;
  }

  @override
  int? getGroupEventKind() {
    return widget.groupEventKind;
  }

  @override
  bool isLongForm() {
    return widget.isLongForm;
  }

  @override
  Widget doBuild(BuildContext context) {
    if (notifyItems == null) {
      notifyItems = [];
      for (var tagP in widget.tagPs) {
        if (tagP is List<dynamic> && tagP.length > 1) {
          notifyItems!.add(EditorNotifyItem(pubkey: tagP[1]));
        }
      }
    }

    final localization = S.of(context);
    final themeData = Theme.of(context);
    var textColor = themeData.textTheme.bodyMedium!.color;
    var cardColor = themeData.cardColor;
    var fontSize = themeData.textTheme.bodyMedium!.fontSize;
    var largeTextSize = themeData.textTheme.bodyLarge!.fontSize;

    List<Widget> list = [];

    if (widget.tags.isNotEmpty) {
      for (var tag in widget.tags) {
        if (tag.length > 1) {
          var tagName = tag[0];
          var tagValue = tag[1];

          if (tagName == "a") {
            // this note is add to community
            var aid = AId.fromString(tagValue);
            if (aid != null && aid.kind == EventKind.communityDefinition) {
              list.add(Container(
                padding: const EdgeInsets.all(Base.basePadding),
                margin: const EdgeInsets.only(bottom: Base.basePadding),
                decoration: BoxDecoration(
                  color: themeData.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(right: Base.basePadding),
                      child: Icon(
                        Icons.groups,
                        size: largeTextSize! * 1.2,
                        color: themeData.primaryColor,
                      ),
                    ),
                    Text(
                      "${localization.postingTo} ${aid.title}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: largeTextSize,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ));
            }
          }
        }
      }
    }
    
    // If posting to a group through groupIdentifier but no tag is found above
    if (widget.groupIdentifier != null && list.isEmpty) {
      list.add(Container(
        padding: const EdgeInsets.all(Base.basePadding),
        margin: const EdgeInsets.only(bottom: Base.basePadding),
        decoration: BoxDecoration(
          color: themeData.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            Container(
              margin: const EdgeInsets.only(right: Base.basePadding),
              child: Icon(
                Icons.groups,
                size: largeTextSize! * 1.2,
                color: themeData.primaryColor,
              ),
            ),
            Selector<GroupProvider, GroupMetadata?>(
              selector: (_, provider) => widget.groupIdentifier != null 
                ? provider.getMetadata(widget.groupIdentifier!) 
                : null,
              builder: (context, metadata, child) {
                final groupName = metadata?.name ?? widget.groupIdentifier?.groupId ?? '';
                return Text(
                  "${localization.postingTo} $groupName",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: largeTextSize,
                    color: textColor,
                  ),
                );
              },
            ),
          ],
        ),
      ));
    }

    if ((notifyItems != null && notifyItems!.isNotEmpty) ||
        (editorNotifyItems.isNotEmpty)) {
      List<Widget> tagPsWidgets = [];
      tagPsWidgets.add(Text("${localization.notify}:"));
      for (var item in notifyItems!) {
        tagPsWidgets.add(EditorNotifyItemWidget(item: item));
      }
      for (var editorNotifyItem in editorNotifyItems) {
        var exist = notifyItems!.any((element) {
          return element.pubkey == editorNotifyItem.pubkey;
        });
        if (!exist) {
          tagPsWidgets.add(EditorNotifyItemWidget(item: editorNotifyItem));
        }
      }
      list.add(Container(
        padding: const EdgeInsets.only(left: Base.basePadding, right: Base.basePadding),
        margin: const EdgeInsets.only(bottom: Base.basePaddingHalf),
        width: double.maxFinite,
        child: Wrap(
          spacing: Base.basePaddingHalf,
          runSpacing: Base.basePaddingHalf,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: tagPsWidgets,
        ),
      ));
    }

    if (showTitle) {
      list.add(buildTitleWidget());
    }

    if (isLongForm()) {
      list.add(buildTitleWidget());

      list.add(buildLongFormImageWidget());

      list.add(buildSummaryWidget());
    }

    if (publishAt != null) {
      var dateFormate = DateFormat("yyyy-MM-dd HH:mm");

      list.add(GestureDetector(
        onTap: selectedTime,
        behavior: HitTestBehavior.translucent,
        child: Container(
          margin: const EdgeInsets.only(left: 10, bottom: Base.basePaddingHalf),
          child: Row(
            children: [
              const Icon(Icons.timer_outlined),
              Container(
                margin: const EdgeInsets.only(left: 4),
                child: Text(
                  dateFormate.format(publishAt!),
                ),
              ),
            ],
          ),
        ),
      ));
    }

    Widget quillWidget = QuillEditor(
      controller: editorController,
      configurations: QuillEditorConfigurations(
        placeholder: localization.whatSHappening,
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
        // padding: EdgeInsets.zero,
        padding: const EdgeInsets.only(
          left: Base.basePadding,
          right: Base.basePadding,
        ),
      ),
      scrollController: ScrollController(),
      focusNode: focusNode,
    );
    List<Widget> editorList = [];
    var editorInputWidget = Container(
      margin: const EdgeInsets.only(bottom: Base.basePadding),
      child: quillWidget,
    );
    editorList.add(editorInputWidget);
    if (inputPoll) {
      editorList.add(PollInputWidget(
        pollInputController: pollInputController,
      ));
    }
    if (inputZapGoal) {
      editorList.add(ZapGoalInputWidget(
        zapGoalInputController: zapGoalInputController,
      ));
    }
    if (openZapSplit) {
      editorList.add(ZapSplitInputWidget(eventZapInfos));
    }

    list.add(Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          // focus to editor input widget
          focusNode.requestFocus();
        },
        child: Container(
          constraints: BoxConstraints(
              maxHeight: mediaDataCache.size.height -
                  mediaDataCache.padding.top -
                  EditorWidget.appbarHeight -
                  IndexAppBar.height),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...editorList,
                if (_hasMedia) const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    ));

    if (_hasMedia) {
      list.add(InfoMessageWidget(
        message: localization.allMediaPublic,
        icon: Icons.info,
      ));
    }

    list.add(buildEditorBtns());
    if (emojiShow) {
      list.add(buildEmojiSelector());
    }
    if (customEmojiShow) {
      list.add(buildEmojiListsWidget());
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: cardColor,
        bottom: const AppBarBottomBorder(),
        leading: const AppbarBackBtnWidget(),
        title: widget.groupIdentifier != null ? Text(
          localization.newPost,
          style: TextStyle(
            color: textColor,
            fontSize: fontSize,
          ),
        ) : null,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: Base.basePadding),
            child: ElevatedButton(
              onPressed: documentSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: themeData.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    localization.send,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.send, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Container(
        color: cardColor,
        width: double.infinity,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Add margins on larger screens but keep full width on small screens
            final screenWidth = MediaQuery.of(context).size.width;
            final isSmallScreen = screenWidth < 600;
            
            return Center(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: isSmallScreen ? double.infinity : 600,
                ),
                padding: isSmallScreen ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: list,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Future<void> onReady(BuildContext context) async {
    if (widget.initEmbeds != null && widget.initEmbeds!.isNotEmpty) {
      {
        final index = editorController.selection.baseOffset;
        final length = editorController.selection.extentOffset - index;

        editorController.replaceText(index, length, "\n", null);

        editorController.moveCursorToPosition(index + 1);
      }

      for (var embed in widget.initEmbeds!) {
        final index = editorController.selection.baseOffset;
        final length = editorController.selection.extentOffset - index;

        editorController.replaceText(index, length, embed, null);

        editorController.moveCursorToPosition(index + 1);
      }

      editorController.moveCursorToPosition(0);
    }
  }

  Future<void> documentSave() async {
    var cancelFunc = BotToast.showLoading();
    try {
      var event = await doDocumentSave();
      if (!mounted) return;
      if (event == null) {
        BotToast.showText(text: S.of(context).sendFail);
        return;
      }
      RouterUtil.back(context, event);
    } finally {
      cancelFunc.call();
    }
  }

  @override
  BuildContext getContext() {
    return context;
  }

  @override
  void updateUI() {
    setState(() {});
  }

  @override
  String? getPubkey() {
    return widget.pubkey;
  }

  @override
  List getTags() {
    return widget.tags;
  }

  @override
  List getTagsAddedWhenSend() {
    if ((notifyItems == null || notifyItems!.isEmpty) &&
        editorNotifyItems.isEmpty) {
      return widget.tagsAddedWhenSend;
    }

    List<dynamic> list = [];
    list.addAll(widget.tagsAddedWhenSend);
    for (var item in notifyItems!) {
      if (item.selected) {
        list.add(["p", item.pubkey]);
      }
    }

    for (var editorNotifyItem in editorNotifyItems) {
      var exist = notifyItems!.any((element) {
        return element.pubkey == editorNotifyItem.pubkey;
      });
      if (!exist) {
        if (editorNotifyItem.selected) {
          list.add(["p", editorNotifyItem.pubkey]);
        }
      }
    }

    return list;
  }

  @override
  bool isDM() {
    return false;
  }

  @override
  void dispose() {
    editorController.removeListener(_editorControllerListener);
    super.dispose();
  }
}
