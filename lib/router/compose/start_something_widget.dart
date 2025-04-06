import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/generated/l10n.dart';
import 'package:nostrmo/router/edit/editor_widget.dart';
import 'package:nostrmo/util/router_util.dart';

class StartSomethingWidget extends StatefulWidget {
  const StartSomethingWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _StartSomethingWidgetState();
  }
}

class _StartSomethingWidgetState extends State<StartSomethingWidget> {
  // Define content types (post intents)
  final List<PostIntent> _contentTypes = [
    PostIntent(
      label: 'Update',
      icon: Icons.article_outlined,
      emoji: '📣',
      description: 'Share an update with your group',
      eventKind: EventKind.TEXT_NOTE,
      isEnabled: true,
    ),
    PostIntent(
      label: 'Thread',
      icon: Icons.chat_outlined,
      emoji: '💬',
      description: 'Start a conversation thread',
      eventKind: EventKind.TEXT_NOTE,
      hasETag: true,
      isEnabled: true,
    ),
    PostIntent(
      label: 'Event',
      icon: Icons.event_outlined,
      emoji: '📅',
      description: 'Plan an event',
      eventKind: 30311, // Event kind
      isEnabled: false, // Disable for initial release
    ),
    PostIntent(
      label: 'Audio Room',
      icon: Icons.headset_outlined,
      emoji: '🎧',
      description: 'Open an audio room',
      eventKind: 30023, // Audio room kind
      customTags: [["t", "audio-room"]],
      isEnabled: false, // Disable for initial release
    ),
    PostIntent(
      label: 'Livestream',
      icon: Icons.live_tv_outlined,
      emoji: '📺',
      description: 'Start a livestream',
      eventKind: 30023, // Livestream kind
      customTags: [["t", "livestream"]],
      isEnabled: false, // Disable for initial release
    ),
    PostIntent(
      label: 'Question',
      icon: Icons.help_outline,
      emoji: '❓',
      description: 'Ask the group something',
      eventKind: 30023, // Question kind
      customTags: [["t", "question"]],
      isEnabled: false, // Disable for initial release
    ),
    PostIntent(
      label: 'Ask/Offer',
      icon: Icons.volunteer_activism_outlined,
      emoji: '🎁',
      description: 'Ask for help or make an offer',
      eventKind: 31990, // Ask/Offer kind
      isEnabled: false, // Disable for initial release
    ),
    PostIntent(
      label: 'Doc/Agenda',
      icon: Icons.description_outlined,
      emoji: '📝',
      description: 'Create a document or agenda',
      eventKind: EventKind.TEXT_NOTE,
      customTags: [["t", "document"]],
      isEnabled: false, // Disable for initial release
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final localization = S.of(context);
    final themeData = Theme.of(context);
    final textColor = themeData.textTheme.bodyMedium!.color;
    final cardColor = themeData.cardColor;

    // Filter enabled content types
    final enabledContentTypes = _contentTypes.where((type) => type.isEnabled).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: cardColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            RouterUtil.back(context);
          },
        ),
        title: Text(
          localization.What_do_you_want_to_do,
          style: TextStyle(
            color: textColor,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        color: themeData.scaffoldBackgroundColor,
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: enabledContentTypes.length,
          itemBuilder: (context, index) {
            final contentType = enabledContentTypes[index];
            return _buildContentTypeCard(context, contentType);
          },
        ),
      ),
    );
  }

  Widget _buildContentTypeCard(BuildContext context, PostIntent contentType) {
    final themeData = Theme.of(context);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _handleContentTypeSelected(context, contentType),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon or emoji
              contentType.emoji != null
                  ? Text(
                      contentType.emoji!,
                      style: const TextStyle(fontSize: 36),
                    )
                  : Icon(
                      contentType.icon,
                      size: 36,
                      color: themeData.primaryColor,
                    ),
              const SizedBox(height: 12),
              // Label
              Text(
                contentType.label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              // Description
              Text(
                contentType.description,
                style: TextStyle(
                  fontSize: 12,
                  color: themeData.textTheme.bodySmall?.color,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleContentTypeSelected(BuildContext context, PostIntent contentType) {
    // For now, we'll just use the existing editor for all content types
    // In the future, route to specific editors based on contentType
    
    List<dynamic> tags = [];
    
    // Add custom tags if they exist
    if (contentType.customTags != null) {
      tags.addAll(contentType.customTags!);
    }
    
    // Add e tag if this is a thread
    if (contentType.hasETag) {
      // For thread, we would normally add an e tag for the parent post
      // In this example, we're just mocking it
      // tags.add(["e", parentEventId]);
    }
    
    // Open the appropriate editor based on the content type
    EditorWidget.open(
      context,
      tags: tags,
      tagsAddedWhenSend: [],
      tagPs: [], 
    );
  }
}

// Model class to represent a post type/intent
class PostIntent {
  final String label;
  final IconData icon;
  final String? emoji;
  final String description;
  final int eventKind;
  final bool hasETag;
  final List<dynamic>? customTags;
  final bool isEnabled;

  PostIntent({
    required this.label,
    required this.icon,
    this.emoji,
    required this.description,
    required this.eventKind,
    this.hasETag = false,
    this.customTags,
    required this.isEnabled,
  });
}