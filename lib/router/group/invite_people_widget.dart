import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/generated/l10n.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:nostrmo/util/theme_util.dart';
import 'package:nostrmo/util/string_code_generator.dart';
import 'package:provider/provider.dart';
import 'package:nostrmo/provider/list_provider.dart';
import 'package:nostrmo/component/appbar_back_btn_widget.dart';
import 'package:nostrmo/component/appbar_bottom_border.dart';

/// Widget for inviting people to a group
class InvitePeopleWidget extends StatefulWidget {
  const InvitePeopleWidget({
    super.key,
  });

  @override
  State<InvitePeopleWidget> createState() => _InvitePeopleWidgetState();
}

class _InvitePeopleWidgetState extends State<InvitePeopleWidget> {
  late String inviteCode;
  late String inviteLink;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    inviteCode = StringCodeGenerator.generateInviteCode();
    
    // We'll generate the link in didChangeDependencies when we have context
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    final arg = RouterUtil.routerArgs(context);
    if (arg != null && arg is GroupIdentifier) {
      final listProvider = Provider.of<ListProvider>(context, listen: false);
      inviteLink = listProvider.createInviteLink(arg, inviteCode);
      
      if (isLoading) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final customColors = themeData.customColors;
    final localization = S.of(context);
    
    final arg = RouterUtil.routerArgs(context);
    if (arg == null || arg is! GroupIdentifier) {
      RouterUtil.back(context);
      return Container();
    }
    
    // GroupIdentifier is available as arg

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
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: shareableLink));
                  BotToast.showText(
                    text: 'Link copied to clipboard',
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 40),
          if (showCreatePostButton)
            Center(
              child: InkWell(
                onTap: () {
                  RouterUtil.back(context);
                  GroupDetailWidget.showTooltipOnGroupCreation = true;
                  RouterUtil.router(
                      context, RouterPath.groupDetail, groupIdentifier);
                },
                highlightColor: theme.primaryColor.withAlpha(51),
                child: Container(
                  color: theme.primaryColor,
                  height: 40,
                  alignment: Alignment.center,
                  child: const Text(
                    'Create your first post',
                    style: TextStyle(
                      fontSize: 14,
                      color: customColors.secondaryForegroundColor,
                    ),
                  ),
                ],
              ),
            ),
      ),
    );
  }
}