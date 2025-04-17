import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nostr_sdk/nip29/group_identifier.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostrmo/component/user/user_pic_widget.dart';
import 'package:nostrmo/component/user/simple_name_widget.dart';
import 'package:nostrmo/data/group_identifier_repository.dart';
import 'package:nostrmo/data/group_metadata_repository.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/provider/user_provider.dart';
import '../models/response_model.dart';
import '../widgets/response_dialog.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:nostrmo/util/theme_util.dart';
import '../models/listing_model.dart';

class ListingCard extends ConsumerWidget {
  final ListingModel listing;
  final VoidCallback? onTap;

  const ListingCard({
    required this.listing,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeData = Theme.of(context);
    final customColors = themeData.customColors;
    final isDarkMode = themeData.brightness == Brightness.dark;
    
    // Define colors based on theme and listing type
    final Color askColor = isDarkMode ? Colors.blue.shade300 : Colors.blue;
    final Color offerColor = isDarkMode ? Colors.green.shade300 : Colors.green;
    
    // Ask header colors
    final Color askHeaderBg = isDarkMode 
        ? Colors.blue.shade900.withOpacity(0.4) 
        : Colors.blue.shade50;
    final Color askTextColor = isDarkMode 
        ? Colors.blue.shade200
        : Colors.blue.shade700;
        
    // Offer header colors
    final Color offerHeaderBg = isDarkMode 
        ? Colors.green.shade900.withOpacity(0.4) 
        : Colors.green.shade50;
    final Color offerTextColor = isDarkMode 
        ? Colors.green.shade200
        : Colors.green.shade700;
    
    // Calculate time remaining or status message
    String timeStatus = '';
    if (listing.expiresAt != null) {
      final daysRemaining = listing.expiresAt!.difference(DateTime.now()).inDays;
      if (daysRemaining > 0) {
        timeStatus = 'Available through ${_formatDate(listing.expiresAt!)}';
      } else {
        timeStatus = 'Expired';
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      clipBehavior: Clip.antiAlias,
      elevation: isDarkMode ? 1.0 : 0.5,
      color: customColors.feedBgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: customColors.separatorColor.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with type and category
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              decoration: BoxDecoration(
                color: listing.type == ListingType.ask 
                  ? askHeaderBg
                  : offerHeaderBg,
                border: Border(
                  bottom: BorderSide(
                    color: customColors.separatorColor.withOpacity(0.3),
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  _buildTypeIcon(isDarkMode: isDarkMode),
                  const SizedBox(width: 8),
                  Text(
                    listing.type == ListingType.ask ? 'ASK' : 'OFFER',
                    style: themeData.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: listing.type == ListingType.ask 
                        ? askTextColor 
                        : offerTextColor,
                    ),
                  ),
                  const Spacer(),
                  _buildStatusChip(context, isDarkMode: isDarkMode),
                ],
              ),
            ),
            
            // Content area
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    listing.title,
                    style: themeData.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Preview of content
                  Text(
                    listing.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: themeData.textTheme.bodyMedium,
                  ),
                  
                  // Image preview if available
                  if (listing.imageUrls.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.network(
                        listing.imageUrls.first,
                        height: 140,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                  
                  // Info row
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Author info
                      _buildUserInfo(ref),
                      
                      if (listing.groupId != null) ...[
                        const Text(' • '),
                        _buildGroupInfo(ref),
                      ],
                      
                      const Spacer(),
                      
                      // Location if available
                      if (listing.location != null) ...[
                        const Icon(Icons.location_on_outlined, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          listing.location!,
                          style: themeData.textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                  
                  // Time status 
                  if (timeStatus.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      timeStatus,
                      style: themeData.textTheme.bodySmall?.copyWith(
                        color: listing.expiresAt != null && 
                              listing.expiresAt!.isBefore(DateTime.now())
                          ? Colors.red
                          : customColors.secondaryForegroundColor,
                      ),
                    ),
                  ],
                  
                  // Price if available
                  if (listing.price != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      listing.price!,
                      style: themeData.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Action buttons
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: customColors.separatorColor.withOpacity(0.3),
                    width: 0.5,
                  ),
                ),
              ),
              child: _buildActionButtons(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeIcon({bool isDarkMode = false}) {
    final Color askIconColor = isDarkMode ? Colors.blue.shade300 : Colors.blue;
    final Color offerIconColor = isDarkMode ? Colors.green.shade300 : Colors.green;
    
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: listing.type == ListingType.ask ? askIconColor : offerIconColor,
        shape: BoxShape.circle,
      ),
      child: Icon(
        listing.type == ListingType.ask ? Icons.help_outline : Icons.local_offer_outlined,
        color: Colors.white,
        size: 14,
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, {bool isDarkMode = false}) {
    Color getStatusColor() {
      switch (listing.status) {
        case ListingStatus.active:
          return isDarkMode ? Colors.green.shade300 : Colors.green;
        case ListingStatus.inactive:
          return isDarkMode ? Colors.grey.shade400 : Colors.grey;
        case ListingStatus.fulfilled:
          return isDarkMode ? Colors.blue.shade300 : Colors.blue;
        case ListingStatus.expired:
          return isDarkMode ? Colors.red.shade300 : Colors.red;
        case ListingStatus.cancelled:
          return isDarkMode ? Colors.orange.shade300 : Colors.orange;
      }
    }

    // Only show status if not active
    if (listing.status == ListingStatus.active) {
      return const SizedBox.shrink();
    }

    Color statusColor = getStatusColor();
    Color bgColor = isDarkMode 
        ? statusColor.withOpacity(0.2) 
        : statusColor.withOpacity(0.1);
    Color borderColor = isDarkMode 
        ? statusColor.withOpacity(0.6) 
        : statusColor.withOpacity(0.5);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
      ),
      child: Text(
        listing.status.name.toUpperCase(),
        style: TextStyle(
          color: statusColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final themeData = Theme.of(context);
    final customColors = themeData.customColors;
    final isDarkMode = themeData.brightness == Brightness.dark;
    
    // Define action button colors based on theme
    final Color askActionColor = isDarkMode ? Colors.blue.shade300 : Colors.blue;
    final Color offerActionColor = isDarkMode ? Colors.green.shade300 : Colors.green;
    final Color messageColor = isDarkMode 
        ? customColors.primaryForegroundColor 
        : themeData.primaryColor;
    final Color thanksColor = isDarkMode ? Colors.red.shade300 : Colors.red;
    
    // Active listings get action buttons
    if (listing.status == ListingStatus.active) {
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (listing.type == ListingType.ask)
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                      _showResponseDialog(context, ResponseType.help);
                    },
                    icon: Icon(Icons.volunteer_activism, size: 16, color: askActionColor),
                    label: Text('I can help!', style: TextStyle(color: askActionColor)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    ),
                  ),
                )
              else
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                      _showResponseDialog(context, ResponseType.interest);
                    },
                    icon: Icon(Icons.thumb_up_outlined, size: 16, color: offerActionColor),
                    label: Text('Interested', style: TextStyle(color: offerActionColor)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    ),
                  ),
                ),
              
              VerticalDivider(
                width: 1,
                thickness: 1,
                indent: 8,
                endIndent: 8,
                color: customColors.separatorColor.withOpacity(0.5),
              ),
              
              Expanded(
                child: TextButton.icon(
                  onPressed: () {
                    _showResponseDialog(context, ResponseType.question);
                  },
                  icon: Icon(Icons.help_outline, size: 16, color: Colors.orange),
                  label: Text('Question', style: TextStyle(color: Colors.orange)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  ),
                ),
              ),
            ],
          ),
          
