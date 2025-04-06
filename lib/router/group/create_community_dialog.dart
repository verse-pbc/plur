import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/consts/colors.dart';
import 'package:nostrmo/router/group/create_community_widget.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:nostrmo/util/theme_util.dart';
import 'package:nostrmo/router/group/invite_people_widget.dart';
import 'package:nostrmo/provider/list_provider.dart';
import 'package:provider/provider.dart';

class CreateCommunityDialog extends StatefulWidget {
  const CreateCommunityDialog({super.key});

  // This dialog MUST be properly themed to match the app
  static OverlayEntry? _overlayEntry;

  static void show(BuildContext context) {
    if (_overlayEntry != null) {
      // Avoid creating multiple overlays
      return;
    }

    // Create an overlay entry that will be directly inserted into the app's main context
    _overlayEntry = OverlayEntry(
      builder: (context) => const CreateCommunityDialog(),
    );

    // Insert the overlay into the app
    Overlay.of(context).insert(_overlayEntry!);
  }

  static void hide() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
  }

  @override
  State<CreateCommunityDialog> createState() => _CreateCommunityDialogState();
}

class _CreateCommunityDialogState extends State<CreateCommunityDialog> {
  bool _showInviteCommunity = false;
  String? _communityInviteLink;
  GroupIdentifier? _groupIdentifier;
  bool _isCreating = false;

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final maxWidth = size.width > 600 ? 500.0 : size.width * 0.9;
    final brightness = themeData.brightness;
    
    return Theme(
      // Force dark theme
      data: ThemeData.dark().copyWith(
        colorScheme: brightness == Brightness.dark
            ? themeData.colorScheme
            : ThemeData.dark().colorScheme,
        cardColor: brightness == Brightness.dark
            ? themeData.cardColor
            : const Color(0xFF333333),
        primaryColor: themeData.primaryColor,
      ),
      child: Scaffold(
        // Use dark overlay
        backgroundColor: Colors.black87,
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            // Background dismiss area (only when not creating)
            GestureDetector(
              onTap: _isCreating ? null : () => CreateCommunityDialog.hide(),
              child: Container(
                color: Colors.transparent,
              ),
            ),
            
            // Main content
            Center(
              child: SingleChildScrollView(
                child: Container(
                  width: maxWidth,
                  margin: const EdgeInsets.symmetric(vertical: 40),
                  child: Card(
                    elevation: 8,
                    // Use theme's card color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header with close button
                          if (!_isCreating)
                            Align(
                              alignment: Alignment.topRight,
                              child: IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  CreateCommunityDialog.hide();
                                },
                                tooltip: 'Close',
                                iconSize: 24,
                              ),
                            ),
                            
                          // Content based on state
                          if (!_showInviteCommunity)
                            CreateCommunityWidget(
                              onCreateCommunity: (name) {
                                setState(() {
                                  _isCreating = true;
                                });
                                _onCreateCommunity(name);
                              }
                            ),
                          if (_showInviteCommunity)
                            InvitePeopleWidget(
                              shareableLink: _communityInviteLink ?? '',
                              groupIdentifier: _groupIdentifier!,
                              showCreatePostButton: true,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            // Full-screen loading overlay (optional, for very long operations)
            if (_isCreating && !_showInviteCommunity)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: Center(
                  child: CircularProgressIndicator(
                    color: themeData.primaryColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _onCreateCommunity(String communityName) async {
    final listProvider = Provider.of<ListProvider>(context, listen: false);
    
    try {
      final groupDetails =
          await listProvider.createGroupAndGenerateInvite(communityName);

      if (mounted) {
        setState(() {
          _communityInviteLink = groupDetails.$1;
          _groupIdentifier = groupDetails.$2;
          _showInviteCommunity = true;
          _isCreating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
        // Could add error handling here if desired
      }
    }
  }
}
