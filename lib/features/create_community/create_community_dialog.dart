import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nostrmo/theme/app_colors.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:bot_toast/bot_toast.dart';

import '../../component/styled_input_field_widget.dart';
import '../../generated/l10n.dart';
import '../../data/group_metadata_repository.dart';
import '../communities/communities_controller.dart';
import 'create_community_controller.dart';
import 'create_community_widget.dart';

// Enum for tracking the dialog state - must be at top level
enum DialogState {
  nameInput,
  creating,
  inviteLink
}

class CreateCommunityDialog extends ConsumerStatefulWidget {
  const CreateCommunityDialog({super.key});

  // Method to show the content as a bottom sheet
  static Future<void> show(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withAlpha((255 * 0.5).round()),
      enableDrag: true,
      isDismissible: true,
      builder: (BuildContext context) {
        // Get responsive width values
        var screenWidth = MediaQuery.of(context).size.width;
        bool isTablet = screenWidth >= 600;
        bool isDesktop = screenWidth >= 900;
        double sheetMaxWidth = isDesktop ? 600 : (isTablet ? 600 : double.infinity);
        
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
              },
              child: Container(
                color: Colors.transparent,
                height: 100,  // Touch area above sheet
              ),
            ),
            AnimatedPadding(
              padding: MediaQuery.of(context).viewInsets,
              duration: const Duration(milliseconds: 100),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: sheetMaxWidth),
                  child: Container(
                    decoration: BoxDecoration(
                      color: context.colors.loginBackground,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: const SafeArea(
                      top: false,
                      bottom: true,
                      child: CreateCommunityDialog(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  ConsumerState<CreateCommunityDialog> createState() {
    return _CreateCommunityDialogState();
  }
}

class _CreateCommunityDialogState extends ConsumerState<CreateCommunityDialog> {
  // Current state of the dialog
  DialogState _currentState = DialogState.nameInput;
  CreateCommunityModel? _communityModel;
  
  // Controller for the invite link field
  TextEditingController? _inviteLinkController;
  
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 32, 40, 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Close button
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: colors.buttonText.withAlpha((255 * 0.1).round()),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  color: colors.buttonText,
                  size: 20,
                ),
              ),
            ),
          ),
          
