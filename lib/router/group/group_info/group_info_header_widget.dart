import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/generated/l10n.dart';
import 'package:nostrmo/util/theme_util.dart';
import '../../../component/group/group_avatar_widget.dart';

/// Displays the header of the group info screen with improved styling.
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
    final customColors = themeData.customColors;
    final localization = S.of(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        // Optional gradient background for the header
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            customColors.feedBgColor,
            customColors.appBgColor,
          ],
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 8),
          // Larger avatar with subtle border
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: customColors.accentColor.withOpacity(0.1),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: GroupAvatar(
              imageUrl: metadata.picture,
              size: 84, // Larger size for more prominence
            ),
          ),
          const SizedBox(height: 16),
          // Group name with larger text
          Text(
            metadata.name ?? metadata.groupId,
            style: TextStyle(
              fontSize: 24, // Larger font size
              fontWeight: FontWeight.bold,
              color: customColors.primaryForegroundColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          // Group status with icon
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                metadata.open ?? false ? Icons.lock_open_outlined : Icons.lock_outlined,
                size: 16,
                color: customColors.dimmedColor,
              ),
              const SizedBox(width: 4),
              Text(
                metadata.open ?? false ? localization.openGroup : localization.closedGroup,
                style: TextStyle(
                  color: customColors.dimmedColor,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: customColors.dimmedColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.people_outline,
                size: 16,
                color: customColors.dimmedColor,
              ),
              const SizedBox(width: 4),
              Text(
                memberCount == 1 
                    ? localization.groupMember(memberCount) 
                    : localization.groupMembers(memberCount),
                style: TextStyle(
                  color: customColors.dimmedColor,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
