import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:nostrmo/theme/app_colors.dart';
import 'package:nostrmo/util/string_code_generator.dart';
import 'package:nostrmo/util/group_invite_link_util.dart';
import 'package:nostrmo/provider/list_provider.dart';
import 'package:nostrmo/generated/l10n.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as dev;

// Link type options
enum LinkType {
  universal,  // chus.me standard link
  short,      // chus.me/j/ short link
  direct,     // direct holis:// link
  nostr       // nostr NIP-29 groups join
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
  late String standardChusmeLink;         // chus.me/i/CODE link
  late String directInChusmeLink;         // chus.me/i/holis://...full link option
  late String generatedShortLink;         // chus.me/j/CODE short link
  late String directHolisLink;            // direct holis:// protocol link
  late String nostrNip29Link;             // nostr: protocol link for NIP-29

  bool isGeneratingShortUrl = false;
  bool hasGeneratedShortUrl = false;
  String shortUrlApiCallAttempt = "Not attempted yet.";
  String registrationApiResponse = "No response yet";
  final ValueNotifier<String> activeLinkNotifier = ValueNotifier<String>('');

  LinkType selectedLinkType = LinkType.direct;

  @override
  void initState() {
    super.initState();
    inviteCode = StringCodeGenerator.generateInviteCode();
    dev.log('Generated invite code: $inviteCode', name: 'InviteDebug');
    final listProvider = Provider.of<ListProvider>(context, listen: false);

    // Generate the direct protocol link (most reliable)
    // Generate the direct protocol link first (this is the primary/default one)
    directHolisLink = GroupInviteLinkUtil.generateDirectProtocolUrl(widget.groupIdentifier!.groupId, inviteCode, widget.groupIdentifier!.host);
    dev.log('Direct holis:// link: $directHolisLink', name: 'InviteDebug');

    // Generate the standard chus.me link
    standardChusmeLink = GroupInviteLinkUtil.generateStandardInviteUrl(inviteCode);
    dev.log('Standard chus.me/i/ link: $standardChusmeLink', name: 'InviteDebug');

    // Generate the chus.me link with embedded holis:// URI
    directInChusmeLink = GroupInviteLinkUtil.generateUniversalLink(widget.groupIdentifier!.groupId, inviteCode, widget.groupIdentifier!.host);
    dev.log('Universal chus.me link with embedded protocol: $directInChusmeLink', name: 'InviteDebug');

    // Generate proper Nostr NIP-29 protocol link using the utility method
    nostrNip29Link = GroupInviteLinkUtil.generateNostrProtocolLink(
      widget.groupIdentifier!.groupId,
      inviteCode,
      widget.groupIdentifier!.host
    );
    dev.log('Nostr NIP-29 link: $nostrNip29Link', name: 'InviteDebug');

    // Default to the direct link as it's more reliable
    activeLinkNotifier.value = directHolisLink;

    // Start the process of generating a short URL (which is currently mocked)
    _generateMockedShortUrl();

    // Try registering with chus.me API for debugging standard invite registration
    _testChusmeStandardInviteRegistration();
  }
  
  @override
  void dispose() {
    activeLinkNotifier.dispose();
    super.dispose();
  }
  
  Future<void> _testChusmeStandardInviteRegistration() async {
    setState(() {
      registrationApiResponse = "Registering standard invite with chus.me/api/invite...";
    });
    
    try {
      // This call might fail if _inviteApiKey is a placeholder
      final result = await GroupInviteLinkUtil.registerStandardInvite(
        widget.groupIdentifier!.groupId,
        widget.groupIdentifier!.host
      );
      
      setState(() {
        if (result != null) {
          registrationApiResponse = "✅ Standard Invite API Success: $result";
        } else {
          registrationApiResponse = "❌ Standard Invite API returned null (Likely due to placeholder API Key: ${GroupInviteLinkUtil.getApiKeyPlaceholderStatus()})";
        }
      });
      dev.log('Standard Invite API Response: $result', name: 'InviteDebug');
    } catch (e) {
      setState(() {
        registrationApiResponse = "❌ Standard Invite API Error: $e (Likely due to placeholder API Key: ${GroupInviteLinkUtil.getApiKeyPlaceholderStatus()})";
      });
      dev.log('Standard Invite API Error: $e', name: 'InviteDebug');
    }
  }
  
