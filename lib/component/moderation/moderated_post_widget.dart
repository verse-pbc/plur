import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/generated/l10n.dart';
import 'package:nostrmo/util/theme_util.dart';
import 'package:nostrmo/component/user/simple_name_widget.dart';
import 'package:nostrmo/component/user/user_pic_widget.dart';

/// Widget that displays a placeholder for a post that has been removed by moderators
class ModeratedPostWidget extends StatelessWidget {
  final Event originalEvent;
  final Event? moderationEvent;

  const ModeratedPostWidget({
    Key? key,
    required this.originalEvent,
    this.moderationEvent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final l10n = S.of(context);
    final customColors = themeData.customColors;
    
    // Extract reason from moderation event if available
    String? removalReason;
    if (moderationEvent != null) {
      for (var tag in moderationEvent!.tags) {
        if (tag.length > 1 && tag[0] == 'reason') {
          removalReason = tag[1] as String;
          break;
        }
      }
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: Base.basePadding, 
        vertical: Base.basePaddingHalf,
      ),
      decoration: BoxDecoration(
        color: customColors.cardBgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.red.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Base.basePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info row
            Row(
              children: [
                // User profile picture
                UserPicWidget(
                  pubkey: originalEvent.pubkey,
                  width: 36,
                ),
                const SizedBox(width: 8),
                
                // User name
                Expanded(
                  child: SimpleNameWidget(
                    pubkey: originalEvent.pubkey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Removed post message
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: themeData.canvasColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.block,
                        color: Colors.red.shade400,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "This post has been removed by a community organizer",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade400,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (removalReason != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Reason: $removalReason',
                      style: TextStyle(
                        fontSize: 14,
                        color: customColors.secondaryForegroundColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Timestamp
            Container(
              margin: const EdgeInsets.only(top: 12),
              child: Text(
                DateTime.fromMillisecondsSinceEpoch(
                  originalEvent.createdAt * 1000,
                ).toString(),
                style: TextStyle(
                  fontSize: 12,
                  color: customColors.secondaryForegroundColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 