import 'package:flutter/material.dart';
import 'package:nostrmo/router/group/create_community_widget.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:nostrmo/util/theme_util.dart';

class CreateCommunityDialog extends StatefulWidget {
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
  State<CreateCommunityDialog> createState() => _CreateCommunityDialogState();
}

class _CreateCommunityDialogState extends State<CreateCommunityDialog> {
  final bool _showInviteCommunity = false;

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    Color cardColor = themeData.cardColor;

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
                      if (!_showInviteCommunity)
                        CreateCommunityWidget(
                            onCreateCommunity: _onCreateCommunity),
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

  void _onCreateCommunity(String communityName) {
    setState(() {
      // TODO: Add functionality to show invite
    });
  }
}