  Future<void> _generateMockedShortUrl() async {
    if (widget.groupIdentifier == null) return;
    
    dev.log('Attempting to generate MOCKED short URL for code: $inviteCode', name: 'InviteDebug');
    
    setState(() {
      isGeneratingShortUrl = true;
      shortUrlApiCallAttempt = "Using GroupInviteLinkUtil.createShortInviteUrl (CURRENTLY MOCKED - NOT A REAL API CALL)...";
    });
    
    try {
      // This uses the local/mocked implementation in GroupInviteLinkUtil
      final result = await GroupInviteLinkUtil.createShortInviteUrl(inviteCode);
      dev.log('Mocked createShortInviteUrl result: $result', name: 'InviteDebug');
      
      if (result != null) {
        setState(() {
          generatedShortLink = result;
          hasGeneratedShortUrl = true;
          shortUrlApiCallAttempt += "\nSuccess (mocked): $result";
          if (selectedLinkType == LinkType.short) {
            activeLinkNotifier.value = generatedShortLink;
          }
        });
      } else {
        shortUrlApiCallAttempt += "\nReturned null (mocked).";
        dev.log('Mocked short link generation returned null', name: 'InviteDebug');
      }
    } catch (e) {
      shortUrlApiCallAttempt += "\nError (mocked): $e";
      dev.log('Error in mocked short link generation: $e', name: 'InviteDebug');
    } finally {
      setState(() {
        isGeneratingShortUrl = false;
      });
    }
  }
  
  void _updateActiveLink() {
    switch (selectedLinkType) {
      case LinkType.universal: // Standard chus.me/i/ link
        activeLinkNotifier.value = standardChusmeLink;
        break;
      case LinkType.short: // Short chus.me/j/ link
        if (hasGeneratedShortUrl) {
          activeLinkNotifier.value = generatedShortLink;
        } else {
          activeLinkNotifier.value = standardChusmeLink; // Fallback to standard link
        }
        break;
      case LinkType.direct: // Direct holis:// protocol link
        activeLinkNotifier.value = directHolisLink;
        break;
      case LinkType.nostr: // Nostr NIP-29 protocol link
        activeLinkNotifier.value = nostrNip29Link;
        break;
    }
  }

