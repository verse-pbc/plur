import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nostrmo/component/primary_button_widget.dart';
import 'package:nostrmo/generated/l10n.dart';

/// A widget that provides a UI for joining an existing community by pasting an invitation link.
class JoinCommunityWidget extends StatefulWidget {
  final void Function(String) onJoinCommunity;

  const JoinCommunityWidget({super.key, required this.onJoinCommunity});

  @override
  State<JoinCommunityWidget> createState() => _JoinCommunityWidgetState();
}

class _JoinCommunityWidgetState extends State<JoinCommunityWidget> {
  final TextEditingController _linkController = TextEditingController();
  bool _hasValidFormat = false;

  @override
  void initState() {
    super.initState();
    
    // Check clipboard on initialization
    _checkClipboard();
  }
  
  Future<void> _checkClipboard() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      final clipboardText = clipboardData?.text?.trim();
      
      // If clipboard contains what looks like a community link, pre-fill it
      if (clipboardText != null && 
          (clipboardText.startsWith('plur://join-community') || clipboardText.startsWith('plur:join-community')) &&
          clipboardText.contains('group-id=')) {
        _linkController.text = clipboardText;
        _validateLink(clipboardText);
      }
    } catch (e) {
      // Silently handle clipboard permission errors
      // In web contexts, we'll need user interaction first
      debugPrint("Clipboard access error: $e");
    }
  }
  
  void _validateLink(String text) {
    setState(() {
      // Basic validation - we'll do more thorough validation when processing
      final trimmedText = text.trim();
      _hasValidFormat = (trimmedText.startsWith('plur://join-community') || 
                         trimmedText.startsWith('plur:join-community')) && 
                        trimmedText.contains('group-id=');
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back button in top left
        Align(
          alignment: Alignment.topLeft,
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              // Go back to the option selection screen
              FocusScope.of(context).unfocus();
              Navigator.of(context).maybePop();
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            splashRadius: 24,
          ),
        ),
        const SizedBox(height: 10),
        
        Text(
          l10n.Join_Group,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 20),
        
        Text(
          "Paste a community invitation link",
          style: const TextStyle(
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        
        // Example of what a link looks like
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            "Example: plur://join-community?group-id=ABC123&code=XYZ789",
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'monospace',
              color: Colors.grey,
            ),
          ),
        ),
        const SizedBox(height: 15),
        
        // Link input field
        TextField(
          controller: _linkController,
          maxLines: 3,
          minLines: 1,
          decoration: InputDecoration(
            hintText: l10n.Please_input,
            border: const OutlineInputBorder(),
            suffixIcon: _linkController.text.isNotEmpty 
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _linkController.clear();
                      _hasValidFormat = false;
                    });
                  },
                )
              : null,
          ),
          onChanged: _validateLink,
        ),
        const SizedBox(height: 10),
        
        // Paste button
        Center(
          child: TextButton.icon(
            onPressed: () async {
              try {
                final data = await Clipboard.getData(Clipboard.kTextPlain);
                if (data?.text != null) {
                  _linkController.text = data!.text!.trim();
                  _validateLink(_linkController.text);
                }
              } catch (e) {
                // Handle clipboard permission errors
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Cannot access clipboard. Please interact with the page first or enter the link manually."),
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            },
            icon: const Icon(Icons.content_paste),
            label: const Text("Paste from clipboard"),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ),
        const SizedBox(height: 20),
        
        // Join button
        PrimaryButtonWidget(
          text: l10n.Join_Group,
          onTap: _hasValidFormat 
            ? () => widget.onJoinCommunity(_linkController.text) 
            : null,
          enabled: _hasValidFormat,
        ),
      ],
    );
  }
  
  @override
  void dispose() {
    _linkController.dispose();
    super.dispose();
  }
}