          // Community icon
          Center(
            child: Image.asset(
              _getIconAssetForState(),
              width: 80,
              height: 80,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  _getIconForState(),
                  size: 80,
                  color: colors.buttonText,
                );
              },
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Content based on current state
          if (_currentState == DialogState.nameInput)
            CreateCommunityWidget(
              onCreateCommunity: (name, customInviteLink) => _onCreateCommunity(name, customInviteLink),
            )
          else if (_currentState == DialogState.creating)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_currentState == DialogState.inviteLink)
            _buildInviteLinkContent(),
        ],
      ),
    );
  }
  
  // Helper method to get the appropriate icon asset based on state
  String _getIconAssetForState() {
    switch (_currentState) {
      case DialogState.nameInput:
        return 'assets/imgs/create-community.png';
      case DialogState.creating:
        return 'assets/imgs/create-community.png';
      case DialogState.inviteLink:
        return 'assets/imgs/join-community.png';
    }
  }
  
  // Helper method to get the appropriate icon for error case
  IconData _getIconForState() {
    switch (_currentState) {
      case DialogState.nameInput:
        return Icons.people_alt_rounded;
      case DialogState.creating:
        return Icons.people_alt_rounded;
      case DialogState.inviteLink:
        return Icons.link_rounded;
    }
  }
  
  // Build the invite link content
  Widget _buildInviteLinkContent() {
    final colors = context.colors;
    final localization = S.of(context);
    
    // Get screen width for responsive design
    var screenWidth = MediaQuery.of(context).size.width;
    bool isDesktop = screenWidth >= 900;

    // Wrapper function for responsive elements
    Widget wrapResponsive(Widget child) {
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isDesktop ? 400 : 500),
          child: child,
        ),
      );
    }
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title
        wrapResponsive(
          Center(
            child: Text(
              localization.invite,
              style: TextStyle(
                fontFamily: 'SF Pro Rounded',
                color: colors.buttonText,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Description
        wrapResponsive(
          Text(
            localization.invitePeopleToJoin,
            style: TextStyle(
              fontFamily: 'SF Pro Rounded',
              color: colors.secondaryText,
              fontSize: 16,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Invite link field
        wrapResponsive(
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: StyledInputFieldWidget(
                  controller: _inviteLinkController ?? TextEditingController(),
                  hintText: "Invite link",
                  // Make the field read-only but still selectable
                  onChanged: null,
                  // Add a key for testing
                  fieldKey: const Key('invite_link_field'),
                  suffixIcon: IconButton(
                    icon: Icon(
                      Icons.copy_rounded,
                      color: colors.accent,
                      size: 22,
                    ),
                    onPressed: () {
                      if (_communityModel != null) {
                        Clipboard.setData(ClipboardData(text: _communityModel!.$2));
                        BotToast.showText(text: localization.copySuccess);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Description text
        wrapResponsive(
          Text(
            localization.shareInviteDescription,
            style: TextStyle(
              fontFamily: 'SF Pro Rounded',
              color: colors.secondaryText,
              fontSize: 14,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        
        const SizedBox(height: 32),
        
        // Create first post button
        wrapResponsive(
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: () {
                if (_communityModel != null) {
                  // Close the dialog
                  Navigator.of(context).pop();
                  
                  // Navigate to the group detail
                  RouterUtil.router(context, RouterPath.groupDetail, _communityModel!.$1);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: colors.accent,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: colors.accent.withAlpha(77),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  'Create your first post',
                  style: TextStyle(
                    fontFamily: 'SF Pro Rounded',
                    color: colors.buttonText,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _onCreateCommunity(String communityName, String? customInviteLink) async {
    // Update state to show loading spinner
    setState(() {
      _currentState = DialogState.creating;
    });
    
    log("🔄 Starting community creation: name='$communityName', customLink='$customInviteLink'", name: 'CreateCommunityDialog');
    
    final controller = ref.read(createCommunityControllerProvider.notifier);
    final result = await controller.createCommunity(
      communityName, 
      customInviteCode: customInviteLink
    );
    
    if (!mounted) return;
    
    log("✅ Community creation result: success=$result", name: 'CreateCommunityDialog');
    
    if (result) {
      // Get the async value to check for errors
      final asyncValue = ref.read(createCommunityControllerProvider);
      log("✅ AsyncValue state: $asyncValue", name: 'CreateCommunityDialog');
      
      // Get the community model from the controller BEFORE doing any refresh operations
      final model = asyncValue.value;
      
      log("✅ Model after creation: $model", name: 'CreateCommunityDialog');
      
      if (model != null) {
        // Log the community creation for debugging
        log("🎉 Community created successfully: ${model.$1.groupId} with invite link: ${model.$2}", 
          name: 'CreateCommunityDialog');
        
        // Store the model first before any refresh operations that might reset the provider state
        final storedModel = model;
        
        // Store the model and update state to show invite link
        setState(() {
          _communityModel = storedModel;
          _currentState = DialogState.inviteLink;
          
          // Initialize the controller with the invite link
          if (_inviteLinkController != null) {
            _inviteLinkController!.dispose();
          }
          _inviteLinkController = TextEditingController(text: storedModel.$2);
        });
        
        // Only do minimal refresh operations that won't interfere with the dialog flow
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            // Refresh only the metadata for this specific community
            ref.refresh(groupMetadataProvider(storedModel.$1));
            ref.refresh(cachedGroupMetadataProvider(storedModel.$1));
          }
        });
        
        // Refresh the communities list after a longer delay to show the new community
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            ref.refresh(communitiesControllerProvider);
          }
        });
      } else {
        // Show error dialog
        log("❌ Model is null after successful community creation - this shouldn't happen", name: 'CreateCommunityDialog');
        _showErrorDialog();
      }
    } else {
      // Show error dialog
      log("❌ Community creation failed", name: 'CreateCommunityDialog');
      _showErrorDialog();
    }
  }
  
  // Helper method to show error dialog with specific error message
  void _showErrorDialog() {
    final localization = S.of(context);
    final controller = ref.read(createCommunityControllerProvider.notifier);
    
    // Get the specific error message from the controller
    final errorMessage = controller.lastError;
    
    String userFriendlyError;
    
    // Convert technical error message to user-friendly message
    if (errorMessage.contains("Group identifier creation failed on all relays") || 
        errorMessage.contains("Failed to create group on any relay")) {
      userFriendlyError = "Could not create community on any available relay. We tried multiple relay servers but all failed. Please check your internet connection and try again.";
    } else if (errorMessage.contains("Failed to set group metadata on any relay")) {
      userFriendlyError = "Could not set community name on any available relay. Please try again later.";
    } else if (errorMessage.contains("Failed to create invite on any relay")) {
      userFriendlyError = "Could not generate invite link on any available relay. Please try again with a different name.";
    } else if (errorMessage.contains("timed out")) {
      userFriendlyError = "Operation timed out. The relay servers might be slow or unavailable right now. Please try again later.";
    } else if (errorMessage.toLowerCase().contains("connection")) {
      userFriendlyError = "Connection error. Please check your internet connection and try again.";
    } else {
      // Log the full error for debugging but show a simplified message to the user
      log("Error creating community: $errorMessage", name: '_CreateCommunityDialogState');
      userFriendlyError = "Failed to create community. Please try again later.";
    }
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog.adaptive(
        title: Text(localization.error),
        content: Text(userFriendlyError),
        actions: [
          TextButton(
            child: Text(localization.retry),
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _currentState = DialogState.nameInput;
              });
            },
          ),
          TextButton(
            child: Text(localization.cancel),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    // Clean up the controller when the widget is disposed
    _inviteLinkController?.dispose();
    super.dispose();
  }
}
