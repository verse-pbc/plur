import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/generated/l10n.dart';
import 'package:nostrmo/router/edit/editor_widget.dart';
import 'package:nostrmo/router/compose/event_composer_widget.dart';
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
      isEnabled: true, // Enable for testing
    ),
    PostIntent(
      label: 'Question',
      icon: Icons.help_outline,
      emoji: '❓',
      description: 'Ask the group something',
      eventKind: EventKind.POLL, // Poll kind
      customTags: [["t", "question"]],
      isEnabled: true, // Enable for testing
    ),
    PostIntent(
      label: 'Doc/Agenda',
      icon: Icons.description_outlined,
      emoji: '📝',
      description: 'Create a document or agenda',
      eventKind: EventKind.LONG_FORM,
      customTags: [["t", "document"]],
      isEnabled: true, // Enable for testing
    ),
    PostIntent(
      label: 'Audio Room',
      icon: Icons.headset_outlined,
      emoji: '🎧',
      description: 'Open an audio room',
      eventKind: 30023, // Audio room kind
      customTags: [["t", "audio-room"]],
      isEnabled: false, // To be implemented later
    ),
    PostIntent(
      label: 'Livestream',
      icon: Icons.live_tv_outlined,
      emoji: '📺',
      description: 'Start a livestream',
      eventKind: 30023, // Livestream kind
      customTags: [["t", "livestream"]],
      isEnabled: false, // To be implemented later
    ),
    PostIntent(
      label: 'Ask/Offer',
      icon: Icons.volunteer_activism_outlined,
      emoji: '🎁',
      description: 'Ask for help or make an offer',
      eventKind: 31990, // Ask/Offer kind
      isEnabled: false, // To be implemented later
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
    // Determine which specialized composer to open based on the content type
    switch (contentType.label) {
      case 'Event':
        _openEventComposer(context, contentType);
        break;
      case 'Thread':
        _openThreadComposer(context, contentType);
        break;
      case 'Audio Room':
        _openAudioRoomComposer(context, contentType);
        break;
      case 'Question':
        _openQuestionComposer(context, contentType);
        break;
      case 'Ask/Offer':
        _openAskOfferComposer(context, contentType);
        break;
      case 'Livestream':
        _openLivestreamComposer(context, contentType);
        break;
      case 'Doc/Agenda':
        _openDocComposer(context, contentType);
        break;
      case 'Update':
      default:
        _openDefaultEditor(context, contentType);
        break;
    }
  }
  
  void _openDefaultEditor(BuildContext context, PostIntent contentType) {
    List<dynamic> tags = [];
    
    // Add custom tags if they exist
    if (contentType.customTags != null) {
      tags.addAll(contentType.customTags!);
    }
    
    // Open the standard editor
    EditorWidget.open(
      context,
      tags: tags,
      tagsAddedWhenSend: [],
      tagPs: [],
      // Set appropriate title based on content type
      customTitle: contentType.label,
    );
  }
  
  void _openThreadComposer(BuildContext context, PostIntent contentType) {
    List<dynamic> tags = [];
    
    if (contentType.customTags != null) {
      tags.addAll(contentType.customTags!);
    }
    
    // For threads, we'd typically add an e-tag for the parent
    // In a real implementation, we might want to show a UI to select which post to reply to
    // For now, we'll just open the composer with thread-specific configuration
    
    EditorWidget.open(
      context,
      tags: tags,
      tagsAddedWhenSend: [],
      tagPs: [],
      customTitle: contentType.label,
      isThread: true,
    );
  }
  
  void _openEventComposer(BuildContext context, PostIntent contentType) {
    // Navigate to the specialized event composer
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventComposerWidget(
          eventKind: contentType.eventKind,
          customTags: contentType.customTags,
        ),
      ),
    );
  }
  
  void _openAudioRoomComposer(BuildContext context, PostIntent contentType) {
    // For now, use the default editor but with the appropriate tags
    // In the future, create a specialized audio room composer
    List<dynamic> tags = [];
    
    if (contentType.customTags != null) {
      tags.addAll(contentType.customTags!);
    }
    
    // Add audio room specific tags
    tags.add(["t", "audio-room"]);
    
    EditorWidget.open(
      context,
      tags: tags,
      tagsAddedWhenSend: [],
      tagPs: [],
      customTitle: S.of(context).Create_Audio_Room,
    );
  }
  
  void _openQuestionComposer(BuildContext context, PostIntent contentType) {
    // Open poll input for questions
    List<dynamic> tags = [];
    
    if (contentType.customTags != null) {
      tags.addAll(contentType.customTags!);
    }
    
    EditorWidget.open(
      context,
      tags: tags,
      tagsAddedWhenSend: [],
      tagPs: [],
      isPoll: true,
      customTitle: S.of(context).Create_Poll,
    );
  }
  
  void _openAskOfferComposer(BuildContext context, PostIntent contentType) {
    // For now, use the default editor with appropriate tags
    List<dynamic> tags = [];
    
    if (contentType.customTags != null) {
      tags.addAll(contentType.customTags!);
    }
    
    tags.add(["t", "ask-offer"]);
    
    EditorWidget.open(
      context,
      tags: tags,
      tagsAddedWhenSend: [],
      tagPs: [],
      customTitle: contentType.label,
    );
  }
  
  void _openLivestreamComposer(BuildContext context, PostIntent contentType) {
    // For now, use the default editor with appropriate tags
    List<dynamic> tags = [];
    
    if (contentType.customTags != null) {
      tags.addAll(contentType.customTags!);
    }
    
    tags.add(["t", "livestream"]);
    
    EditorWidget.open(
      context,
      tags: tags,
      tagsAddedWhenSend: [],
      tagPs: [],
      customTitle: S.of(context).Create_Livestream,
    );
  }
  
  void _openDocComposer(BuildContext context, PostIntent contentType) {
    // For docs, use the long-form editor
    List<dynamic> tags = [];
    
    if (contentType.customTags != null) {
      tags.addAll(contentType.customTags!);
    }
    
    tags.add(["t", "document"]);
    
    EditorWidget.open(
      context,
      tags: tags,
      tagsAddedWhenSend: [],
      tagPs: [],
      isLongForm: true,
      customTitle: S.of(context).Create_Document,
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