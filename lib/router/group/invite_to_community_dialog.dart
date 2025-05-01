import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:nostrmo/util/theme_util.dart';
import 'package:nostrmo/util/string_code_generator.dart';
import 'package:nostrmo/util/group_invite_link_util.dart';
import 'package:nostrmo/provider/list_provider.dart';
import 'package:nostrmo/generated/l10n.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:provider/provider.dart';

// Link type options
enum LinkType {
  universal,
  short,
  direct
}

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
  late String inviteLink;
  late String shortLink;
  bool isGeneratingShortUrl = false;
  bool hasShortUrl = false;
  final ValueNotifier<String> activeLinkNotifier = ValueNotifier<String>('');
  
  LinkType selectedLinkType = LinkType.universal;

  @override
  void initState() {
    super.initState();
    inviteCode = StringCodeGenerator.generateInviteCode();
    print('Generated invite code: $inviteCode'); // Debug print
    final listProvider = Provider.of<ListProvider>(context, listen: false);
    
    // Generate the initial universal link
    inviteLink = listProvider.createInviteLink(widget.groupIdentifier!, inviteCode);
    print('Generated invite link: $inviteLink'); // Debug print
    activeLinkNotifier.value = inviteLink;
    
    // Start the process of generating a short URL
    _generateShortUrl();
  }
  
  @override
  void dispose() {
    activeLinkNotifier.dispose();
    super.dispose();
  }
  
  // Generate a short URL from the standard invite
  Future<void> _generateShortUrl() async {
    // Only try to generate if we have a valid group identifier
    if (widget.groupIdentifier == null) return;
    
    print('Generating short URL for code: $inviteCode'); // Debug print
    
    setState(() {
      isGeneratingShortUrl = true;
    });
    
    try {
      // Use the GroupInviteLinkUtil to create a short URL
      final result = await GroupInviteLinkUtil.createShortInviteUrl(inviteCode);
      print('createShortInviteUrl result: $result'); // Debug print
      
      // If successful, update the shortLink variable
      if (result != null) {
        setState(() {
          shortLink = result;
          hasShortUrl = true;
          isGeneratingShortUrl = false;
          print('Short link set to: $shortLink'); // Debug print
          
          // If short link type was selected, update the active link
          if (selectedLinkType == LinkType.short) {
            activeLinkNotifier.value = shortLink;
            print('Active link updated to short link: ${activeLinkNotifier.value}'); // Debug print
          }
        });
      } else {
        print('Short link generation returned null'); // Debug print
        setState(() {
          isGeneratingShortUrl = false;
        });
      }
    } catch (e) {
      print('Error generating short link: $e'); // Debug print
      setState(() {
        isGeneratingShortUrl = false;
      });
    }
  }
  
  // Update the currently displayed link based on the selected type
  void _updateActiveLink() {
    switch (selectedLinkType) {
      case LinkType.universal:
        activeLinkNotifier.value = inviteLink;
        break;
      case LinkType.short:
        if (hasShortUrl) {
          activeLinkNotifier.value = shortLink;
        } else {
          // If short URL isn't available yet, fall back to universal
          activeLinkNotifier.value = inviteLink;
        }
        break;
      case LinkType.direct:
        // Generate the direct protocol link
        final directLink = 'plur://join-community?group-id=${widget.groupIdentifier!.groupId}&code=$inviteCode&relay=${Uri.encodeComponent(widget.groupIdentifier!.host)}';
        activeLinkNotifier.value = directLink;
        break;
    }
  }

  /// Builds a button for selecting the link type
  Widget _buildLinkTypeButton(
    BuildContext context, {
    required LinkType type,
    required IconData icon,
    required String label,
    bool isLoading = false,
    bool disabled = false,
  }) {
    final themeData = Theme.of(context);
    final customColors = themeData.customColors;
    
    final isSelected = selectedLinkType == type;
    
    return InkWell(
      onTap: disabled ? null : () {
        setState(() {
          selectedLinkType = type;
          _updateActiveLink();
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
            ? customColors.accentColor.withAlpha(25) // 0.1 * 255 = 25
            : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected 
              ? customColors.accentColor 
              : customColors.secondaryForegroundColor.withAlpha(76), // 0.3 * 255 = 76
            width: 1.0,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        customColors.accentColor,
                      ),
                    ),
                  )
                : Icon(
                    icon,
                    color: disabled 
                        ? customColors.secondaryForegroundColor.withAlpha(128) // 0.5 * 255 = 128
                        : (isSelected ? customColors.accentColor : customColors.secondaryForegroundColor),
                    size: 20,
                  ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: disabled
                    ? customColors.secondaryForegroundColor.withAlpha(128) // 0.5 * 255 = 128
                    : (isSelected ? customColors.accentColor : customColors.secondaryForegroundColor),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
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
                            localization.invite,
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
                        localization.invitePeopleToJoin,
                        style: TextStyle(
                          fontSize: 16,
                          color: customColors.primaryForegroundColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Link type selector
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildLinkTypeButton(
                            context,
                            type: LinkType.universal,
                            icon: Icons.language, 
                            label: 'Web Link'
                          ),
                          _buildLinkTypeButton(
                            context,
                            type: LinkType.short,
                            icon: Icons.link, 
                            label: 'Short Link',
                            isLoading: isGeneratingShortUrl,
                            disabled: !hasShortUrl && !isGeneratingShortUrl,
                          ),
                          _buildLinkTypeButton(
                            context,
                            type: LinkType.direct,
                            icon: Icons.smartphone, 
                            label: 'Direct Link'
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Link display
                      ValueListenableBuilder<String>(
                        valueListenable: activeLinkNotifier,
                        builder: (context, activeLink, child) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: customColors.feedBgColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: customColors.accentColor.withAlpha(76), // 0.3 * 255 = 76
                                width: 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    activeLink,
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
                                    Clipboard.setData(ClipboardData(text: activeLink));
                                    BotToast.showText(
                                      text: localization.copySuccess,
                                    );
                                  },
                                ),
                              ],
                            ),
                          );
                        }
                      ),
                      
                      // Status text for short link
                      if (selectedLinkType == LinkType.short && isGeneratingShortUrl)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Generating short link...',
                            style: TextStyle(
                              fontSize: 12, 
                              color: customColors.secondaryForegroundColor,
                              fontStyle: FontStyle.italic
                            ),
                          ),
                        ),
                        
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => RouterUtil.back(context),
                            child: Text(
                              localization.done,
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