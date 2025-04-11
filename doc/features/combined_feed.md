# Combined Communities Feed

## Overview

The combined communities feed feature allows users to see posts from all their joined communities in a single feed view. This makes it easier for users to stay updated with content from across all their communities without having to navigate to each community individually.

## Key Components

### UI Components

1. **AllGroupPostsWidget** (`lib/router/group/all_group_posts_widget.dart`)
   - Provides a tabbed interface with two views:
     - Grid View: Shows communities in a grid layout for easy access
     - Feed View: Shows a combined feed of posts from all communities

2. **CommunitiesGridWidget** (`lib/router/group/communities_grid_widget.dart`)
   - Displays all joined communities in a grid layout
   - Used in the first tab of the AllGroupPostsWidget

3. **CommunitiesFeedWidget** (`lib/router/group/communities_feed_widget.dart`)
   - Container for the combined feed display
   - Manages the GroupFeedProvider

4. **GroupEventListWidget** (`lib/component/event/group_event_list_widget.dart`)
   - Displays the actual list of events from all communities
   - Handles pagination, loading states, and empty states

5. **CommunityTitleWidget** (`lib/router/group/community_title_widget.dart`)
   - Shows the title of the feed with a count of joined communities

### Data Management

1. **GroupFeedProvider** (`lib/provider/group_feed_provider.dart`)
   - Core provider that fetches and manages events from multiple communities
   - Handles querying the Nostr relay for events from all joined communities
   - Manages two event boxes:
     - `notesBox`: Main events displayed in the feed
     - `newNotesBox`: New events that arrive while the user is viewing the feed

## How It Works

1. When the user opens the Communities tab, they see the AllGroupPostsWidget with two tabs: Grid View and Feed View
2. The Grid View shows all communities the user has joined
3. The Feed View displays posts from all communities in a combined feed, sorted by recency
4. The GroupFeedProvider fetches events from all communities by:
   - Getting the list of joined communities from ListProvider
   - Creating filters to fetch GROUP_NOTE and GROUP_NOTE_REPLY events from all these communities
   - Subscribing to new events from these communities
5. New posts are initially added to a separate newNotesBox and a notification is shown
6. Users can tap the notification to merge these new posts into the main feed

## Handling Edge Cases

1. **Empty State**: When a user has no communities or no posts, appropriate empty state UI is displayed
2. **New Events**: New events that arrive while the user is viewing the feed are added to a separate box and a notification is shown
3. **Pagination**: Implemented via the LoadMoreEvent mixin to fetch older posts when the user scrolls to the bottom

## Testing

The feature includes unit tests in `test/group_feed_provider_test.dart` to verify:
1. Proper initialization of the provider
2. Correct identification of group events
3. Merging of new events from the newNotesBox to the main notesBox

## Future Improvements

Potential future enhancements could include:
1. Adding sorting options (by activity, newest, etc.)
2. Filtering options to show posts from specific communities
3. Improved notification for new posts with preview information