import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/generated/l10n.dart';
import 'package:nostrmo/util/theme_util.dart';
import '../../../component/group/group_avatar_widget.dart';

/// Displays the header of the group info screen.
class GroupInfoHeaderWidget extends StatelessWidget {
  final GroupMetadata metadata;
  final int memberCount;

  const GroupInfoHeaderWidget({
    super.key,
    required this.metadata,
    required this.memberCount,
  });

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final localization = S.of(context);

    return Column(
      children: [
        const SizedBox(height: 20),
        GroupAvatar(imageUrl: metadata.picture),
        const SizedBox(height: 16),
        Text(
          metadata.name ?? metadata.groupId,
          style: themeData.textTheme.headlineSmall?.copyWith(
            color: themeData.customColors.primaryForegroundColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _groupStatusText(localization),
          style: themeData.textTheme.bodyMedium?.copyWith(
            color: themeData.customColors.dimmedColor,
          ),
        ),
        const SizedBox(height: 25),
      ],
    );
  }

  String _groupStatusText(S localization) =>
      '${metadata.open ?? false ? localization.Open_group : localization.Closed_group} • ${memberCount == 1 ? localization.Group_member(memberCount) : localization.Group_members(memberCount)}';
}
