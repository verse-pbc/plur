import 'package:provider/provider.dart';
import 'package:nostrmo/provider/group_read_status_provider.dart';
import 'package:nostrmo/provider/group_feed_provider.dart';
import 'package:nostrmo/provider/list_provider.dart';

// Update the MultiProvider section in main.dart by adding these providers to the list:
// Add this right after the ListProvider in the providers list in the MultiProvider widget

// ADD THIS TO THE PROVIDERS ARRAY:
// After line 681 - right after the ListProvider entry

ListenableProvider<GroupReadStatusProvider>(
  create: (context) {
    final readStatusProvider = GroupReadStatusProvider();
    readStatusProvider.init();
    return readStatusProvider;
  },
),

// Add this right after the GroupReadStatusProvider provider:
ProxyProvider2<ListProvider, GroupReadStatusProvider, GroupFeedProvider>(
  update: (context, listProvider, readStatusProvider, previous) {
    if (previous == null) {
      return GroupFeedProvider(listProvider, readStatusProvider);
    }
    return previous;
  },
),