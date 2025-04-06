import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/router/group/create_community_widget.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:nostrmo/util/theme_util.dart';
import 'package:nostrmo/router/group/invite_people_widget.dart';
import 'package:nostrmo/provider/list_provider.dart';
import 'package:provider/provider.dart';

class CreateCommunityDialog extends StatefulWidget {
  const CreateCommunityDialog({super.key});

  static Future<void> show(BuildContext context) async {
    await showDialog<void>(
      context: context,
      useRootNavigator: false,
      barrierDismissible: false, // Prevent accidental dismissal during loading
      builder: (_) {
        return const CreateCommunityDialog();
      },
    );
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
    
    return PopScope(
      canPop: !_isCreating, // Prevent back button during creation
      child: Scaffold(
        backgroundColor: ThemeUtil.getDialogCoverColor(themeData),
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            // Background dismiss area (only when not creating)
            GestureDetector(
              onTap: _isCreating ? null : () => RouterUtil.back(context),
              child: Container(
                color: Colors.black54,
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
                    color: themeData.brightness == Brightness.dark 
                        ? themeData.colorScheme.surface 
                        : Colors.white,
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
                                  RouterUtil.back(context);
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
                color: Colors.black.withAlpha(100),
                child: const Center(
                  child: CircularProgressIndicator(),
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
