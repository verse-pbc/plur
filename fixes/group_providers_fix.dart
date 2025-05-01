import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'group_feed_provider.dart';
import 'group_read_status_provider.dart';
import 'list_provider.dart';

/// Setup function for group-related providers
///
/// This creates a provider tree with GroupReadStatusProvider and GroupFeedProvider
/// This allows proper dependency injection for these providers
class GroupProviders extends StatelessWidget {
  final Widget child;
  
  const GroupProviders({
    super.key,
    required this.child,
  });
  
  @override
  Widget build(BuildContext context) {
    // Get the list provider from the context
    final listProvider = Provider.of<ListProvider>(context, listen: false);
    
    // Create providers in the correct order of dependencies
    return ChangeNotifierProvider(
      create: (context) => GroupReadStatusProvider(),
      child: Consumer<GroupReadStatusProvider>(
        builder: (context, readStatusProvider, _) {
          // Create the GroupFeedProvider with its dependencies
          return ChangeNotifierProvider(
            create: (context) {
              // Create the provider with both dependencies
              final feedProvider = GroupFeedProvider(listProvider, readStatusProvider);
              
              // Schedule post-frame initialization to ensure counts are updated
              // This avoids doing heavy work during build
              WidgetsBinding.instance.addPostFrameCallback((_) {
                // Initialize the read status provider first
                readStatusProvider.init().then((_) {
                  // Check if we have posts in cache and update counts
                  if (!feedProvider.notesBox.isEmpty()) {
                    feedProvider.updateAllGroupReadCounts();
                  }
                });
              });
              
              return feedProvider;
            },
            child: child,
          );
        },
      ),
    );
  }
}

/// Extension method to add group providers to a widget
extension GroupProvidersExtension on Widget {
  /// Wraps this widget with the necessary group providers
  Widget withGroupProviders() {
    return GroupProviders(child: this);
  }
}