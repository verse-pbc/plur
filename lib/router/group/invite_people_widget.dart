import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/generated/l10n.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:nostrmo/util/theme_util.dart';
import 'package:nostrmo/util/string_code_generator.dart';
import 'package:nostrmo/util/group_invite_link_util.dart';
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

// Link type options
enum LinkType {
  direct,      // direct plur:// link
  universal,   // chus.me standard link
  short,       // chus.me/j/ short link
  nostr        // nostr NIP-29 groups join
}

class _InvitePeopleWidgetState extends State<InvitePeopleWidget> {
  late String inviteCode;

  // Different link types
  late String directPlurLink;         // direct plur:// protocol link
  late String standardChusmeLink;     // chus.me/i/CODE link
  late String directInChusmeLink;     // chus.me/i/plur://...full link option
  late String nostrNip29Link;         // nostr: protocol link for NIP-29
  String generatedShortLink = '';     // chus.me/j/CODE short link (empty initially)

  String inviteLink = ''; // Currently active/selected link
  bool isLoading = true;
  bool _isDisposed = false; // Track if widget is disposed
  bool isGeneratingShortUrl = false;
  bool hasGeneratedShortUrl = false;

  // Currently selected link type
  LinkType selectedLinkType = LinkType.direct;
  final ValueNotifier<String> activeLinkNotifier = ValueNotifier<String>('');

  @override
  void initState() {
    super.initState();
    inviteCode = StringCodeGenerator.generateInviteCode();

    // Use the provided shareableLink if available
    if (widget.shareableLink != null && widget.shareableLink!.isNotEmpty) {
      inviteLink = widget.shareableLink!;
      directPlurLink = inviteLink; // Default to provided link
      standardChusmeLink = inviteLink;
      directInChusmeLink = inviteLink;
      nostrNip29Link = inviteLink;
      activeLinkNotifier.value = inviteLink;
      isLoading = false;
    }

    // Schedule async initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeInviteLinks();
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    activeLinkNotifier.dispose();
    super.dispose();
  }

  // Separate method to ensure invite links are properly initialized
  void _initializeInviteLinks() {
    // Use a microtask to avoid calling setState during build
    Future.microtask(() {
      if (mounted && isLoading) {
        final arg = widget.groupIdentifier ?? RouterUtil.routerArgs(context);
        if (arg != null && arg is GroupIdentifier) {
          try {
            // Generate all link types upfront
            directPlurLink = GroupInviteLinkUtil.generateDirectProtocolUrl(
              arg.groupId,
              inviteCode,
              arg.host
            );

            standardChusmeLink = GroupInviteLinkUtil.generateStandardInviteUrl(inviteCode);

            directInChusmeLink = GroupInviteLinkUtil.generateUniversalLink(
              arg.groupId,
              inviteCode,
              arg.host
            );

            // Generate proper Nostr NIP-29 protocol link using the utility method
            nostrNip29Link = GroupInviteLinkUtil.generateNostrProtocolLink(
              arg.groupId,
              inviteCode,
              arg.host
            );

            // Default to the direct protocol URL
            inviteLink = directPlurLink;
            activeLinkNotifier.value = directPlurLink;

            // Start generating short URL in the background
            _generateShortUrl();

            // Update state to show links
            if (mounted && !_isDisposed) {
              // Use a Future.delayed to ensure we're not in a critical build phase
              Future.delayed(Duration.zero, () {
                if (mounted && !_isDisposed) {
                  setState(() {
                    isLoading = false;
                  });
                }
              });
            }
          } catch (e) {
            // Handle error case
            if (mounted && !_isDisposed) {
              // Use Future.delayed to ensure we're not in a critical build phase
              Future.delayed(Duration.zero, () {
                if (mounted && !_isDisposed) {
                  setState(() {
                    isLoading = false;
                  });
                  BotToast.showText(text: "Failed to create invite links: $e");
                }
              });
            }
          }
        }
      }
    });
  }

  // Generate a short URL in the background
  Future<void> _generateShortUrl() async {
    if (_isDisposed) return;

    setState(() {
      isGeneratingShortUrl = true;
    });

    try {
      // This call is mocked in the current implementation
      final result = await GroupInviteLinkUtil.createShortInviteUrl(inviteCode);

      if (result != null && mounted && !_isDisposed) {
        setState(() {
          generatedShortLink = result;
          hasGeneratedShortUrl = true;
          isGeneratingShortUrl = false;

          // Update active link if short link type is selected
          if (selectedLinkType == LinkType.short) {
            activeLinkNotifier.value = generatedShortLink;
          }
        });
      }
    } catch (e) {
      if (mounted && !_isDisposed) {
        setState(() {
          isGeneratingShortUrl = false;
        });
      }
    }
  }