  Widget _buildLinkTypeButton(
    BuildContext context, {
    required LinkType type,
    required IconData icon,
    required String label,
    bool isLoading = false,
    bool disabled = false,
  }) {
    final themeData = Theme.of(context);
    
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
            ? context.colors.accent.withAlpha(25)
            : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected 
              ? context.colors.accent 
              : context.colors.secondaryText.withAlpha(76),
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
                        context.colors.accent,
                      ),
                    ),
                  )
                : Icon(
                    icon,
                    color: disabled 
                        ? context.colors.secondaryText.withAlpha(128) 
                        : (isSelected ? context.colors.accent : context.colors.secondaryText),
                    size: 20,
                  ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: disabled
                    ? context.colors.secondaryText.withAlpha(128) 
                    : (isSelected ? context.colors.accent : context.colors.secondaryText),
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
    final localization = S.of(context);

    return Scaffold(
      backgroundColor: (themeData.textTheme.bodyMedium!.color ?? Colors.black).withAlpha(51),
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
                    color: context.colors.feedBackground,
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
                              color: context.colors.primaryText,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              color: context.colors.primaryText,
                            ),
                            onPressed: () => RouterUtil.back(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: context.colors.accent.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: context.colors.accent.withAlpha(76)),
                        ),
                        child: Text(
                          "Choose an invite link type below:",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: context.colors.primaryText,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // DEBUGGING SECTION
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.yellowAccent,
                            width: 1.0,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "🐛 AVAILABLE LINK FORMATS (holis:// preferred) 🐛",
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.yellowAccent),
                            ),
                            const SizedBox(height: 6),
                            _DebugInfoRow(label: "Invite Code:", value: inviteCode, valueColor: Colors.lightGreenAccent),
                            _DebugInfoRow(label: "1. Direct holis:// Link:", value: directHolisLink, isLink: true),
                            _DebugInfoRow(label: "2. Standard chus.me/i Link:", value: standardChusmeLink, isLink: true),
                            _DebugInfoRow(label: "3. chus.me Universal:", value: directInChusmeLink, isLink: true),
                            _DebugInfoRow(label: "4. Nostr NIP-29 Link:", value: nostrNip29Link, isLink: true),
                            const Divider(color: Colors.grey),
                            const Text("chus.me Standard Invite Registration:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyanAccent, fontSize: 12)),
                            Text(registrationApiResponse, style: TextStyle(fontSize: 11, color: registrationApiResponse.contains("✅") ? Colors.greenAccent : Colors.redAccent)),
                            TextButton(
                              onPressed: _testChusmeStandardInviteRegistration,
                              child: const Text("Retry Standard Registration", style: TextStyle(color: Colors.blueAccent, fontSize: 11)),
                            ),
                            const Divider(color: Colors.grey),
                            const Text("chus.me Short Link Generation (/j/):", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyanAccent, fontSize: 12)),
                            Text(
                                "Status: ${isGeneratingShortUrl ? 'Generating (mocked)...' : (hasGeneratedShortUrl ? 'Generated (mocked)' : 'Not generated/Error (mocked)')}", 
                                style: TextStyle(fontSize: 11, color: hasGeneratedShortUrl ? Colors.greenAccent : Colors.orangeAccent)
                            ),
                            Text(
                              "Note: Current short link generation (createShortInviteUrl) is MOCKED and does NOT call a real API.",
                              style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Colors.yellowAccent.withOpacity(0.8)),
                            ),
                            if (hasGeneratedShortUrl)
                              _DebugInfoRow(label: "Mocked Short Link:", value: generatedShortLink, isLink: true),
                            _DebugInfoRow(label: "API Call Detail (Mocked Shortener):", value: shortUrlApiCallAttempt, wrap: true),
                            Text(
                                "If real API (createShortUrl) were used: POST to https://chus.me/api/invite/short with body: {\'code\': '$inviteCode'} and X-Invite-Token: ${GroupInviteLinkUtil.getApiKeyPlaceholderStatus()}", 
                                style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Colors.white70)
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Simple list of buttons - easier to display on all screen sizes
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Expanded(
                                child: _buildLinkTypeButton(
                                  context,
                                  type: LinkType.direct,
                                  icon: Icons.smartphone,
                                  label: 'holis://'
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildLinkTypeButton(
                                  context,
                                  type: LinkType.universal,
                                  icon: Icons.language,
                                  label: 'chus.me/invite'
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Expanded(
                                child: _buildLinkTypeButton(
                                  context,
                                  type: LinkType.short,
                                  icon: Icons.link,
                                  label: 'Short',
                                  isLoading: isGeneratingShortUrl,
                                  disabled: !hasGeneratedShortUrl && !isGeneratingShortUrl,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildLinkTypeButton(
                                  context,
                                  type: LinkType.nostr,
                                  icon: Icons.settings_ethernet,
                                  label: 'Nostr'
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      ValueListenableBuilder<String>(
                        valueListenable: activeLinkNotifier,
                        builder: (context, activeLink, child) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: context.colors.feedBackground,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: context.colors.accent.withAlpha(76),
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
                                      color: context.colors.primaryText,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.copy,
                                    color: context.colors.accent,
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
                      
                      if (selectedLinkType == LinkType.short && isGeneratingShortUrl)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Generating MOCKED short link...',
                            style: TextStyle(
                              fontSize: 12, 
                              color: context.colors.secondaryText,
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
                                color: context.colors.accent,
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

// Helper widget for consistent debug info rows
class _DebugInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color labelColor;
  final Color valueColor;
  final bool isLink;
  final bool wrap;

  const _DebugInfoRow({
    required this.label,
    required this.value,
    this.labelColor = Colors.white,
    this.valueColor = Colors.white70,
    this.isLink = false,
    this.wrap = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: wrap ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: labelColor),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 11, color: valueColor, decoration: isLink ? TextDecoration.underline : TextDecoration.none),
              softWrap: wrap,
              overflow: wrap ? TextOverflow.visible : TextOverflow.ellipsis,
            ),
          ),
          if (isLink)
            IconButton(
              icon: Icon(Icons.copy, size: 14, color: Colors.grey.shade400),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                BotToast.showText(text: 'Copied: $label');
              },
            )
        ],
      ),
    );
  }
}