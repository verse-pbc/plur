import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:nostrmo/generated/l10n.dart';
import 'package:nostrmo/util/community_join_util.dart';

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
      
      if (mounted) {
        setState(() {
          _hasValidLink = CommunityJoinUtil.isValidJoinLink(clipboardText);
        });
      }
    } catch (e) {
      // Handle permission or focus errors gracefully
      // In web contexts, clipboard is only available after user interaction
      debugPrint("Clipboard error: $e");
      if (mounted) {
        setState(() {
          _hasValidLink = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final themeData = Theme.of(context);
    final primaryColor = themeData.primaryColor;
    
    return AnimatedOpacity(
      opacity: _hasValidLink ? 1.0 : 0.0, // Hide when no valid link
      duration: const Duration(milliseconds: 200),
      child: Visibility(
        visible: _hasValidLink,
        child: FloatingActionButton.extended(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.content_paste),
          label: Text(l10n.joinGroup),
          onPressed: () async {
            try {
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
            } catch (e) {
              // Handle clipboard permission errors
              if (context.mounted) {
                BotToast.showText(
                  text: "Cannot access clipboard. Please interact with the page first or use manual entry.",
                  duration: const Duration(seconds: 4),
                );
              }
            }
          },
        ),
      ),
    );
  }
}