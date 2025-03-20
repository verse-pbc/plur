import 'package:flutter/material.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/generated/l10n.dart';
import 'package:nostrmo/router/edit/editor_notify_item_widget.dart';

/// The tags that are used to notify the users.
class NotifyTagsWidget extends StatelessWidget {
  final List<EditorNotifyItem>? notifyItems;
  final List<EditorNotifyItem> editorNotifyItems;

  const NotifyTagsWidget({
    super.key,
    required this.notifyItems,
    required this.editorNotifyItems,
  });

  @override
  Widget build(BuildContext context) {
    if ((notifyItems == null || notifyItems!.isEmpty) &&
        editorNotifyItems.isEmpty) {
      return const SizedBox.shrink();
    }

    final List<Widget> tagPsWidgets = [Text("${S.of(context).Notify}:")];

    if (notifyItems != null) {
      for (var item in notifyItems!) {
        tagPsWidgets.add(EditorNotifyItemWidget(item: item));
      }
    }

    for (var editorNotifyItem in editorNotifyItems) {
      var exist = notifyItems?.any((element) => element.pubkey == editorNotifyItem.pubkey) ?? false;
      if (!exist) {
        tagPsWidgets.add(EditorNotifyItemWidget(item: editorNotifyItem));
      }
    }

    return Container(
      padding: const EdgeInsets.only(
        left: Base.basePadding,
        right: Base.basePadding,
      ),
      margin: const EdgeInsets.only(bottom: Base.basePaddingHalf),
      width: double.maxFinite,
      child: Wrap(
        spacing: Base.basePaddingHalf,
        runSpacing: Base.basePaddingHalf,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: tagPsWidgets,
      ),
    );
  }
}
