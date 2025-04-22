import 'package:flutter/material.dart';
import 'package:get_time_ago/get_time_ago.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/component/content/content_widget.dart';
import 'package:nostrmo/component/content/content_image_widget.dart';
import 'package:nostrmo/component/content/content_video_widget.dart';
import 'package:nostrmo/component/json_view_dialog.dart';
import 'package:nostrmo/consts/plur_colors.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostrmo/util/router_util.dart';
import 'dart:convert';
import 'package:provider/provider.dart';

import '../../component/user/user_pic_widget.dart';
import '../../consts/base.dart';
import '../../consts/base_consts.dart';
import '../../provider/settings_provider.dart';
import '../group/group_detail_chat_widget.dart';
import 'dm_plaintext_handle.dart';

class DMDetailItemWidget extends StatefulWidget {
  final String sessionPubkey;

  final Event event;

  final bool isLocal;
  
  final String? replyToId;

  const DMDetailItemWidget({
    super.key, 
    required this.sessionPubkey,
    required this.event,
    required this.isLocal,
    this.replyToId,
  });

  @override
  State<StatefulWidget> createState() {
    return _DMDetailItemWidgetState();
  }
}

class _DMDetailItemWidgetState extends State<DMDetailItemWidget>
    with DMPlaintextHandle {
  static const double imageWidth = 34;
  static const double blankWidth = 50;
  
  // Global caches for shared use across instances
  static final Map<String, Map<String, dynamic>> _mediaInfoCacheGlobal = {};
  static final Map<String, Map<String, double>> _dimensionCacheGlobal = {};
  
  // Prevent unnecessary rebuilds on message content changes
  bool _contentProcessed = false;
  String _displayContent = "";
  
  // Flag to track expensive UI operations
  bool _isProcessingMedia = false;

  @override
  @override
  void initState() {
    super.initState();
    _processContentWithoutRebuild();
  }
  
  /// Process the content in a non-reactive way to avoid unnecessary rebuilds
  void _processContentWithoutRebuild() {
    if (_contentProcessed) return;
    
    // Check if we need to decrypt
    if (widget.event.kind == EventKind.directMessage) {
      String? cached = _getDecryptedContent();
      if (cached == null) {
        // Queue for decryption without triggering a rebuild
        _queueDecryption();
      }
    }
    
    // Mark as processed to avoid repeating this work
    _contentProcessed = true;
    
    // Schedule media info processing in the next frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _processMediaInfo();
      }
    });
  }
  
  /// Get decrypted content from cache
  String? _getDecryptedContent() {
    // First check if the event ID matches our current event (fastest)
    if (widget.event.id == currentPlainEventId && plainContent != null) {
      _displayContent = plainContent!;
      return plainContent;
    }
    
    // Try the DMProvider's static cache (this is now persistent)
    try {
      final dmProvider = Provider.of<dynamic>(context, listen: false);
      if (dmProvider.getDecryptedContent != null) {
        final cachedContent = dmProvider.getDecryptedContent(widget.event.id);
        if (cachedContent != null) {
          _displayContent = cachedContent;
          // If we found it in provider's cache, update our local cache too
          DMPlaintextHandle.decryptionCache[widget.event.id] = cachedContent;
          return cachedContent;
        }
      }
    } catch (e) {
      // Provider not available, fall back to local cache
    }
    
    // Finally check the DMPlaintextHandle static cache
    if (DMPlaintextHandle.decryptionCache.containsKey(widget.event.id)) {
      final cached = DMPlaintextHandle.decryptionCache[widget.event.id];
      _displayContent = cached!;
      
      // If we found it in local cache but not provider, update provider
      try {
        final dmProvider = Provider.of<dynamic>(context, listen: false);
        if (dmProvider.cacheDecryptedContent != null) {
          dmProvider.cacheDecryptedContent(widget.event.id, cached);
        }
      } catch (e) {
        // Provider not available, that's OK
      }
      
      return cached;
    }
    
    return null;
  }
  
  /// Queue decryption without triggering a state update
  void _queueDecryption() {
    // Use the DMPlaintextHandle mixin's method
    handleEncryptedText(widget.event, widget.sessionPubkey);
  }
  
  /// Process media information for the message
  void _processMediaInfo() {
    if (_isProcessingMedia) return;
    
    _isProcessingMedia = true;
    
    try {
      // Cache for parsed media information by event ID
      final Map<String, Map<String, dynamic>> mediaInfoCache = _DMDetailItemWidgetState._mediaInfoCacheGlobal;
      
      // Use cached content if available
      String content = plainContent ?? widget.event.content;
      
      // Skip if the media info is already cached
      if (!mediaInfoCache.containsKey(widget.event.id)) {
        bool containsMedia = false;
        String? mediaUrl;
        String contentType = "text";
        String? blurhash;
        String? dimensions;
        
        // First check for imeta tags which provide better metadata for images
        for (final tag in widget.event.tags) {
          if (tag.isNotEmpty && tag[0] == "imeta" && tag.length > 1) {
            // Parse the imeta tag data
            for (int i = 1; i < tag.length; i++) {
              String item = tag[i];
              if (item.startsWith("url ")) {
                mediaUrl = item.substring(4).trim();
                contentType = "image";
                containsMedia = true;
              } else if (item.startsWith("blurhash ")) {
                blurhash = item.substring(9).trim();
              } else if (item.startsWith("dim ")) {
                dimensions = item.substring(4).trim();
              }
            }
            
            // Break since we found what we needed
            if (containsMedia) break;
          }
        }
        
        // If we didn't find media in imeta tags, check the content directly
        if (!containsMedia) {
          // Simple URL detection for images and videos
          final urlPattern = RegExp(r'https?:\/\/[^\s]+\.(jpg|jpeg|png|gif|mp4|webm|mov|bin)');
          final match = urlPattern.firstMatch(content);
          if (match != null) {
            mediaUrl = match.group(0);
            final extension = match.group(1)?.toLowerCase();
            
            if (extension == 'jpg' || extension == 'jpeg' || extension == 'png' || extension == 'gif' || extension == 'bin') {
              contentType = "image";
              containsMedia = true;
            } else if (extension == 'mp4' || extension == 'webm' || extension == 'mov') {
              contentType = "video";
              containsMedia = true;
            }
          }
        }
        
        // Cache the results
        mediaInfoCache[widget.event.id] = {
          'containsMedia': containsMedia,
          'mediaUrl': mediaUrl,
          'contentType': contentType,
          'blurhash': blurhash,
          'dimensions': dimensions,
        };
      }
    } finally {
      _isProcessingMedia = false;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // Ensure content is processed
    if (!_contentProcessed) {
      _processContentWithoutRebuild();
    }
    
    // Get cached data or process it now
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    final themeData = Theme.of(context);
    final mainColor = themeData.primaryColor;
    final smallTextSize = themeData.textTheme.bodySmall!.fontSize;
    final hintColor = themeData.hintColor;
    
    // Get time string
    final timeStr = GetTimeAgo.parse(
        DateTime.fromMillisecondsSinceEpoch(widget.event.createdAt * 1000));
    
    // Check if we need to update content display
    if (currentPlainEventId != widget.event.id) {
      plainContent = null;
    }
    
    // Get content for display
    String content = _displayContent;
    if (StringUtil.isBlank(content)) {
      content = widget.event.content;
    }
    
    // Handle decryption if needed
    if (widget.event.kind == EventKind.directMessage && 
        StringUtil.isBlank(plainContent)) {
      handleEncryptedText(widget.event, widget.sessionPubkey);
      
      // Check if we got content from the cache
      if (StringUtil.isNotBlank(plainContent)) {
        content = plainContent!;
      }
    }
    
    // Create the user avatar widget with shadow
    final userHeadWidget = RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.only(top: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(imageWidth / 2),
          boxShadow: [
            BoxShadow(
              color: themeData.brightness == Brightness.dark 
                ? Colors.black.withOpacity(0.1)
                : Colors.black.withOpacity(0.15),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: UserPicWidget(
          pubkey: widget.event.pubkey,
          width: imageWidth,
        ),
      ),
    );
    
    // Get media info from cache
    final Map<String, Map<String, dynamic>> mediaInfoCache = _DMDetailItemWidgetState._mediaInfoCacheGlobal;
    
    // Default values
    bool containsMedia = false;
    String? mediaUrl;
    String contentType = "text";
    String? blurhash;
    String? dimensions;
    
    // Use cached media info if available
    if (mediaInfoCache.containsKey(widget.event.id)) {
      final cachedInfo = mediaInfoCache[widget.event.id]!;
      containsMedia = cachedInfo['containsMedia'] ?? false;
      mediaUrl = cachedInfo['mediaUrl'];
      contentType = cachedInfo['contentType'] ?? 'text';
      blurhash = cachedInfo['blurhash'];
      dimensions = cachedInfo['dimensions'];
    }
    
    // Prepare display content
    String displayContent = content;
    if (containsMedia && mediaUrl != null) {
      // Remove the media URL from the text content to avoid duplication
      displayContent = content.replaceAll(mediaUrl, '').trim();
    }
    
    // Format content for display
    displayContent = displayContent.replaceAll("\r", " ");
    displayContent = displayContent.replaceAll("\n", " ");
    
    // Message metadata row elements with consistent styling
    final timeWidget = Text(
      timeStr,
      style: GoogleFonts.nunito(
        textStyle: PlurColors.timestampStyle(context),
      ),
    );
    
    // Show encryption icon if needed
    Widget enhancedIcon = Container();
    if (widget.event.kind == EventKind.privateDirectMessage) {
      enhancedIcon = Container(
        margin: const EdgeInsets.only(
          left: Base.basePaddingHalf,
          right: Base.basePaddingHalf,
        ),
        child: Icon(
          Icons.enhanced_encryption,
          size: 14,
          color: PlurColors.secondaryTextColor(context),
        ),
      );
    }
    
    // Create the message header with time and encryption status
    final List<Widget> topList = [];
    if (widget.isLocal) {
      topList.add(enhancedIcon);
      topList.add(timeWidget);
    } else {
      topList.add(timeWidget);
      topList.add(enhancedIcon);
    }
    
    // Build reply indicator if this is a reply
    Widget? replyIndicator;
    if (widget.replyToId != null) {
      replyIndicator = Container(
        margin: const EdgeInsets.only(bottom: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.reply,
              size: 14,
              color: PlurColors.secondaryTextColor(context),
            ),
            const SizedBox(width: 4),
            Text(
              'Reply',
              style: GoogleFonts.nunito(
                textStyle: TextStyle(
                  fontSize: 12,
                  color: PlurColors.secondaryTextColor(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    var contentWidget = Container(
      margin: const EdgeInsets.only(
        left: Base.basePaddingHalf,
        right: Base.basePaddingHalf,
      ),
      child: Column(
        crossAxisAlignment:
            !widget.isLocal ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: topList,
          ),
          if (replyIndicator != null) replyIndicator,
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.only(
              top: Base.basePaddingHalf,
              right: Base.basePadding,
              bottom: Base.basePaddingHalf,
              left: Base.basePadding,
            ),
            decoration: BoxDecoration(
              color: widget.isLocal 
                ? (themeData.brightness == Brightness.dark 
                    ? PlurColors.buttonBackground.withOpacity(0.25) 
                    : PlurColors.buttonBackground.withOpacity(0.15))
                : PlurColors.cardBg(context),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(!widget.isLocal ? 4 : 16),
                topRight: Radius.circular(widget.isLocal ? 4 : 16),
                bottomLeft: const Radius.circular(16),
                bottomRight: const Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: themeData.brightness == Brightness.dark 
                    ? Colors.black.withOpacity(0.05)
                    : Colors.black.withOpacity(0.1),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: GestureDetector(
              onLongPress: () {
                // Show context menu with reply option
                final renderObj = context.findRenderObject();
                final overlayObj = Overlay.of(context).context.findRenderObject();
                
                // Safety check for null or incorrect type
                if (renderObj == null || overlayObj == null || 
                    renderObj is! RenderBox || overlayObj is! RenderBox) {
                  return; // Exit if we can't get valid render objects
                }
                
                final RenderBox renderBox = renderObj;
                final RenderBox overlay = overlayObj;
                final RelativeRect position = RelativeRect.fromRect(
                  Rect.fromPoints(
                    renderBox.localToGlobal(Offset.zero, ancestor: overlay),
                    renderBox.localToGlobal(renderBox.size.bottomRight(Offset.zero), ancestor: overlay),
                  ),
                  Offset.zero & overlay.size,
                );
                
                showMenu(
                  context: context,
                  position: position,
                  items: [
                    PopupMenuItem(
                      value: 'reply',
                      child: Row(
                        children: [
                          Icon(Icons.reply, color: themeData.brightness == Brightness.dark 
                            ? null 
                            : PlurColors.lightPrimaryText),
                          const SizedBox(width: 8),
                          Text('Reply', style: TextStyle(
                            color: themeData.brightness == Brightness.dark 
                              ? null 
                              : PlurColors.lightPrimaryText,
                          )),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'view_raw',
                      child: Row(
                        children: [
                          Icon(Icons.code, color: themeData.brightness == Brightness.dark 
                            ? null 
                            : PlurColors.lightPrimaryText),
                          const SizedBox(width: 8),
                          Text('View Raw Event', style: TextStyle(
                            color: themeData.brightness == Brightness.dark 
                              ? null 
                              : PlurColors.lightPrimaryText,
                          )),
                        ],
                      ),
                    ),
                  ],
                ).then((value) {
                  if (value == 'reply') {
                    // Notify parent to set up reply
                    final chatWidget = context.findAncestorStateOfType<GroupDetailChatWidgetState>();
                    if (chatWidget != null) {
                      chatWidget.setReplyToEvent(widget.event);
                    }
                  } else if (value == 'view_raw') {
                    // Show the raw event in a JSON viewer
                    _showRawEvent();
                  }
                });
              },
              child: Column(
                crossAxisAlignment: widget.isLocal
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Show text content if available
                  if (displayContent.isNotEmpty)
                    displayContent.length < 100 ? 
                    // Use simple Text widget for short messages to apply our styling
                    Text(
                      displayContent,
                      style: GoogleFonts.nunito(
                        textStyle: TextStyle(
                          color: PlurColors.textColor(context),
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          height: 1.35,
                        ),
                      ),
                    ) :
                    // Use ContentWidget for complex messages with links
                    ContentWidget(
                      content: displayContent,
                      event: widget.event,
                      showLinkPreview: settingsProvider.linkPreview == OpenStatus.open,
                      showImage: false,  // Don't show images in the text content
                      showVideo: false,  // Don't show videos in the text content
                      smallest: true,
                    ),
                  
                  // Add spacing if we have both text and media
                  if (displayContent.isNotEmpty && containsMedia)
                    const SizedBox(height: 8),
                  
                  // Show inline media if available
                  if (containsMedia && mediaUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: contentType == "image" 
                        ? _buildImageWidget(mediaUrl, blurhash, dimensions)
                        : ContentVideoWidget(
                            url: mediaUrl,
                            width: 200,  // Set reasonable width for chat bubble
                            height: 150,  // Set reasonable height for chat bubble
                          ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    // Create a clickable user head widget
    final clickableUserHeadWidget = GestureDetector(
      onTap: () {
        RouterUtil.router(context, RouterPath.user, widget.event.pubkey);
      },
      child: userHeadWidget,
    );

    List<Widget> list = [];
    if (widget.isLocal) {
      list.add(Container(width: blankWidth));
      list.add(Expanded(child: contentWidget));
      list.add(clickableUserHeadWidget);
    } else {
      list.add(clickableUserHeadWidget);
      list.add(Expanded(child: contentWidget));
      list.add(Container(width: blankWidth));
    }

    return Container(
      padding: const EdgeInsets.all(Base.basePaddingHalf),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: list,
      ),
    );
  }
  
  /// Builds an image widget with proper sizing based on the image's dimensions
  /// and with blurhash loading support if available.
  /// 
  /// - [imageUrl] The URL of the image to display
  /// - [blurhash] Optional blurhash for smoother loading
  /// - [dimensions] Optional dimensions in format "widthxheight"
  Widget _buildImageWidget(String imageUrl, String? blurhash, String? dimensions) {
    // Default dimensions for the chat bubble
    double width = 200;
    double height = 150;
    
    // Quick dimension check with caching for repeated dimensions
    final Map<String, Map<String, double>> dimensionCache = _DMDetailItemWidgetState._dimensionCacheGlobal;
    
    if (dimensions != null) {
      if (dimensionCache.containsKey(dimensions)) {
        // Use cached dimension calculations
        final cachedDimensions = dimensionCache[dimensions]!;
        width = cachedDimensions['width']!;
        height = cachedDimensions['height']!;
      } else {
        final parts = dimensions.split('x');
        if (parts.length == 2) {
          try {
            final originalWidth = int.parse(parts[0]);
            final originalHeight = int.parse(parts[1]);
            
            // Calculate aspect ratio
            final aspectRatio = originalWidth / originalHeight;
            
            // Maintain aspect ratio with max width of 200
            width = 200;
            height = width / aspectRatio;
            
            // Cap height if it gets too tall
            if (height > 300) {
              height = 300;
              width = height * aspectRatio;
            }
            
            // Cache the calculated dimensions
            dimensionCache[dimensions] = {
              'width': width,
              'height': height,
            };
            
          } catch (e) {
            // Parsing error, use defaults
          }
        }
      }
    }
    
    // Create FileMetadata object if we have blurhash (more efficiently)
    FileMetadata? fileMetadata;
    if (blurhash != null) {
      // Only create the object with the minimum required fields
      fileMetadata = FileMetadata(
        imageUrl,
        "image/jpeg", // Assume JPEG as default type
        blurhash: blurhash,
        dim: dimensions,
      );
    }
    
    return ContentImageWidget(
      imageUrl: imageUrl,
      width: width,
      height: height,
      imageBoxFix: BoxFit.cover,
      fileMetadata: fileMetadata,
    );
  }
  
  /// Shows a dialog with the raw JSON data of the current event.
  /// Used for debugging purposes to inspect event structure,
  /// especially for media messages with imeta tags.
  void _showRawEvent() {
    // Convert event to a map that can be easily viewed
    final eventMap = {
      'id': widget.event.id,
      'pubkey': widget.event.pubkey,
      'created_at': widget.event.createdAt,
      'kind': widget.event.kind,
      'tags': widget.event.tags,
      'content': widget.event.content,
      'sig': widget.event.sig,
    };
    
    // Convert to pretty-printed JSON
    final prettyJson = const JsonEncoder.withIndent('  ').convert(eventMap);
    
    // Store context in local variable to avoid async gap warning
    final currentContext = context;
    
    // Show dialog with the JSON content
    JsonViewDialog.show(currentContext, prettyJson);
  }
}
