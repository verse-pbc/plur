import 'package:flutter/material.dart';
import 'package:nostrmo/component/info_message_widget.dart';
import 'package:nostrmo/generated/l10n.dart';

class EditorFooter extends StatelessWidget {
  final bool hasMedia;
  final Widget editorButtons;
  final Widget? emojiSelector;
  final Widget? emojiListsWidget;

  const EditorFooter({
    super.key,
    required this.hasMedia,
    required this.editorButtons,
    this.emojiSelector,
    this.emojiListsWidget,
  });

  @override
  Widget build(BuildContext context) {
    final localization = S.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasMedia)
          InfoMessageWidget(
            icon: Icons.info,
            message: localization.All_media_public,
          ),
        editorButtons,
        if (emojiSelector != null) emojiSelector!,
        if (emojiListsWidget != null) emojiListsWidget!,
      ],
    );
  }
}
