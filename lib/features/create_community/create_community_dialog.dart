import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nostrmo/router/group/invite_people_widget.dart';
import 'package:nostrmo/theme/app_colors.dart';

import '../../generated/l10n.dart';
import 'create_community_controller.dart';
import 'create_community_widget.dart';

class CreateCommunityDialog extends ConsumerStatefulWidget {
  const CreateCommunityDialog({super.key});

  // New method to show the content as a bottom sheet instead of a dialog
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
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final controller = ref.watch(createCommunityControllerProvider);
    
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
              'assets/imgs/welcome_groups.png',
              width: 80,
              height: 80,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.people_alt_rounded,
                  size: 80,
                  color: colors.buttonText,
                );
              },
            ),
          ),
          
          const SizedBox(height: 16),
          
          controller.when(
            data: (model) {
              if (model == null) {
                return CreateCommunityWidget(
                  onCreateCommunity: _onCreateCommunity,
                );
              } else {
                return InvitePeopleWidget(
                  shareableLink: model.$2,
                  groupIdentifier: model.$1,
                  showCreatePostButton: true,
                );
              }
            },
            error: (error, stackTrace) {
              return Center(child: ErrorWidget(error));
            },
            loading: () {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _onCreateCommunity(String communityName) async {
    final controller = ref.read(createCommunityControllerProvider.notifier);
    final result = await controller.createCommunity(communityName);
    if (!mounted) return;
    final localization = S.of(context);
    if (!result) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => AlertDialog.adaptive(
          title: Text(localization.error),
          content: const Text("Failed to create community"),
          actions: [
            TextButton(
              child: Text(localization.retry),
              onPressed: () {
                Navigator.of(context).pop();
                _onCreateCommunity(communityName);
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
  }
}
