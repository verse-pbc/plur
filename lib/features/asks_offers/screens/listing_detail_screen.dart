import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nostr_sdk/nip29/group_identifier.dart';
import 'package:nostrmo/component/user/user_pic_widget.dart';
import 'package:nostrmo/component/user/simple_name_widget.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostrmo/data/group_identifier_repository.dart';
import 'package:nostrmo/data/group_metadata_repository.dart';
import 'package:nostrmo/provider/user_provider.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:nostrmo/util/theme_util.dart';
import '../models/listing_model.dart';
import '../models/response_model.dart';
import '../providers/listing_provider.dart';
import '../providers/response_provider.dart';
import '../widgets/response_dialog.dart';
import '../widgets/response_list.dart';
import 'create_edit_listing_screen.dart';

class ListingDetailScreen extends ConsumerStatefulWidget {
  final ListingModel listing;

  const ListingDetailScreen({
    required this.listing,
    super.key,
  });

  @override
  ConsumerState<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends ConsumerState<ListingDetailScreen> {
  bool _isLoadingResponses = false;

  @override
  void initState() {
    super.initState();
    _loadResponses();
  }

  Future<void> _loadResponses() async {
    setState(() {
      _isLoadingResponses = true;
    });
    
    try {
      await ref.read(responseProvider.notifier).loadResponses(
        listingEventId: widget.listing.id,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingResponses = false;
        });
      }
    }
  }

  void _handleAcceptResponse(ResponseModel response) {
    ref.read(responseProvider.notifier).updateResponse(
      response.copyWith(
        status: ResponseStatus.accepted,
      ),
    );
  }

  void _handleDeclineResponse(ResponseModel response) {
    ref.read(responseProvider.notifier).updateResponse(
      response.copyWith(
        status: ResponseStatus.declined,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final customColors = themeData.customColors;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.listing.type == ListingType.ask ? 'Ask Details' : 'Offer Details'),
        actions: [
          if (widget.listing.status == ListingStatus.active) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => CreateEditListingScreen(
                      listing: widget.listing,
                      groupId: widget.listing.groupId,
                    ),
                  ),
                );
              },
            ),
            PopupMenuButton<ListingStatus>(
              icon: const Icon(Icons.more_vert),
              onSelected: (ListingStatus status) {
                ref.read(listingProvider.notifier).updateListing(
                  widget.listing.copyWith(status: status),
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
                color: widget.listing.type == ListingType.ask 
                  ? Colors.blue.withOpacity(0.1) // TODO: Replace with withValues() once determined
                  : Colors.green.withOpacity(0.1), // TODO: Replace with withValues() once determined
                border: Border(
                  bottom: BorderSide(
                    color: customColors.separatorColor.withOpacity(0.3), // TODO: Replace with withValues() once determined
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
                        widget.listing.type == ListingType.ask ? 'ASK' : 'OFFER',
                        style: themeData.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: widget.listing.type == ListingType.ask ? Colors.blue : Colors.green,
                        ),
                      ),
                      Text(
                        widget.listing.title,
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
            if (widget.listing.imageUrls.isNotEmpty)
              SizedBox(
                height: 220,
                child: PageView.builder(
                  itemCount: widget.listing.imageUrls.length,
                  itemBuilder: (context, index) {
                    return Image.network(
                      widget.listing.imageUrls[index],
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
                      // User avatar
                      UserPicWidget(
                        pubkey: widget.listing.pubkey,
                        width: 40,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // User name
                          GestureDetector(
                            onTap: () {
                              RouterUtil.router(context, RouterPath.user, widget.listing.pubkey);
                            },
                            child: SimpleNameWidget(
                              pubkey: widget.listing.pubkey,
                              textStyle: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            'Posted ${_formatRelativeTime(widget.listing.createdAt)}',
                            style: themeData.textTheme.bodySmall?.copyWith(
                              color: customColors.secondaryForegroundColor,
                            ),
                          ),
                        ],
                      ),
                      if (widget.listing.groupId != null) ...[
                        const Spacer(),
                        // Group chip with group name
                        _buildGroupChip(context),
                      ],
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Description
                  Text(
                    widget.listing.content,
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
                          if (widget.listing.price != null)
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
                                widget.listing.price!,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ),
                            
                          if (widget.listing.location != null)
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
                              subtitle: Text(widget.listing.location!),
                            ),
                            
                          if (widget.listing.expiresAt != null)
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
                              subtitle: Text(_formatDate(widget.listing.expiresAt!)),
                            ),
                            
                          if (widget.listing.paymentInfo != null)
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
                              subtitle: Text(widget.listing.paymentInfo!),
                            ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Responses section header
                  Row(
                    children: [
                      Text(
                        'Responses',
                        style: themeData.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Consumer(
                        builder: (context, ref, child) {
                          final responses = ref.watch(responseProvider);
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: themeData.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              responses.maybeWhen(
                                data: (data) => data.length.toString(),
                                orElse: () => '0',
                              ),
                              style: TextStyle(
                                color: themeData.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Responses list
                  if (_isLoadingResponses)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else
                    ResponseList(
                      listing: widget.listing,
                      isCurrentUserOwner: _isCurrentUserOwner(),
                      onAccept: _handleAcceptResponse,
                      onDecline: _handleDeclineResponse,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomActions(context),
    );
  }
  
  Widget _buildBottomActions(BuildContext context) {
    if (widget.listing.status == ListingStatus.active) {
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                if (widget.listing.type == ListingType.ask)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _showResponseDialog(ResponseType.help);
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
                        _showResponseDialog(ResponseType.interest);
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
                // "Ask a question" button
                if (!_isCurrentUserOwner())
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _showResponseDialog(ResponseType.question);
                      },
                      icon: const Icon(Icons.help_outline),
                      label: const Text('Ask a question'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Owner actions
                if (_isCurrentUserOwner()) ...[
                  OutlinedButton.icon(
                    onPressed: () {
                      _showStatusChangeDialog(context);
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
                      final detail = dmProvider.findOrNewADetail(widget.listing.pubkey);
                      // Navigate to DM screen with the session detail
                      RouterUtil.router(context, RouterPath.dmDetail, detail);
                    },
                    icon: const Icon(Icons.message_outlined),
                    label: const Text('Direct Message'),
                  ),
                ],
              ],
            ),
          ],
        ),
      );
    } 
    // Fulfilled listings get a "say thanks" option
    else if (widget.listing.status == ListingStatus.fulfilled && !_isCurrentUserOwner()) {
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
  
  void _showStatusChangeDialog(BuildContext context) {
    final themeData = Theme.of(context);
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Update Status'),
        content: const Text('What is the current status of this listing?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(listingProvider.notifier).updateListing(
                widget.listing.copyWith(status: ListingStatus.fulfilled),
              );
              Navigator.pop(dialogContext);
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
                widget.listing.copyWith(status: ListingStatus.cancelled),
              );
              Navigator.pop(dialogContext);
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
  
  // Check if current user is the owner of the listing
  bool _isCurrentUserOwner() {
    if (nostr == null) return false;
    return nostr!.publicKey == widget.listing.pubkey;
  }

  // Show response dialog
  void _showResponseDialog(ResponseType initialType) {
    showDialog(
      context: context,
      builder: (dialogContext) => ResponseDialog(
        listing: widget.listing,
        initialResponseType: initialType,
      ),
    ).then((result) {
      if (result == true && mounted) {
        // Refresh responses after adding a new one
        _loadResponses();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Response sent successfully')),
        );
      }
    });
  }

  Widget _buildTypeIcon() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: widget.listing.type == ListingType.ask ? Colors.blue : Colors.green,
        shape: BoxShape.circle,
      ),
      child: Icon(
        widget.listing.type == ListingType.ask ? Icons.help_outline : Icons.local_offer_outlined,
        color: Colors.white,
        size: 18,
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    Color getStatusColor() {
      switch (widget.listing.status) {
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
        widget.listing.status.name.toUpperCase(),
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
  
  Widget _buildGroupChip(BuildContext context) {
    if (widget.listing.groupId == null) return const SizedBox.shrink();
    
    final themeData = Theme.of(context);
    final customColors = themeData.customColors;
    
    // Extract host from group identifier format (host:id)
    String? host;
    String groupIdFormatted = widget.listing.groupId!;
    
    if (widget.listing.groupId!.contains(':')) {
      final parts = widget.listing.groupId!.split(':');
      host = parts[0];
      groupIdFormatted = parts[1];
    }
    
    // Create GroupIdentifier if both host and id are available
    GroupIdentifier? groupIdentifier;
    if (host != null) {
      groupIdentifier = GroupIdentifier(host, groupIdFormatted);
    }
    
    // Default chip with just the ID
    Widget defaultChip = Chip(
      label: Text('Group: $groupIdFormatted'),
      backgroundColor: customColors.feedBgColor,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
    
    // If we can construct a group identifier, use it to fetch metadata
    if (groupIdentifier != null) {
      return Consumer(
        builder: (context, ref, child) {
          final groupMetadataAsync = ref.watch(groupMetadataProvider(groupIdentifier!));
          
          return groupMetadataAsync.when(
            data: (metadata) {
              if (metadata == null) return defaultChip;
              
              return GestureDetector(
                onTap: () {
                  // Navigate to group detail
                  RouterUtil.router(context, RouterPath.groupDetail, groupIdentifier);
                },
                child: Chip(
                  label: Text(metadata.displayName ?? metadata.name ?? 'Group: $groupIdFormatted'),
                  backgroundColor: customColors.feedBgColor,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              );
            },
            loading: () => defaultChip,
            error: (_, __) => defaultChip,
          );
        },
      );
    }
    
    return defaultChip;
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