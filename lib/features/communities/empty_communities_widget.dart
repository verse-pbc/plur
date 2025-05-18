import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/features/create_community/create_community_dialog.dart';
import 'package:nostrmo/router/group/join_community_widget.dart';
import 'package:nostrmo/util/community_join_util.dart';
import 'package:nostrmo/theme/app_colors.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/provider/user_provider.dart';
import 'package:provider/provider.dart';
import '../../generated/l10n.dart';
import '../../data/user.dart';

/// A widget that displays options when no communities are available
/// Provides options to create, join, or search for communities
class EmptyCommunitiesWidget extends StatelessWidget {
  const EmptyCommunitiesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = S.of(context);
    final pubkey = nostr!.publicKey;
    final userProvider = Provider.of<UserProvider>(context);
    
    return Container(
      color: colors.background,
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            // Remove card, directly show the content
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title - changed to Welcome and centered with username
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Selector<UserProvider, User?>(
                      builder: (context, user, child) {
                        String displayName = "";
                        
                        if (user != null) {
                          if (user.displayName != null && user.displayName!.isNotEmpty) {
                            displayName = user.displayName!;
                          } else if (user.name != null && user.name!.isNotEmpty) {
                            displayName = user.name!;
                          }
                        }
                        
                        if (displayName.isEmpty) {
                          displayName = Nip19.encodeSimplePubKey(pubkey);
                        }
                        
                        return Text(
                          "Welcome $displayName!",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: colors.primaryText,
                          ),
                        );
                      },
                      selector: (_, provider) {
                        return provider.getUser(pubkey);
                      },
                    ),
                  ),
                ),
                    
                // Create new community option
                _buildOptionTile(
                  context: context,
                  icon: Icons.add_circle_outline,
                  title: l10n.createGroup,
                  subtitle: "Create a new community for your interests",
                  onTap: () {
                    CreateCommunityDialog.show(context);
                  },
                ),
                
                const SizedBox(height: 12),
                Divider(color: colors.paneSeparator),
                const SizedBox(height: 12),
                
                // Join test community option
                _buildOptionTile(
                  context: context,
                  icon: Icons.people_outline,
                  title: "Join Plur Test Users",
                  subtitle: "Join the official Plur test community",
                  onTap: () {
                    _joinTestUsersGroup(context);
                  },
                ),
                
                const SizedBox(height: 12),
                Divider(color: colors.paneSeparator),
                const SizedBox(height: 12),
                
                // Join with invite link option
                _buildOptionTile(
                  context: context,
                  icon: Icons.link,
                  title: l10n.joinGroup,
                  subtitle: l10n.haveInviteLink,
                  onTap: () {
                    // Navigate to join community page
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => JoinCommunityWidget(
                          onJoinCommunity: (String link) {
                            final success = CommunityJoinUtil.parseAndJoinCommunity(context, link);
                            if (success) {
                              Navigator.of(context).pop();
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 12),
                Divider(color: colors.paneSeparator),
                const SizedBox(height: 12),
                
                // Search for communities
                _buildOptionTile(
                  context: context,
                  icon: Icons.search,
                  title: "Find Communities",
                  subtitle: "Search for public communities",
                  enabled: false,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Public community search coming soon!")),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // Helper to build a consistent option tile
  Widget _buildOptionTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    final colors = context.colors;
    final color = enabled ? colors.accent : colors.secondaryText.withAlpha(153);
    
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: enabled ? colors.primaryText : colors.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.secondaryText,
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
  
  // Joins the Plur Test Users community group
  void _joinTestUsersGroup(BuildContext context) {
    const String testUsersGroupLink = "plur://join-community?group-id=R6PCSLSWB45E&code=Z2PWD5ML";
    
    // Show confirmation dialog first
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        final colors = context.colors;
        
        return AlertDialog(
          backgroundColor: colors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            "Join Plur Test Users Group",
            style: TextStyle(
              color: colors.primaryText,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            "Would you like to join the Plur Test Users community? "
            "This is a public group for testing features and connecting with other users.",
            style: TextStyle(
              color: colors.primaryText,
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: Text(
                "Cancel",
                style: TextStyle(
                  color: colors.secondaryText,
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                
                // Show loading indicator
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text("Joining Plur Test Users group..."),
                    duration: const Duration(seconds: 1),
                    backgroundColor: colors.primary.withAlpha(230),
                  ),
                );
                
                // Attempt to join the group
                bool success = CommunityJoinUtil.parseAndJoinCommunity(context, testUsersGroupLink);
                
                if (!success && context.mounted) {
                  // Show error message if joining failed
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Failed to join test users group. Please try again later."),
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                "Join Group",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}