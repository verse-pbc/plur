import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:nostrmo/generated/l10n.dart';
import 'package:nostrmo/util/community_join_util.dart';
import 'package:nostrmo/util/theme_util.dart';

/// A floating action button that checks clipboard for community invite links
/// and joins communities when a valid link is found.
class PasteJoinLinkButton extends StatefulWidget {
  const PasteJoinLinkButton({super.key});

  @override
  State<PasteJoinLinkButton> createState() => _PasteJoinLinkButtonState();
}

class _PasteJoinLinkButtonState extends State<PasteJoinLinkButton> {
  bool _hasValidLink = false;

  @override
  void initState() {
    super.initState();
    // Check clipboard on init
    _checkClipboard();
  }

  Future<void> _checkClipboard() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      final clipboardText = clipboardData?.text?.trim();
      
      setState(() {
        _hasValidLink = CommunityJoinUtil.isValidJoinLink(clipboardText);
      });
    } catch (e) {
      // Ignore clipboard errors
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final themeData = Theme.of(context);
    final primaryColor = themeData.primaryColor;
    final dimmedColor = themeData.customColors.dimmedColor;
    
    return AnimatedOpacity(
      opacity: _hasValidLink ? 1.0 : 0.0, // Hide when no valid link
      duration: const Duration(milliseconds: 200),
      child: Visibility(
        visible: _hasValidLink,
        child: FloatingActionButton.extended(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.content_paste),
          label: Text(l10n.Join_Group),
          onPressed: () async {
            final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
            final clipboardText = clipboardData?.text?.trim();
            
            if (clipboardText != null) {
              final success = CommunityJoinUtil.parseAndJoinCommunity(context, clipboardText);
              if (!success) {
                if (context.mounted) {
                  BotToast.showText(text: "Invalid community link format");
                }
              }
            }
          },
        ),
      ),
    );
  }
}