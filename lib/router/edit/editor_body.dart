import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:nostrmo/nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/component/editor/lnbc_embed_builder.dart';
import 'package:nostrmo/component/editor/mention_event_embed_builder.dart';
import 'package:nostrmo/component/editor/mention_user_embed_builder.dart';
import 'package:nostrmo/component/editor/pic_embed_builder.dart';
import 'package:nostrmo/component/editor/tag_embed_builder.dart';
import 'package:nostrmo/component/editor/video_embed_builder.dart';
import 'package:nostrmo/component/editor/custom_emoji_embed_builder.dart';
import 'package:nostrmo/component/editor/poll_input_widget.dart';
import 'package:nostrmo/component/editor/zap_goal_input_widget.dart';
import 'package:nostrmo/component/editor/zap_split_input_widget.dart';
import 'package:nostrmo/consts/base.dart';

/// The body of the text editor that
class EditorBody extends StatelessWidget {
  final QuillController editorController;
  final FocusNode focusNode;
  final String placeholder;
  final bool inputPoll;
  final bool inputZapGoal;
  final bool openZapSplit;
  final PollInputController? pollInputController;
  final ZapGoalInputController? zapGoalInputController;
  final List<EventZapInfo>? eventZapInfos;

  const EditorBody({
    super.key,
    required this.editorController,
    required this.focusNode,
    required this.placeholder,
    this.inputPoll = false,
    this.inputZapGoal = false,
    this.openZapSplit = false,
    this.pollInputController,
    this.zapGoalInputController,
    this.eventZapInfos,
  });

  @override
  Widget build(BuildContext context) {
    final Widget quillWidget = QuillEditor(
      controller: editorController,
      configurations: QuillEditorConfigurations(
        placeholder: placeholder,
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
      ),
      scrollController: ScrollController(),
      focusNode: focusNode,
    );

    final List<Widget> editorList = [
      Container(
        margin: const EdgeInsets.only(bottom: Base.basePadding),
        child: quillWidget,
      ),
    ];

    if (inputPoll && pollInputController != null) {
      editorList.add(PollInputWidget(
        pollInputController: pollInputController!,
      ));
    }

    if (inputZapGoal && zapGoalInputController != null) {
      editorList.add(ZapGoalInputWidget(
        zapGoalInputController: zapGoalInputController!,
      ));
    }

    if (openZapSplit && eventZapInfos != null) {
      editorList.add(ZapSplitInputWidget(eventZapInfos!));
    }

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => focusNode.requestFocus(),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...editorList,
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}