  // Update the active link based on selected type
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
      case LinkType.direct: // Direct plur:// protocol link
        activeLinkNotifier.value = directPlurLink;
        break;
      case LinkType.nostr: // Nostr NIP-29 protocol link
        activeLinkNotifier.value = nostrNip29Link;
        break;
    }
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Initialization is now handled in initState with _initializeInviteLinks
    // This method is kept for lifecycle compliance but doesn't duplicate work
  }

  // Helper for building link type buttons
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
            ? customColors.accentColor.withAlpha(25)
            : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
              ? customColors.accentColor
              : customColors.secondaryForegroundColor.withAlpha(76),
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
                        ? customColors.secondaryForegroundColor.withAlpha(128)
                        : (isSelected ? customColors.accentColor : customColors.secondaryForegroundColor),
                    size: 20,
                  ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: disabled
                    ? customColors.secondaryForegroundColor.withAlpha(128)
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

    final groupId = widget.groupIdentifier ?? RouterUtil.routerArgs(context);
    if (groupId == null || groupId is! GroupIdentifier) {
      RouterUtil.back(context);
      return Container();
    }

    // GroupIdentifier is available

    return Scaffold(
      // Use AppBar with proper sizing and styling
      appBar: AppBar(
        title: Text(
          localization.invite,
          style: TextStyle(
            color: customColors.primaryForegroundColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0, // Remove shadow
        leading: const AppbarBackBtnWidget(),
        bottom: const AppBarBottomBorder(),
      ),
      body: SafeArea(
        child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                // Use LayoutBuilder to get the available constraints
                return SingleChildScrollView(
                  child: Container( // Use Container with fixed height
                    width: constraints.maxWidth,
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min, // Use min to avoid layout issues
                        children: [
                          Text(
                            localization.invitePeopleToJoin,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: customColors.primaryForegroundColor,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Link type selector buttons
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: customColors.accentColor.withAlpha(25),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: customColors.accentColor.withAlpha(76)),
                            ),
                            child: Text(
                              "Choose an invite link type below:",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: customColors.primaryForegroundColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Link type selector buttons in a grid
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
                                      label: 'plur://'
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

                          // Link display with copy button
                          ValueListenableBuilder<String>(
                            valueListenable: activeLinkNotifier,
                            builder: (context, activeLink, child) {
                              return Container(
                                width: double.infinity,
                                constraints: const BoxConstraints(minHeight: 56),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: customColors.feedBgColor,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: customColors.accentColor.withAlpha(76),
                                    width: 1.0,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        activeLink.isNotEmpty ? activeLink : localization.loading,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: customColors.primaryForegroundColor,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: Icon(
                                        Icons.copy,
                                        color: customColors.accentColor,
                                      ),
                                      onPressed: activeLink.isNotEmpty ? () {
                                        Clipboard.setData(ClipboardData(text: activeLink));
                                        BotToast.showText(
                                          text: localization.copySuccess,
                                        );
                                      } : null,
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
                                'Generating short link...',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: customColors.secondaryForegroundColor,
                                  fontStyle: FontStyle.italic
                                ),
                              ),
                            ),

                          const SizedBox(height: 16),
                          Text(
                            localization.shareInviteDescription,
                            style: TextStyle(
                              fontSize: 14,
                              color: customColors.secondaryForegroundColor,
                            ),
                          ),

                          // Add "Invite by Name" option
                          const SizedBox(height: 32),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: customColors.feedBgColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: customColors.accentColor.withAlpha(50),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.person_search,
                                      color: customColors.accentColor,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        "Invite contacts directly",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: customColors.primaryForegroundColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "You can also invite people directly from your contacts",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: customColors.secondaryForegroundColor,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    RouterUtil.router(context, RouterPath.inviteByName, groupId);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: customColors.accentColor.withAlpha(25),
                                    foregroundColor: customColors.accentColor,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: BorderSide(color: customColors.accentColor),
                                    ),
                                  ),
                                  icon: const Icon(Icons.person_add),
                                  label: const Text(
                                    "Invite by Name",
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Add Create Post button if requested
                          if (widget.showCreatePostButton) ...[
                            const SizedBox(height: 40),
                            Center(
                              child: SizedBox(
                                width: double.infinity,
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
                                  child: const Text(
                                    'Create your first post',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                          // Add bottom padding
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      ),
    );
  }
}