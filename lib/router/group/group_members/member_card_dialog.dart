import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/component/user/user_pic_widget.dart';
import 'package:nostrmo/component/group/admin_tag_widget.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostrmo/generated/l10n.dart';
import 'package:nostrmo/provider/dm_provider.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:nostrmo/util/theme_util.dart';
import 'package:provider/provider.dart';
import 'package:nostrmo/provider/user_provider.dart';

class MemberCardDialog extends StatelessWidget {
  final String pubkey;
  final GroupIdentifier groupId;
  final bool isAdmin;
  final BuildContext? parentContext;

  const MemberCardDialog({
    Key? key,
    required this.pubkey,
    required this.groupId,
    this.isAdmin = false,
    this.parentContext,
  }) : super(key: key);

  static Future<void> show(
    BuildContext context, {
    required String pubkey,
    required GroupIdentifier groupId,
    bool isAdmin = false,
  }) async {
    // Store the original context for proper navigation after dialog is closed
    final originalContext = context;
    
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return MemberCardDialog(
          pubkey: pubkey,
          groupId: groupId,
          isAdmin: isAdmin,
          parentContext: originalContext,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final customColors = themeData.customColors;
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.getUser(pubkey);
    final localization = S.of(context);

    // Get display name or fallback to short pubkey
    final displayName = user?.displayName ?? user?.name ?? Nip19.encodeSimplePubKey(pubkey);
    
    // Get NIP-05 (if available)
    final nip05 = user?.nip05;
    
    // Get about text (if available)
    final about = user?.about;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: customColors.cardBgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top section with user info
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // User avatar
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      UserPicWidget(
                        pubkey: pubkey,
                        width: 80,
                      ),
                      if (isAdmin)
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary,
                              width: 3.0,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // User name and admin badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          displayName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: customColors.primaryForegroundColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isAdmin) ...[
                        const SizedBox(width: 8),
                        const AdminTagWidget(),
                      ],
                    ],
                  ),
                  
                  // NIP05 identifier (if available)
                  if (nip05 != null && nip05.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      nip05,
                      style: TextStyle(
                        fontSize: 14,
                        color: customColors.dimmedColor,
                      ),
                    ),
                  ],
                  
                  // About text (if available)
                  if (about != null && about.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      about,
                      style: TextStyle(
                        fontSize: 14,
                        color: customColors.secondaryForegroundColor,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            
            // Action buttons
            Container(
              decoration: BoxDecoration(
                color: customColors.feedBgColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  // View profile button
                  Expanded(
                    child: _buildActionButton(
                      context: context,
                      icon: Icons.person_outline,
                      label: localization.Open_User_page,
                      onTap: () {
                        Navigator.of(context).pop(); // Close dialog
                        
                        // Use parentContext if available, otherwise use current context
                        final navigationContext = parentContext ?? context;
                        
                        // Add a small delay to ensure dialog is fully closed
                        Future.delayed(const Duration(milliseconds: 100), () {
                          try {
                            RouterUtil.router(navigationContext, RouterPath.user, pubkey);
                          } catch (e) {
                            // Show error toast if profile navigation fails
                            BotToast.showText(text: "Failed to open profile: $e");
                          }
                        });
                      },
                    ),
                  ),
                  
                  // Vertical divider between buttons
                  Container(
                    height: 40,
                    width: 1,
                    color: customColors.separatorColor,
                  ),
                  
                  // Message user button
                  Expanded(
                    child: _buildActionButton(
                      context: context,
                      icon: Icons.message_outlined,
                      label: localization.DMs,
                      onTap: () {
                        Navigator.of(context).pop(); // Close dialog
                        
                        // Use parentContext if available, otherwise use current context
                        final navigationContext = parentContext ?? context;
                        
                        // Add a small delay to ensure dialog is fully closed
                        Future.delayed(const Duration(milliseconds: 100), () {
                          try {
                            // Create a DM session and navigate to it
                            final dmProvider = Provider.of<DMProvider>(navigationContext, listen: false);
                            final dmSessionDetail = dmProvider.findOrNewADetail(pubkey);
                            
                            // Navigate to DM detail with the session
                            RouterUtil.router(
                              navigationContext,
                              RouterPath.dmDetail,
                              dmSessionDetail,
                            );
                          } catch (e) {
                            // Show error toast if DM navigation fails
                            BotToast.showText(text: "Failed to open conversation: $e");
                          }
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final themeData = Theme.of(context);
    final customColors = themeData.customColors;
    
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: customColors.accentColor,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: customColors.accentColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}