# Group Data Caching System

## Overview

This document outlines the implementation plan for a persistent data cache system to track group activity, including read/unread status, post counts, and last viewed timestamps. The goal is to provide offline access to group metadata and improve user experience by clearly indicating which groups have new content.

## Current Architecture

The app currently manages group data through:

- **GroupProvider**: Handles group metadata, members, and admins
- **GroupFeedProvider**: Manages posts from groups with in-memory caching
- **GroupMetadataRepository**: Fetches and sets group metadata
- **DB class**: SQLite implementation for persistent storage

While there's a mechanism for tracking read status in direct messages via the `dm_session_info` table, no equivalent exists for group posts. Most group data exists only in memory and isn't persisted between app sessions.

## Proposed Implementation

We'll create a comprehensive caching system that:

1. Persistently stores group metadata between app sessions
2. Tracks which posts have been read or are new
3. Maintains accurate post counts per group
4. Records when a user last viewed each group
5. Provides offline access to this information

### Database Schema Extension

Create a new `group_read_info` table to track group activity:

```sql
CREATE TABLE group_read_info (
  key_index INTEGER,
  group_id TEXT NOT NULL,
  host TEXT NOT NULL, 
  last_read_time INTEGER NOT NULL,
  post_count INTEGER DEFAULT 0,
  unread_count INTEGER DEFAULT 0,
  last_viewed_at INTEGER NOT NULL,
  PRIMARY KEY (key_index, group_id, host)
);
```

### New Data Models and Providers

1. **GroupReadInfo**: Data model for storing group read status
2. **GroupReadStatusProvider**: Manages the read/unread status for groups
3. **GroupReadInfoDB**: Database access layer for group read info

## Implementation Checklist

### Database Layer

- [ ] Update DB version number in `DB` class
- [ ] Add `group_read_info` table creation to `_onCreate` method
- [ ] Implement migration in `_onUpgrade` method for existing installations
- [ ] Create database indexes for optimized query performance
- [ ] Implement database purge mechanism for old/stale data

### Data Models

- [ ] Create `GroupReadInfo` model class with:
  - [ ] Serialization methods (toJson/fromJson)
  - [ ] Factory constructors
  - [ ] Utility methods for status calculations

- [ ] Implement `GroupReadInfoDB` with:
  - [ ] CRUD operations (create, read, update, delete)
  - [ ] Batch operations for efficiency
  - [ ] Query methods for different access patterns

### Provider Implementation

- [ ] Create `GroupReadStatusProvider` class that:
  - [ ] Loads group read status from database on startup
  - [ ] Tracks read/unread messages by timestamp comparison
  - [ ] Updates post counts when new posts arrive
  - [ ] Provides methods to mark groups as viewed/read
  - [ ] Persists all changes to database

- [ ] Modify `GroupFeedProvider` to:
  - [ ] Accept `GroupReadStatusProvider` in constructor
  - [ ] Track which posts are new since last read time
  - [ ] Update read status counts when posts are loaded or created
  - [ ] Implement methods to manage read status of posts

- [ ] Update dependency injection system:
  - [ ] Register new providers in app setup
  - [ ] Update factory methods for existing providers

### UI Integration

- [ ] Modify `CommunityListItemWidget` to:
  - [ ] Display accurate unread counts from cache
  - [ ] Use different styling for unread vs. read groups
  - [ ] Refresh when group status changes

- [ ] Update `GroupDetailWidget` to:
  - [ ] Mark group as viewed when opened
  - [ ] Add "Mark all as read" functionality
  - [ ] Visually indicate which posts are new

- [ ] Implement unread indicators in:
  - [ ] Bottom navigation bar badges
  - [ ] Group list screens
  - [ ] Any group selection dialogs

### Testing

- [ ] Create unit tests for:
  - [ ] GroupReadInfo model
  - [ ] GroupReadInfoDB operations
  - [ ] GroupReadStatusProvider functionality

- [ ] Implement integration tests for:
  - [ ] Database migration
  - [ ] Provider interactions
  - [ ] UI updates based on status changes

- [ ] Test edge cases:
  - [ ] App restart behavior
  - [ ] Offline usage
  - [ ] Large numbers of groups/posts
  - [ ] Clock changes and timestamp edge cases

### Documentation and cleanup

- [ ] Update code documentation for new classes
- [ ] Add usage examples in comments
- [ ] Review and refactor for consistency with app patterns
- [ ] Update any relevant project documentation

## Potential Challenges

1. **Performance with large datasets**: Need to ensure queries remain fast with many groups/posts
2. **Memory usage**: Balance between in-memory caching and database access
3. **Synchronization**: Keeping local cache in sync with remote data from relays
4. **Migration**: Smooth upgrade path for existing users

## Implementation Timeline

- **Phase 1**: Database schema and models (estimated: 1-2 days)
- **Phase 2**: Provider implementation and integration (estimated: 2-3 days)
- **Phase 3**: UI updates and testing (estimated: 2-3 days)

## Future Enhancements

- **Advanced filtering**: Filter groups by unread status
- **Notification priorities**: Prioritize notifications based on group activity
- **Data synchronization**: Sync read status across multiple devices
- **Analytics**: Track group engagement metrics