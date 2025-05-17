import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/generated/l10n.dart';
import 'package:nostrmo/util/theme_util.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:nostrmo/provider/list_provider.dart';
import 'package:nostrmo/util/community_join_util.dart';
import 'package:nostrmo/util/string_code_generator.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

/// Widget to display a group invite received in a DM
class ContentGroupInviteWidget extends StatefulWidget {
  final Map<String, dynamic> inviteData;
  
  const ContentGroupInviteWidget({
    super.key,
    required this.inviteData,
  });
  
  @override
  State<ContentGroupInviteWidget> createState() => _ContentGroupInviteWidgetState();
}

class _ContentGroupInviteWidgetState extends State<ContentGroupInviteWidget> {
  final _log = Logger('ContentGroupInviteWidget');
  bool _joining = false;
  bool _joined = false;
  
  // Extract invite details from the invite data
  Map<String, dynamic> get _invite => widget.inviteData['invite'] as Map<String, dynamic>;
  
  String get groupId => _invite['group_id'] as String;
  String get inviteCode => _invite['code'] as String;  
  String get relay => _invite['relay'] as String;
  String get groupName => _invite['group_name'] as String;
  String? get avatar => _invite['avatar'] as String?;
  String get role => _invite['role'] as String? ?? 'member';
  int get expiresAt => _invite['expires_at'] as int? ?? 0;
  bool get isReusable => _invite['reusable'] as bool? ?? true;
  
  bool get isExpired {
    if (expiresAt <= 0) return false;
    return DateTime.now().millisecondsSinceEpoch ~/ 1000 > expiresAt;
  }
  
  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final customColors = themeData.customColors;
    final localization = S.of(context);
    
