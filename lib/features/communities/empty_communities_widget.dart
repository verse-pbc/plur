import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/features/create_community/create_community_dialog.dart';
import 'package:nostrmo/router/group/join_community_widget.dart';
import 'package:nostrmo/util/community_join_util.dart';
import 'package:nostrmo/theme/app_colors.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/provider/user_provider.dart';
import 'package:provider/provider.dart';
import '../../data/user.dart';

/// A widget that displays options when no communities are available
/// Provides options to create, join, or search for communities
class EmptyCommunitiesWidget extends StatelessWidget {
  const EmptyCommunitiesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final pubkey = nostr!.publicKey;
    
    return Container(
      color: colors.background,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title with padding matching login sheet
            Padding(
              padding: const EdgeInsets.fromLTRB(40, 32, 40, 32),
              child: Center(
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
                      "Welcome, $displayName!",
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
                    
            // Option tiles with proper padding
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: _buildOptionTile(
                context: context,
                icon: Icons.add_circle_outline,
                title: "Create a Community",
                subtitle: "Start your own community around a topic or activity you care about.",
                onTap: () {
                  CreateCommunityDialog.show(context);
                },
              ),
            ),
            
            const SizedBox(height: 24),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: _buildOptionTile(
                context: context,
                icon: Icons.people_outline,
                title: "Join Holis Community",
                subtitle: "Be part of our official test group and help us shape the future of Plur.",
                onTap: () {
                  _joinTestUsersGroup(context);
                },
              ),
            ),
            
            const SizedBox(height: 24),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: _buildOptionTile(
                context: context,
                icon: Icons.link,
                title: "Join with an Invite",
                subtitle: "Got an invite link? Use it here to join a private group instantly.",
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
            ),
            
            const SizedBox(height: 24),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: _buildOptionTile(
                context: context,
                icon: Icons.search,
                title: "Find Communities",
                subtitle: "Explore and join open communities that match your interests.",
                enabled: false,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Public community search coming soon!")),
                  );
                },
              ),
            ),
            const SizedBox(height: 48), // Bottom padding matching login sheet
          ],
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final color = enabled ? colors.accent : colors.secondaryText.withAlpha(153);
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E2936) : null,
        border: Border.all(
          color: colors.paneSeparator,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: enabled ? colors.primaryText : colors.secondaryText,
                ),
              ),
              const SizedBox(height: 8),
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
            "Join Holis Community",
            style: TextStyle(
              color: colors.primaryText,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            "Would you like to join the Holis Community? "
            "This is our official test group where you can help us shape the future of Plur.",
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
                    content: const Text("Joining Holis Community..."),
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
                      content: Text("Failed to join Holis Community. Please try again later."),
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