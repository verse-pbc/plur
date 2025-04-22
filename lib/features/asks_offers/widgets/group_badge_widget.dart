import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Consumer;
import 'package:nostr_sdk/nip29/group_identifier.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostrmo/data/group_metadata_repository.dart';
import 'package:nostrmo/provider/group_provider.dart';
import 'package:provider/provider.dart' as provider_pkg;
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
    
    // Directly access the group provider for immediate group data without loading state
    // access via Provider.of since it's not a Riverpod provider
    final groupProvider = provider_pkg.Provider.of<GroupProvider>(context, listen: false);
    final metadata = groupProvider.getMetadata(groupIdentifier);
    
    // If group metadata is available immediately from the provider's cache, use it
    if (metadata != null) {
      final groupName = metadata.displayName ?? metadata.name ?? 'Community';
      return _buildBadge(context, groupIdentifier, groupName, themeData);
    }
    
    // Otherwise, watch the async provider with proper loading/error states
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
            
            return _buildBadgeContent(themeData, groupName);
          },
          loading: () => _buildBadgeContent(themeData, id), // Show ID instead of "Loading..."
          error: (_, __) => _buildBadgeContent(themeData, 'Community'),
        ),
      ),
    );
  }
  
  Widget _buildBadge(BuildContext context, GroupIdentifier groupIdentifier, String groupName, ThemeData themeData) {
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
        child: _buildBadgeContent(themeData, groupName),
      ),
    );
  }
  
  Widget _buildBadgeContent(ThemeData themeData, String text) {
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
            text,
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
  }
}