import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nostrmo/router/group/invite_people_widget.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:nostrmo/util/theme_util.dart';

import '../../generated/l10n.dart';
import 'create_community_controller.dart';
import 'create_community_widget.dart';

class CreateCommunityDialog extends ConsumerStatefulWidget {
  const CreateCommunityDialog({super.key});

  static Future<void> show(BuildContext context) async {
    await showDialog<void>(
      context: context,
      useRootNavigator: false,
      builder: (_) {
        return const CreateCommunityDialog();
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
    final themeData = Theme.of(context);
    Color cardColor = themeData.cardColor;
    final controller = ref.watch(createCommunityControllerProvider);
    return Scaffold(
      backgroundColor: ThemeUtil.getDialogCoverColor(themeData),
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          GestureDetector(
            onTap: () {
              RouterUtil.back(context);
            },
            child: Container(
              color: Colors.black54,
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          RouterUtil.back(context);
                        },
                      ),
                    ),
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
                            padding: EdgeInsets.fromLTRB(20, 50, 20, 90),
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
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
          title: Text(localization.Error),
          content: Text(localization.Save_failed),
          actions: [
            TextButton(
              child: Text(localization.Retry),
              onPressed: () {
                Navigator.of(context).pop();
                _onCreateCommunity(communityName);
              },
            ),
            TextButton(
              child: Text(localization.Cancel),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    }
  }
}
