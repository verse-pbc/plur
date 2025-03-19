import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:nostrmo/component/appbar_bottom_border.dart';
import 'package:nostrmo/nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/util/router_util.dart';

import '../../component/appbar_back_btn_widget.dart';
import '../../component/cust_state.dart';
import '../../component/editor/editor_mixin.dart';
import '../../generated/l10n.dart';
import 'editor_notify_item_widget.dart';
import '../../util/theme_util.dart';
import 'package:nostrmo/router/edit/editor_body.dart';
import 'package:nostrmo/router/edit/editor_header.dart';
import 'package:nostrmo/router/edit/editor_footer.dart';

class EditorWidget extends StatefulWidget {
  static const double appbarHeight = 56;

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
  State<StatefulWidget> createState() => _EditorWidgetState();
}

class _EditorWidgetState extends CustState<EditorWidget> with EditorMixin {
  late final List<EditorNotifyItem>? notifyItems;
  List<EditorNotifyItem> editorNotifyItems = [];
  bool hasMedia = false;

  @override
  void initState() {
    super.initState();
    inputPoll = widget.isPoll;
    inputZapGoal = widget.isZapGoal;
    handleFocusInit();
    initializeNotifyItems();
    _setupMediaListener();
  }

  void _setupMediaListener() {
    editorController.addListener(_updateHasMedia);
  }

  void _updateHasMedia() {
    final delta = editorController.document.toDelta();
    final newHasMedia = _checkForMedia(delta);
    if (hasMedia != newHasMedia) {
      setState(() => hasMedia = newHasMedia);
    }
  }

  bool _checkForMedia(Object delta) {
    return (delta as dynamic).toList().any((operation) =>
        operation.key == "insert" &&
        operation.data is Map &&
        _isMediaData(operation.data as Map));
  }

  bool _isMediaData(Map data) =>
      data.containsKey("image") || data.containsKey("video");

  void initializeNotifyItems() {
    notifyItems = widget.tagPs
        .where((tagP) => tagP is List<dynamic> && tagP.length > 1)
        .map((tagP) => EditorNotifyItem(pubkey: tagP[1]))
        .toList();
  }

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
    final localization = S.of(context);
    final themeData = Theme.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: themeData.customColors.navBgColor,
        bottom: const AppBarBottomBorder(),
        leading: const AppbarBackBtnWidget(),
        actions: [
          TextButton(
            onPressed: documentSave,
            child: Text(
              localization.Send,
              style: TextStyle(
                color: themeData.textTheme.bodyMedium!.color,
                fontSize: themeData.textTheme.bodyMedium!.fontSize,
              ),
            ),
          ),
        ],
      ),
      body: Container(
        color: themeData.customColors.loginBgColor,
        padding: EdgeInsets.only(top: hasMedia ? 0 : 20),
        child: Column(
          children: [
            EditorHeader(
              data: EditorHeaderData(
                publishAt: publishAt,
                tags: widget.tags,
                notifyItems: notifyItems,
                editorNotifyItems: editorNotifyItems,
                isLongForm: isLongForm(),
              ),
              onTimeSelected: selectedTime,
              titleBuilder: (context) => buildTitleWidget(),
              longFormImageBuilder: (context) => buildLongFormImageWidget(),
              summaryBuilder: (context) => buildSummaryWidget(),
            ),
            EditorBody(
              editorController: editorController,
              focusNode: focusNode,
              placeholder: localization.What_s_happening,
              inputPoll: inputPoll,
              inputZapGoal: inputZapGoal,
              openZapSplit: openZapSplit,
              pollInputController: pollInputController,
              zapGoalInputController: zapGoalInputController,
              eventZapInfos: eventZapInfos,
            ),
            EditorFooter(
              hasMedia: hasMedia,
              editorButtons: buildEditorBtns(),
              emojiSelector: emojiShow ? buildEmojiSelector() : null,
              emojiListsWidget:
                  customEmojiShow ? buildEmojiListsWidget() : null,
            ),
          ],
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

    editorNotifyItems = [];
    editorController.addListener(() {
      bool updated = false;
      Map<String, int> mentionUserMap = {};

      var delta = editorController.document.toDelta();
      var operations = delta.toList();
      for (var operation in operations) {
        if (operation.key == "insert") {
          if (operation.data is Map) {
            var m = operation.data as Map;
            var value = m["mentionUser"];
            if (StringUtil.isNotBlank(value)) {
              mentionUserMap[value] = 1;
            }
          }
        }
      }

      List<EditorNotifyItem> needDeleds = [];
      for (var item in editorNotifyItems) {
        var exist = mentionUserMap.remove(item.pubkey);
        if (exist == null) {
          updated = true;
          needDeleds.add(item);
        }
      }
      editorNotifyItems.removeWhere((element) => needDeleds.contains(element));

      if (mentionUserMap.isNotEmpty) {
        var entries = mentionUserMap.entries;
        for (var entry in entries) {
          updated = true;
          editorNotifyItems.add(EditorNotifyItem(pubkey: entry.key));
        }
      }

      if (updated) updateUI();
    });
  }

  Future<void> documentSave() async {
    final cancelFunc = BotToast.showLoading();
    try {
      final event = await doDocumentSave();
      if (!mounted) return;
      if (event == null) {
        BotToast.showText(text: S.of(context).Send_fail);
        return;
      }
      RouterUtil.back(context, event);
    } finally {
      cancelFunc.call();
    }
  }

  @override
  BuildContext getContext() => context;

  @override
  void updateUI() => setState(() {});

  @override
  String? getPubkey() => widget.pubkey;

  @override
  List getTags() => widget.tags;

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
  bool isDM() => false;
}
