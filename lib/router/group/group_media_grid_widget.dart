import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

import '../../consts/base.dart';
import '../../component/image_preview_dialog.dart';
import '../../provider/group_media_provider.dart';
import '../../util/theme_util.dart';
import '../../generated/l10n.dart';

/// Instagram-style grid view for displaying media posts from a group
class GroupMediaGridWidget extends StatefulWidget {
  /// The group identifier to show media for
  final GroupIdentifier groupId;
  
  const GroupMediaGridWidget({
    super.key,
    required this.groupId,
  });

  @override
  State<GroupMediaGridWidget> createState() => _GroupMediaGridWidgetState();
}

class _GroupMediaGridWidgetState extends State<GroupMediaGridWidget> {
  late GroupMediaProvider _mediaProvider;
  
  @override
  void initState() {
    super.initState();
    _mediaProvider = GroupMediaProvider(widget.groupId);
    _mediaProvider.fetchMedia();
  }
  
  @override
  void dispose() {
    _mediaProvider.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _mediaProvider,
      child: Consumer<GroupMediaProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final events = provider.mediaBox.all();
          
          if (events.isEmpty) {
            return _buildEmptyState(context);
          }
          
          return RefreshIndicator(
            onRefresh: () async {
              provider.refresh();
            },
            child: _buildMediaGrid(context, events, provider),
          );
        },
      ),
    );
  }
  
  /// Build the empty state message when no media is found
  Widget _buildEmptyState(BuildContext context) {
    final themeData = Theme.of(context);
    final customColors = themeData.customColors;
    final localization = S.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 48,
            color: customColors.dimmedColor,
          ),
          const SizedBox(height: 16),
          Text(
            localization.No_Media_found,
            style: TextStyle(
              color: customColors.secondaryForegroundColor,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            localization.Add_photos_to_posts,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: customColors.dimmedColor,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build the media grid with all images from posts
  Widget _buildMediaGrid(
    BuildContext context, 
    List<Event> events, 
    GroupMediaProvider provider
  ) {
    // Calculate grid parameters
    const crossAxisCount = 3;
    const spacing = 2.0;
    
    return GridView.builder(
      padding: const EdgeInsets.all(spacing),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: 1.0,
      ),
      itemCount: events.length,
      itemBuilder: (context, index) {
        return _buildMediaGridItem(
          context,
          event: events[index],
          provider: provider,
        );
      },
    );
  }
  
  /// Build an individual grid item for a media post
  Widget _buildMediaGridItem(
    BuildContext context, 
    {required Event event, required GroupMediaProvider provider}
  ) {
    // Get file metadata for the event
    final metadataList = provider.getFileMetadata(event.id);
    String? imageUrl;
    
    // Try to get the image URL from metadata first
    if (metadataList.isNotEmpty) {
      imageUrl = metadataList.first.url;
    } 
    // If no metadata, try to extract an image URL from the content
    else {
      imageUrl = _extractImageUrl(event.content);
    }
    
    // If still no URL, use a placeholder
    if (imageUrl == null) {
      return _buildPlaceholder(context, event);
    }
    
    // Build the grid tile with the image
    return InkWell(
      onTap: () {
        _openImagePreview(context, event, imageUrl!);
      },
      child: Hero(
        tag: 'media_${event.id}',
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => _buildLoadingPlaceholder(context),
          errorWidget: (context, url, error) => _buildPlaceholder(context, event),
        ),
      ),
    );
  }
  
  /// Build a loading placeholder for images
  Widget _buildLoadingPlaceholder(BuildContext context) {
    final themeData = Theme.of(context);
    final customColors = themeData.customColors;
    
    return Container(
      color: customColors.navBgColor,
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }
  
  /// Build a placeholder for items without valid images
  Widget _buildPlaceholder(BuildContext context, Event event) {
    final themeData = Theme.of(context);
    final customColors = themeData.customColors;
    
    return Container(
      color: customColors.navBgColor,
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 24,
          color: customColors.dimmedColor,
        ),
      ),
    );
  }
  
  /// Extract an image URL from event content
  String? _extractImageUrl(String content) {
    // Simple regex to find image URLs - this could be enhanced
    final RegExp imageRegex = RegExp(
      r'https?:\/\/[^\s]+\.(jpg|jpeg|png|gif|webp)',
      caseSensitive: false,
    );
    
    final match = imageRegex.firstMatch(content);
    if (match != null) {
      return match.group(0);
    }
    
    return null;
  }
  
  /// Open the image preview dialog
  void _openImagePreview(BuildContext context, Event event, String imageUrl) {
    ImagePreviewDialog.show(
      context: context,
      imageURL: imageUrl,
      heroTag: 'media_${event.id}',
      event: event,
    );
  }
}