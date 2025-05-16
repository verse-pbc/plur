import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:easy_image_viewer/easy_image_viewer.dart';

import '../../component/image_preview_dialog.dart';
import '../../component/content/content_image_widget.dart';
import '../../provider/group_media_provider.dart';
import '../../theme/app_colors.dart';
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
    final localization = S.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 48,
            color: context.colors.dimmed,
          ),
          const SizedBox(height: 16),
          Text(
            localization.noMediaFound,
            style: TextStyle(
              color: context.colors.secondaryText,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            localization.addPhotosToYourPosts,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.colors.dimmed,
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
  
  /// Build an individual grid item for a media post following NIP-92
  Widget _buildMediaGridItem(
    BuildContext context, 
    {required Event event, required GroupMediaProvider provider}
  ) {
    // Get file metadata for the event
    final metadataList = provider.getFileMetadata(event.id);
    if (metadataList.isEmpty) {
      // If there's no metadata, we shouldn't even be here according to our filter
      // but just in case, show a placeholder
      return _buildPlaceholder(context, event);
    }
    
    // Get the first metadata entry (typically there's only one per event)
    final metadata = metadataList.first;
    String? imageUrl;
    
    // According to NIP-92, we should prioritize in this order:
    // 1. thumb - smaller representation of the resource
    // 2. image - another representation (may be original or processed)
    // 3. url - the main resource URL
    imageUrl = metadata.thumb ?? metadata.image ?? metadata.url;
    
    // Make sure we have a URL (should always be the case since url is required in NIP-92)
    if (imageUrl.isEmpty) {
      return _buildPlaceholder(context, event);
    }
    
    // Check if this is an image or video type we can display
    // Strictly follow NIP-92 mime type
    final mimeType = metadata.m.toLowerCase();
    final isImage = mimeType.startsWith('image/');
    final isVideo = mimeType.startsWith('video/');
    
    if (!isImage && !isVideo) {
      // If it's not an image or video type, use a placeholder
      return _buildPlaceholder(context, event);
    }
    
    // Debug information
    print('Event ${event.id.substring(0, 8)} mime type: $mimeType');
    print('Using media URL: $imageUrl');
    
    // Use the same ContentImageWidget that's used elsewhere in the app
    // for consistent image loading and rendering
    return GestureDetector(
      onTap: () {
        _openImagePreview(context, event, imageUrl!);
      },
      child: ClipRect(
        child: SizedBox.expand(
          child: Hero(
            tag: 'media_${event.id}',
            child: ContentImageWidget(
              imageUrl: imageUrl,
              fileMetadata: metadata,
              imageBoxFix: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
  
  // Removed blurhash placeholder method as it's handled by ContentImageWidget
  
  /// Build a loading placeholder for images
  Widget _buildLoadingPlaceholder(BuildContext context) {
    final themeData = Theme.of(context);
    
    return Container(
      color: context.colors.primary,
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
    
    return Container(
      color: context.colors.primary,
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 24,
          color: context.colors.dimmed,
        ),
      ),
    );
  }
  
  /// Open the image preview dialog
  void _openImagePreview(BuildContext context, Event event, String imageUrl) {
    // Create a CachedNetworkImageProvider for better performance
    final imageProvider = SingleImageProvider(
      CachedNetworkImageProvider(imageUrl),
    );
    
    // Show the image preview dialog with the created provider
    ImagePreviewDialog.show(
      context,
      imageProvider,
      doubleTapZoomable: true,
      swipeDismissible: true,
    );
  }
}