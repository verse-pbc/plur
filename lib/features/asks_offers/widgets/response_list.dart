import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nostrmo/theme/app_colors.dart';
import '../models/listing_model.dart';
import '../models/response_model.dart';
import '../providers/response_provider.dart';

class ResponseList extends ConsumerWidget {
  final ListingModel listing;
  final bool isCurrentUserOwner;
  final Function(ResponseModel) onAccept;
  final Function(ResponseModel) onDecline;

  const ResponseList({
    required this.listing,
    required this.isCurrentUserOwner,
    required this.onAccept,
    required this.onDecline,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final responsesAsync = ref.watch(responseProvider);
    final themeData = Theme.of(context);

    return responsesAsync.when(
      data: (responses) {
        if (responses.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32.0),
              child: Text('No responses yet'),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: responses.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            final response = responses[index];
            return _buildResponseItem(
              context,
              response,
              themeData,
            );
          },
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 32.0),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stackTrace) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Failed to load responses'),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  ref.read(responseProvider.notifier).loadResponses(
                    listingEventId: listing.id,
                  );
                },
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResponseItem(
    BuildContext context,
    ResponseModel response,
    ThemeData themeData,
  ) {
    // Determine color based on response type
    Color getTypeColor() {
      switch (response.responseType) {
        case ResponseType.help:
          return Colors.blue;
        case ResponseType.interest:
          return Colors.green;
        case ResponseType.question:
          return Colors.orange;
        case ResponseType.offer:
          return Colors.purple;
      }
    }

    // Get response type as readable text
    String getTypeText() {
      switch (response.responseType) {
        case ResponseType.help:
          return 'Offered help';
        case ResponseType.interest:
          return 'Expressed interest';
        case ResponseType.question:
          return 'Asked a question';
        case ResponseType.offer:
          return 'Made a counter-offer';
      }
    }
    
    // Get status badge color
    Color getStatusColor() {
      switch (response.status) {
        case ResponseStatus.pending:
          return Colors.grey;
        case ResponseStatus.accepted:
          return Colors.green;
        case ResponseStatus.declined:
          return Colors.red;
        case ResponseStatus.withdrawn:
          return Colors.orange;
      }
    }
    
    // Get status as readable text
    String getStatusText() {
      switch (response.status) {
        case ResponseStatus.pending:
          return 'Pending';
        case ResponseStatus.accepted:
          return 'Accepted';
        case ResponseStatus.declined:
          return 'Declined';
        case ResponseStatus.withdrawn:
          return 'Withdrawn';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with user info and response type
          Row(
            children: [
              // User avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: getTypeColor().withOpacity(0.2),
                child: Text(
                  response.pubkey.substring(0, 2).toUpperCase(),
                  style: TextStyle(
                    color: getTypeColor(),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // User info and response type
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TODO: Replace with actual username from metadata
                    const Text(
                      'Username',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          _getIconForResponseType(response.responseType),
                          color: getTypeColor(),
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          getTypeText(),
                          style: TextStyle(
                            color: context.colors.secondaryText,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatRelativeTime(response.createdAt),
                          style: TextStyle(
                            color: context.colors.secondaryText,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: getStatusColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: getStatusColor().withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  getStatusText(),
                  style: TextStyle(
                    color: getStatusColor(),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Response content
          Text(
            response.content,
            style: themeData.textTheme.bodyMedium,
          ),
          
          // Additional details if present
          if (response.price != null || 
              response.availability != null || 
              response.location != null) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (response.price != null)
                  _buildDetailChip(
                    Icons.attach_money,
                    response.price!,
                    Colors.green,
                  ),
                if (response.availability != null)
                  _buildDetailChip(
                    Icons.access_time,
                    response.availability!,
                    Colors.blue,
                  ),
                if (response.location != null)
                  _buildDetailChip(
                    Icons.location_on,
                    response.location!,
                    Colors.orange,
                  ),
              ],
            ),
          ],
          
          // Action buttons only for listing owner and pending responses
          if (isCurrentUserOwner && response.status == ResponseStatus.pending) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => onDecline(response),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                  child: const Text('Decline'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => onAccept(response),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Accept'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForResponseType(ResponseType type) {
    switch (type) {
      case ResponseType.help:
        return Icons.volunteer_activism;
      case ResponseType.interest:
        return Icons.thumb_up_outlined;
      case ResponseType.question:
        return Icons.help_outline;
      case ResponseType.offer:
        return Icons.local_offer_outlined;
    }
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