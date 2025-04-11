import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/generated/l10n.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:nostrmo/util/theme_util.dart';
import 'package:nostrmo/util/string_code_generator.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:provider/provider.dart';
import 'package:nostrmo/provider/list_provider.dart';
import 'package:nostrmo/component/appbar_back_btn_widget.dart';
import 'package:nostrmo/component/appbar_bottom_border.dart';

/// Widget for inviting people to a group
class InvitePeopleWidget extends StatefulWidget {
  final String? shareableLink;
  final GroupIdentifier? groupIdentifier;
  final bool showCreatePostButton;

  const InvitePeopleWidget({
    super.key,
    this.shareableLink,
    this.groupIdentifier,
    this.showCreatePostButton = false,
  });

  @override
  State<InvitePeopleWidget> createState() => _InvitePeopleWidgetState();
}

class _InvitePeopleWidgetState extends State<InvitePeopleWidget> {
  late String inviteCode;
  String inviteLink = ''; // Initialize with empty string instead of late
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    inviteCode = StringCodeGenerator.generateInviteCode();
    
    // Use the provided shareableLink if available
    if (widget.shareableLink != null && widget.shareableLink!.isNotEmpty) {
      inviteLink = widget.shareableLink!;
      isLoading = false;
    }
    
    // Schedule async initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeInviteLink();
    });
  }
  
  // Separate method to ensure invite link is properly initialized
  void _initializeInviteLink() {
    if (mounted && (inviteLink.isEmpty || isLoading)) {
      final arg = widget.groupIdentifier ?? RouterUtil.routerArgs(context);
      if (arg != null && arg is GroupIdentifier) {
        try {
          final listProvider = Provider.of<ListProvider>(context, listen: false);
          final newInviteLink = listProvider.createInviteLink(arg, inviteCode);
          
          if (mounted) {
            setState(() {
              inviteLink = newInviteLink;
              isLoading = false;
            });
          }
        } catch (e) {
          // Handle error case
          if (mounted) {
            setState(() {
              isLoading = false;
            });
            BotToast.showText(text: "Failed to create invite link: $e");
          }
        }
      }
    }
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Initialization is now handled in initState with _initializeInviteLink
    // This method is kept for lifecycle compliance but doesn't duplicate work
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final customColors = themeData.customColors;
    final localization = S.of(context);
    
    final groupId = widget.groupIdentifier ?? RouterUtil.routerArgs(context);
    if (groupId == null || groupId is! GroupIdentifier) {
      RouterUtil.back(context);
      return Container();
    }
    
    // GroupIdentifier is available

    return Scaffold(
      appBar: AppBar(
        title: Text(
          localization.Invite,
          style: TextStyle(
            color: customColors.primaryForegroundColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: const AppbarBackBtnWidget(),
        bottom: const AppBarBottomBorder(),
      ),
      body: SafeArea(
        child: isLoading 
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localization.Invite_people_to_join,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: customColors.primaryForegroundColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity, // Ensure container has width
                    constraints: const BoxConstraints(minHeight: 56), // Ensure minimum height
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: customColors.feedBgColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            inviteLink.isNotEmpty ? inviteLink : localization.Loading,
                            style: TextStyle(
                              fontSize: 14,
                              color: customColors.primaryForegroundColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                        const SizedBox(width: 8), // Add spacing
                        IconButton(
                          icon: Icon(
                            Icons.copy,
                            color: customColors.accentColor,
                          ),
                          onPressed: inviteLink.isNotEmpty ? () {
                            Clipboard.setData(ClipboardData(text: inviteLink));
                            BotToast.showText(
                              text: localization.Copy_success,
                            );
                          } : null, // Disable if no link
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    localization.Share_invite_description,
                    style: TextStyle(
                      fontSize: 14,
                      color: customColors.secondaryForegroundColor,
                    ),
                  ),
                  
                  // Add Create Post button if requested
                  if (widget.showCreatePostButton) ...[
                    const SizedBox(height: 40),
                    Center(
                      child: SizedBox(
                        width: double.infinity, // Ensure the widget has a defined width
                        child: ElevatedButton(
                          onPressed: () {
                            RouterUtil.back(context);
                            RouterUtil.router(context, RouterPath.groupDetail, groupId);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeData.primaryColor,
                            foregroundColor: customColors.buttonTextColor,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Create your first post',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
      ),
    );
  }
}