    if (_joined) {
      return _buildJoinedCard(customColors, localization);
    }
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: customColors.feedBgColor,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                // Group avatar
                if (avatar != null && avatar!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.network(
                      avatar!,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildAvatarFallback(customColors);
                      },
                    ),
                  )
                else
                  _buildAvatarFallback(customColors),
                
                const SizedBox(width: 16),
                
                // Group info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        groupName,
                        style: TextStyle(
                          color: customColors.primaryForegroundColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        localization.communityInvite,
                        style: TextStyle(
                          color: customColors.secondaryForegroundColor,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Role and expiry info
            Row(
              children: [
                _buildInfoChip(
                  customColors,
                  Icons.person,
                  role == 'admin' ? localization.admin : localization.member,
                ),
                const SizedBox(width: 8),
                if (expiresAt > 0)
                  _buildInfoChip(
                    customColors,
                    Icons.timer,
                    isExpired
                        ? localization.expired
                        : _formatExpiryDate(expiresAt),
                    isError: isExpired,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Join button
            ElevatedButton(
              onPressed: isExpired || _joining ? null : _joinGroup,
              style: ElevatedButton.styleFrom(
                backgroundColor: customColors.accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                disabledBackgroundColor: customColors.disabledColor,
              ),
              child: _joining
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    )
                  : Text(
                      isExpired
                          ? localization.inviteExpired
                          : localization.joinCommunity,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
            
            // Manual link option
            if (!isExpired)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton(
                  onPressed: _copyInviteLink,
                  style: TextButton.styleFrom(
                    foregroundColor: customColors.secondaryForegroundColor,
                  ),
                  child: Text(localization.copyLink),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAvatarFallback(CustomColors customColors) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: customColors.accentColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: Text(
          groupName.isNotEmpty ? groupName[0].toUpperCase() : 'G',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
  
  Widget _buildInfoChip(
    CustomColors customColors,
    IconData icon,
    String text, {
    bool isError = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: customColors.secondaryForegroundColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isError ? Colors.red : customColors.secondaryForegroundColor,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: isError ? Colors.red : customColors.secondaryForegroundColor,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildJoinedCard(CustomColors customColors, S localization) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: customColors.feedBgColor,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                // Group avatar
                if (avatar != null && avatar!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.network(
                      avatar!,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildAvatarFallback(customColors);
                      },
                    ),
                  )
                else
                  _buildAvatarFallback(customColors),
                
                const SizedBox(width: 16),
                
                // Group info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        groupName,
                        style: TextStyle(
                          color: customColors.primaryForegroundColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 14,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            localization.joined,
                            style: const TextStyle(
                              color: Colors.green,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Open button
            OutlinedButton(
              onPressed: _openGroup,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: customColors.accentColor),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                localization.open,
                style: TextStyle(
                  color: customColors.accentColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatExpiryDate(int timestamp) {
    final expiryDate = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final now = DateTime.now();
    final difference = expiryDate.difference(now);
    
    final localization = S.of(context);
    
    if (difference.inDays > 0) {
      return '${localization.expires}: ${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${localization.expires}: ${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${localization.expires}: ${difference.inMinutes}m';
    } else {
      return localization.expiringNow;
    }
  }
  
  Future<void> _joinGroup() async {
    if (isExpired || _joining || _joined) return;
    
    // Capture BuildContext before async operation
    final BuildContext currentContext = context;
    final bool contextMounted = mounted;
    
    setState(() {
      _joining = true;
    });
    
    Function? cancelFunc;
    try {
      // Show loading with safe error handling
      cancelFunc = _safeShowLoading();
      
      // Create join parameters
      final params = JoinGroupParameters(
        host: relay,
        groupId: groupId,
        code: inviteCode,
      );
      
      // Get the list provider
      final listProvider = Provider.of<ListProvider>(currentContext, listen: false);
      
      // Log join attempt
      _log.info("Attempting to join group $groupId on relay $relay");
      
      // Try to join the group
      final joinSuccess = await listProvider.joinGroup(params, context: currentContext);
      
      // Check if widget is still mounted before updating state
      if (!contextMounted) {
        _log.warning("Widget unmounted during join operation, skipping UI updates");
        return;
      }
      
      if (joinSuccess) {
        _log.info("Successfully joined group $groupId");
        
        // Send accept event
        if (nostr != null) {
          final acceptEvent = Event(
            nostr!.publicKey,
            EventKind.groupInviteAccept,
            [
              ["d", groupId],
              ["p", nostr!.publicKey], // Add this tag to track who accepted the invite
            ],
            "",
          );
          
          // Try to send accept event to multiple relays
          List<String> relaysToTry = [
            relay, 
            RelayProvider.defaultGroupsRelayAddress
          ];
          
          for (final r in relaysToTry) {
            try {
              nostr!.sendEvent(acceptEvent, tempRelays: [r], targetRelays: [r]);
            } catch (e) {
              _log.warning("Error sending accept event to relay $r: $e");
            }
          }
        }
        
        // Update UI
        setState(() {
          _joining = false;
          _joined = true;
        });
        
        _safeShowToast(S.of(currentContext).joinSuccess);
      } else {
        _log.warning("Failed to join group $groupId");
        
        setState(() {
          _joining = false;
        });
        
        _safeShowToast(S.of(currentContext).joinFailed);
      }
    } catch (e) {
      _log.severe("Error joining group: $e");
      
      // Only update state if still mounted
      if (contextMounted) {
        setState(() {
          _joining = false;
        });
        
        _safeShowToast("${S.of(currentContext).error}: $e");
      }
    } finally {
      // Safely cancel loading indicator
      if (cancelFunc != null) {
        try {
          cancelFunc.call();
        } catch (e) {
          _log.warning("Error canceling loading indicator: $e");
        }
      }
    }
  }
  
  // Helper functions to safely show toasts and loading indicators
  void _safeShowToast(String text) {
    try {
      BotToast.showText(text: text, duration: const Duration(seconds: 2));
    } catch (e) {
      _log.warning("Error showing toast: $e");
    }
  }
  
  Function _safeShowLoading() {
    try {
      return BotToast.showLoading();
    } catch (e) {
      _log.warning("Error showing loading indicator: $e");
      // Return a no-op function
      return () {};
    }
  }
  
  void _copyInviteLink() {
    final link = "plur://join-community?group-id=$groupId&code=$inviteCode&relay=${Uri.encodeComponent(relay)}";
    
    // Copy to clipboard
    RouterUtil.copyToClipboard(link, () {
      BotToast.showText(text: S.of(context).copySuccess);
    });
  }
  
  void _openGroup() {
    // Create a GroupIdentifier from the joined group info
    final groupIdentifier = GroupIdentifier(relay, groupId);
    
    // Navigate to the group detail screen
    RouterUtil.router(context, RouterPath.groupDetail, groupIdentifier);
  }
}