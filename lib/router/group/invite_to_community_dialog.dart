import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:nostrmo/util/theme_util.dart';
import 'package:nostrmo/util/string_code_generator.dart';
import 'package:nostrmo/provider/list_provider.dart';
import 'package:nostrmo/generated/l10n.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:provider/provider.dart';

class InviteToCommunityDialog extends StatefulWidget {
  final GroupIdentifier? groupIdentifier;

  const InviteToCommunityDialog({
    super.key,
    required this.groupIdentifier,
  });

  static Future<void> show({
    required BuildContext context,
    required GroupIdentifier? groupIdentifier,
    ListProvider? listProvider,
  }) async {
    if (groupIdentifier == null) return;

    await showDialog<void>(
      context: context,
      useRootNavigator: false,
      builder: (_) {
        return InviteToCommunityDialog(
          groupIdentifier: groupIdentifier,
        );
      },
    );
  }

  @override
  State<InviteToCommunityDialog> createState() =>
      _InviteToCommunityDialogState();
}

class _InviteToCommunityDialogState extends State<InviteToCommunityDialog> {
  late final String inviteCode;
  late final String inviteLink;

  @override
  void initState() {
    super.initState();
    inviteCode = StringCodeGenerator.generateInviteCode();
    final listProvider = Provider.of<ListProvider>(context, listen: false);
    inviteLink = listProvider.createInviteLink(widget.groupIdentifier!, inviteCode);
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final customColors = themeData.customColors;
    final localization = S.of(context);

    return Scaffold(
      backgroundColor: ThemeUtil.getDialogCoverColor(themeData),
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          GestureDetector(
            onTap: () => RouterUtil.back(context),
            child: Container(color: Colors.black54),
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
                    color: customColors.feedBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            localization.Invite,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: customColors.primaryForegroundColor,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              color: customColors.primaryForegroundColor,
                            ),
                            onPressed: () => RouterUtil.back(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        localization.Invite_people_to_join,
                        style: TextStyle(
                          fontSize: 16,
                          color: customColors.primaryForegroundColor,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: customColors.feedBgColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                inviteLink,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: customColors.primaryForegroundColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.copy,
                                color: customColors.accentColor,
                              ),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: inviteLink));
                                BotToast.showText(
                                  text: localization.Copy_success,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => RouterUtil.back(context),
                            child: Text(
                              localization.Done,
                              style: TextStyle(
                                color: customColors.accentColor,
                              ),
                            ),
                          ),
                        ],
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
}