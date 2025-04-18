import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nostr_sdk/nip29/group_identifier.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostrmo/data/group_metadata_repository.dart';
import 'package:nostrmo/util/router_util.dart';

/// A widget that displays a badge for a group with its name
class GroupBadgeWidget extends ConsumerWidget {
  final String groupId;
  final double fontSize;
  final Color? backgroundColor;
  final Color? textColor;
  final VoidCallback? onTap;

  const GroupBadgeWidget({
    required this.groupId,
    this.fontSize = 12.0,
    this.backgroundColor,
    this.textColor,
    this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Parse the groupId into a GroupIdentifier object
    String host;
    String id;
    
    if (groupId.contains(':')) {
      final parts = groupId.split(':');
      host = parts[0];
      id = parts[1];
    } else {
      // Fallback if no host in the format
      host = 'relay';
      id = groupId;
    }
    
    final groupIdentifier = GroupIdentifier(host, id);
    final themeData = Theme.of(context);
    
    return GestureDetector(
      onTap: onTap ?? () {
        // Navigate to group detail screen
        RouterUtil.router(context, RouterPath.groupDetail, groupIdentifier);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: backgroundColor ?? themeData.colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: ref.watch(groupMetadataProvider(groupIdentifier)).when(
          data: (metadata) {
            final groupName = metadata?.displayName ?? 
                             metadata?.name ?? 
                             'Community';
            
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.group_rounded,
                  size: fontSize + 2,
                  color: textColor ?? themeData.colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    groupName,
                    style: TextStyle(
                      fontSize: fontSize,
                      color: textColor ?? themeData.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            );
          },
          loading: () => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.group_rounded,
                size: fontSize + 2,
                color: textColor ?? themeData.colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Text(
                'Loading...',
                style: TextStyle(
                  fontSize: fontSize,
                  color: textColor ?? themeData.colorScheme.primary,
                ),
              ),
            ],
          ),
          error: (_, __) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.group_rounded,
                size: fontSize + 2,
                color: textColor ?? themeData.colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Text(
                'Community',
                style: TextStyle(
                  fontSize: fontSize,
                  color: textColor ?? themeData.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}