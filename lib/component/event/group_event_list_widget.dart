import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/component/event/event_list_widget.dart';
import 'package:nostrmo/component/group/group_avatar_widget.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostrmo/provider/group_provider.dart';
import 'package:nostrmo/provider/relay_provider.dart';
import 'package:nostrmo/service/moderation_service.dart';
import 'package:nostrmo/util/app_logger.dart';
import 'package:provider/provider.dart';

/// A widget that decorates an event post with its community information
class GroupEventListWidget extends StatelessWidget {
  final Event event;
  final bool showVideo;

  const GroupEventListWidget({
    super.key,
    required this.event,
    this.showVideo = false,
  });

  @override
  Widget build(BuildContext context) {
    final groupProvider = Provider.of<GroupProvider>(context);
    final moderationService = Provider.of<ModerationService>(context, listen: true);
    final themeData = Theme.of(context);
    
    // Check if this post has been moderated/removed
    if (moderationService.isPostModerated(event.id)) {
      logger.i("MODERATION: Post ${event.id.substring(0, 8)}... is moderated, not displaying", 
          null, null, LogCategory.groups);
      
      // Return an empty container or a "content removed" widget
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: themeData.dividerColor,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.block,
              color: themeData.hintColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "This content has been removed by a community organizer",
                style: TextStyle(
                  color: themeData.hintColor,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    // Get the original EventListWidget that we'll wrap
    Widget eventWidget = EventListWidget(
      event: event, 
      showVideo: showVideo,
    );
    
    // Extract group ID from the event
    String? groupId;
    String? host;
    for (var tag in event.tags) {
      if (tag is List && tag.isNotEmpty && tag.length > 1) {
        if (tag[0] == "h") {
          groupId = tag[1];
          break;
        }
      }
    }

    if (groupId == null) {
      // Fallback if no group ID is found
      return eventWidget;
    }

    // Create GroupIdentifier - try to find host from relay tags
    for (var tag in event.tags) {
      if (tag is List && tag.isNotEmpty && tag.length > 1) {
        if (tag[0] == "relay") {
          host = tag[1];
          break;
        }
      }
    }
    
    // Use default relay if no relay tag was found
    final relay = host ?? RelayProvider.defaultGroupsRelayAddress;
    final groupIdentifier = GroupIdentifier(relay, groupId);
    
    // Get group metadata from provider
    final metadata = groupProvider.getMetadata(groupIdentifier);
    final groupName = metadata?.name ?? "Unknown Community";

    // Add community badge to the event widget
    return Stack(
      children: [
        // Original event content
        eventWidget,
        
        // Community badge
        Positioned(
          top: 38, // Position below the relative date widget
          right: 12,
          child: InkWell(
            onTap: () {
              Navigator.pushNamed(
                context, 
                RouterPath.groupDetail, 
                arguments: groupIdentifier,
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: themeData.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: themeData.dividerColor.withAlpha(77),
                  width: 0.5, 
                ),
                boxShadow: [
                  BoxShadow(
                    color: themeData.shadowColor.withAlpha(26),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Small group avatar
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: GroupAvatar(
                      imageUrl: metadata?.picture,
                      size: 14,
                      borderWidth: 0.5,
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Group name
                  Flexible(
                    child: Text(
                      groupName,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: themeData.colorScheme.onSurface.withAlpha(204),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}