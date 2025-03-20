import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nostrmo/router/edit/community_tag_widget.dart';
import 'package:nostrmo/router/edit/notify_tags_widget.dart';
import 'package:nostrmo/router/edit/editor_notify_item_widget.dart';

class EditorHeaderData {
  final DateTime? publishAt;
  final List<dynamic> tags;
  final List<EditorNotifyItem>? notifyItems;
  final List<EditorNotifyItem> editorNotifyItems;
  final bool isLongForm;

  const EditorHeaderData({
    this.publishAt,
    this.tags = const [],
    this.notifyItems,
    this.editorNotifyItems = const [],
    this.isLongForm = false,
  });
}

/// The header of the text editor that displays the community tags and notify tags.
class EditorHeader extends StatelessWidget {
  final EditorHeaderData data;
  final VoidCallback onTimeSelected;
  final WidgetBuilder titleBuilder;
  final WidgetBuilder longFormImageBuilder;
  final WidgetBuilder summaryBuilder;

  const EditorHeader({
    super.key,
    required this.data,
    required this.onTimeSelected,
    required this.titleBuilder,
    required this.longFormImageBuilder,
    required this.summaryBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CommunityTagWidget(tags: data.tags),
        NotifyTagsWidget(
          notifyItems: data.notifyItems,
          editorNotifyItems: data.editorNotifyItems,
        ),
        if (data.isLongForm) ...[
          titleBuilder(context),
          longFormImageBuilder(context),
          summaryBuilder(context),
        ],
        if (data.publishAt != null) _scheduledTime(context),
      ],
    );
  }

  Widget _scheduledTime(BuildContext context) {
    return GestureDetector(
      onTap: onTimeSelected,
      behavior: HitTestBehavior.translucent,
      child: Container(
        margin: const EdgeInsets.only(left: 10, bottom: 8),
        child: Row(
          children: [
            const Icon(Icons.timer_outlined),
            Container(
              margin: const EdgeInsets.only(left: 4),
              child: Text(
                DateFormat("yyyy-MM-dd HH:mm").format(data.publishAt!),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