          Divider(
            height: 1,
            thickness: 1,
            color: customColors.separatorColor.withOpacity(0.3),
          ),
          
          TextButton.icon(
            onPressed: () {
              // Use the global dmProvider to create a session
              final detail = dmProvider.findOrNewADetail(listing.pubkey);
              // Navigate to DM screen with the session detail
              RouterUtil.router(context, RouterPath.dmDetail, detail);
            },
            icon: Icon(Icons.message_outlined, size: 16, color: messageColor),
            label: Text('Direct Message', style: TextStyle(color: messageColor)),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            ),
          ),
        ],
      );
    } 
    // Fulfilled listings get a "say thanks" option
    else if (listing.status == ListingStatus.fulfilled) {
      return TextButton.icon(
        onPressed: () {
          // TODO: Implement thanks action
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Feature coming soon: Say thanks')),
          );
        },
        icon: Icon(Icons.favorite_border, color: thanksColor, size: 16),
        label: Text('Say thanks', style: TextStyle(color: thanksColor)),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        ),
      );
    }
    // Otherwise show a plain status
    else {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Text(
          'This ${listing.type == ListingType.ask ? 'ask' : 'offer'} is ${listing.status.name}',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: customColors.secondaryForegroundColor,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }
  }

  Widget _buildUserInfo(WidgetRef ref) {
    final themeData = Theme.of(ref.context);
    final pubkey = listing.pubkey;
    
    if (pubkey.isEmpty) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.person_outline, size: 16),
          SizedBox(width: 4),
          Text(
            'Anonymous User',
            style: TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }
    
    // Use the global userProvider to get user data
    final user = userProvider.getUser(pubkey);
    
    return GestureDetector(
      onTap: () {
        // Navigate to user profile
        RouterUtil.router(ref.context, RouterPath.user, pubkey);
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // User avatar
          SizedBox(
            width: 20,
            height: 20,
            child: UserPicWidget(
              pubkey: pubkey,
              width: 20,
            ),
          ),
          const SizedBox(width: 4),
          // User name
          SimpleNameWidget(
            pubkey: pubkey,
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildGroupInfo(WidgetRef ref) {
    if (listing.groupId == null) return const SizedBox.shrink();
    
    // Extract host from group identifier format (host:id)
    String? host;
    String groupIdFormatted = listing.groupId!;
    
    if (listing.groupId!.contains(':')) {
      final parts = listing.groupId!.split(':');
      host = parts[0];
      groupIdFormatted = parts[1];
    }
    
    // Create GroupIdentifier if both host and id are available
    GroupIdentifier? groupIdentifier;
    if (host != null) {
      groupIdentifier = GroupIdentifier(host, groupIdFormatted);
    }
    
    // Default widget with just the ID
    Widget defaultWidget = Text(
      'Group: $groupIdFormatted',
      style: const TextStyle(
        fontWeight: FontWeight.w500,
      ),
    );
    
    // If we can construct a group identifier, use it to fetch metadata
    if (groupIdentifier != null) {
      final groupMetadataAsync = ref.watch(groupMetadataProvider(groupIdentifier!));
      
      return groupMetadataAsync.when(
        data: (metadata) {
          if (metadata == null) return defaultWidget;
          
          return GestureDetector(
            onTap: () {
              // Navigate to group detail
              RouterUtil.router(ref.context, RouterPath.groupDetail, groupIdentifier);
            },
            child: Text(
              metadata.displayName ?? metadata.name ?? 'Group: $groupIdFormatted',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          );
        },
        loading: () => defaultWidget,
        error: (_, __) => defaultWidget,
      );
    }
    
    return defaultWidget;
  }

  void _showResponseDialog(BuildContext context, ResponseType initialType) {
    showDialog(
      context: context,
      builder: (dialogContext) => ResponseDialog(
        listing: listing,
        initialResponseType: initialType,
      ),
    ).then((result) {
      if (result == true && context.mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Response sent successfully')),
        );
      }
    });
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }
} 