import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:nostrmo/util/theme_util.dart';
import '../models/listing_model.dart';
import '../providers/listing_provider.dart';
import 'create_edit_listing_screen.dart';

class ListingDetailScreen extends ConsumerWidget {
  final ListingModel listing;

  const ListingDetailScreen({
    required this.listing,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeData = Theme.of(context);
    final customColors = themeData.customColors;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(listing.type == ListingType.ask ? 'Ask Details' : 'Offer Details'),
        actions: [
          if (listing.status == ListingStatus.active) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => CreateEditListingScreen(
                      listing: listing,
                      groupId: listing.groupId,
                    ),
                  ),
                );
              },
            ),
            PopupMenuButton<ListingStatus>(
              icon: const Icon(Icons.more_vert),
              onSelected: (ListingStatus status) {
                ref.read(listingProvider.notifier).updateListing(
                  listing.copyWith(status: status),
                );
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<ListingStatus>>[
                const PopupMenuItem<ListingStatus>(
                  value: ListingStatus.fulfilled,
                  child: Text('Mark as Fulfilled'),
                ),
                const PopupMenuItem<ListingStatus>(
                  value: ListingStatus.cancelled,
                  child: Text('Mark as Cancelled'),
                ),
                const PopupMenuItem<ListingStatus>(
                  value: ListingStatus.inactive,
                  child: Text('Mark as Inactive'),
                ),
              ],
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with type and status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              decoration: BoxDecoration(
                color: listing.type == ListingType.ask 
                  ? Colors.blue.withOpacity(0.1)
                  : Colors.green.withOpacity(0.1),
                border: Border(
                  bottom: BorderSide(
                    color: customColors.separatorColor.withOpacity(0.3),
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  _buildTypeIcon(),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        listing.type == ListingType.ask ? 'ASK' : 'OFFER',
                        style: themeData.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: listing.type == ListingType.ask ? Colors.blue : Colors.green,
                        ),
                      ),
                      Text(
                        listing.title,
                        style: themeData.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  _buildStatusBadge(context),
                ],
              ),
            ),
            
            // Images
            if (listing.imageUrls.isNotEmpty)
              SizedBox(
                height: 220,
                child: PageView.builder(
                  itemCount: listing.imageUrls.length,
                  itemBuilder: (context, index) {
                    return Image.network(
                      listing.imageUrls[index],
                      fit: BoxFit.cover,
                    );
                  },
                ),
              ),
              
            // Content
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Author info
                  Row(
                    children: [
                      CircleAvatar(
                        // TODO: Replace with actual user image
                        backgroundColor: themeData.primaryColor.withOpacity(0.2),
                        child: const Icon(Icons.person_outline),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // TODO: Replace with actual username
                          const Text(
                            'Username',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Posted ${_formatRelativeTime(listing.createdAt)}',
                            style: themeData.textTheme.bodySmall?.copyWith(
                              color: customColors.secondaryForegroundColor,
                            ),
                          ),
                        ],
                      ),
                      if (listing.groupId != null) ...[
                        const Spacer(),
                        // TODO: Replace with actual group name
                        Chip(
                          label: const Text('Group Name'),
                          backgroundColor: customColors.feedBgColor,
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Description
                  Text(
                    listing.content,
                    style: themeData.textTheme.bodyLarge,
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Details list
                  Card(
                    elevation: 0,
                    color: customColors.feedBgColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          if (listing.price != null)
                            ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.attach_money, color: Colors.green),
                              ),
                              title: const Text('Price'),
                              subtitle: Text(
                                listing.price!,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ),
                            
                          if (listing.location != null)
                            ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.location_on, color: Colors.orange),
                              ),
                              title: const Text('Location'),
                              subtitle: Text(listing.location!),
                            ),
                            
                          if (listing.expiresAt != null)
                            ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.timer, color: Colors.purple),
                              ),
                              title: const Text('Available Until'),
                              subtitle: Text(_formatDate(listing.expiresAt!)),
                            ),
                            
                          if (listing.paymentInfo != null)
                            ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.payment, color: Colors.blue),
                              ),
                              title: const Text('Payment Information'),
                              subtitle: Text(listing.paymentInfo!),
                            ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Comments section header (for future implementation)
                  Row(
                    children: [
                      Text(
                        'Replies',
                        style: themeData.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: themeData.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '0', // Placeholder for future comment count
                          style: TextStyle(
                            color: themeData.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // Placeholder for future comments implementation
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: Center(
                      child: Text(
                        'Comments feature coming soon',
                        style: TextStyle(
                          color: customColors.secondaryForegroundColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomActions(context, ref),
    );
  }
  
  Widget _buildBottomActions(BuildContext context, WidgetRef ref) {
    if (listing.status == ListingStatus.active) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: Theme.of(context).canvasColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, -1),
              blurRadius: 4,
            ),
          ],
        ),
        child: Row(
          children: [
            if (listing.type == ListingType.ask)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Implement help action
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Feature coming soon: I can help')),
                    );
                  },
                  icon: const Icon(Icons.volunteer_activism),
                  label: const Text('I can help!'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              )
            else
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Implement interest action
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Feature coming soon: I\'m interested')),
                    );
                  },
                  icon: const Icon(Icons.thumb_up_outlined),
                  label: const Text('I\'m interested'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            const SizedBox(width: 16),
            // Owner actions
            if (_isCurrentUserOwner()) ...[
              OutlinedButton.icon(
                onPressed: () {
                  _showStatusChangeDialog(context, ref);
                },
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Mark as Fulfilled'),
              ),
            ]
            // Non-owner actions
            else ...[
              OutlinedButton.icon(
                onPressed: () {
                  // Use the global dmProvider to create a session
                  final detail = dmProvider.findOrNewADetail(listing.pubkey);
                  // Navigate to DM screen with the session detail
                  RouterUtil.router(context, RouterPath.dmDetail, detail);
                },
                icon: const Icon(Icons.message_outlined),
                label: const Text('Message'),
              ),
            ],
          ],
        ),
      );
    } 
    // Fulfilled listings get a "say thanks" option
    else if (listing.status == ListingStatus.fulfilled && !_isCurrentUserOwner()) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: Theme.of(context).canvasColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, -1),
              blurRadius: 4,
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: () {
            // TODO: Implement thanks action
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Feature coming soon: Say thanks')),
            );
          },
          icon: const Icon(Icons.favorite_border),
          label: const Text('Say thanks'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade100,
            foregroundColor: Colors.red,
          ),
        ),
      );
    }
    
    // Otherwise, no bottom bar
    return const SizedBox.shrink();
  }
  
  void _showStatusChangeDialog(BuildContext context, WidgetRef ref) {
    final themeData = Theme.of(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Status'),
        content: const Text('What is the current status of this listing?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(listingProvider.notifier).updateListing(
                listing.copyWith(status: ListingStatus.fulfilled),
              );
              Navigator.pop(context);
            },
            child: Text(
              'Mark as Fulfilled',
              style: TextStyle(
                color: themeData.primaryColor,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(listingProvider.notifier).updateListing(
                listing.copyWith(status: ListingStatus.cancelled),
              );
              Navigator.pop(context);
            },
            child: const Text(
              'Mark as Cancelled',
              style: TextStyle(
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // TODO: Replace with actual user check
  bool _isCurrentUserOwner() {
    // Placeholder - replace with actual logic
    return false;
  }

  Widget _buildTypeIcon() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: listing.type == ListingType.ask ? Colors.blue : Colors.green,
        shape: BoxShape.circle,
      ),
      child: Icon(
        listing.type == ListingType.ask ? Icons.help_outline : Icons.local_offer_outlined,
        color: Colors.white,
        size: 18,
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    Color getStatusColor() {
      switch (listing.status) {
        case ListingStatus.active:
          return Colors.green;
        case ListingStatus.inactive:
          return Colors.grey;
        case ListingStatus.fulfilled:
          return Colors.blue;
        case ListingStatus.expired:
          return Colors.red;
        case ListingStatus.cancelled:
          return Colors.orange;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: getStatusColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: getStatusColor().withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Text(
        listing.status.name.toUpperCase(),
        style: TextStyle(
          color: getStatusColor(),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
  
  String _formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} ${(difference.inDays / 365).floor() == 1 ? 'year' : 'years'} ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} ${(difference.inDays / 30).floor() == 1 ? 'month' : 'months'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'just now';
    }
  }
} 