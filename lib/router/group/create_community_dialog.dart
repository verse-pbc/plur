import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/router/group/create_community_widget.dart';
import 'package:nostrmo/router/group/invite_people_widget.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:nostrmo/util/theme_util.dart';

import '../group_add_dialog_controller.dart';

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
    final controller = ref.watch(addGroupControllerProvider);
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
          SingleChildScrollView(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              alignment: Alignment.center,
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.all(20),
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
                            child: CircularProgressIndicator(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onCreateCommunity(String communityName) async {
    final provider = addGroupControllerProvider;
    final controller = ref.read(provider.notifier);
    final result = await controller.createCommunity(communityName);
  }
}
