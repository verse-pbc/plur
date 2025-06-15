# NIP-29 Implementation Guide

## Overview

NIP-29 defines a protocol for Nostr Group Chats. This implementation provides a comprehensive set of tools for working with Nostr groups, including:

- Group management
- Member administration
- Content moderation
- Permissions and roles

## Key Components

### GroupIdentifier

The `GroupIdentifier` class uniquely identifies a group by combining a relay host and a group ID. This implementation extends the standard NIP-29 format to make it easier to work with in the application.

### Group Metadata

The `GroupMetadata` class handles the properties of a group:
- Name
- Picture
- About information
- Community guidelines
- Public/private status
- Open/closed status
- Relay list

### Group Members

The `GroupMembers` class manages a list of members in a group, allowing you to check membership and add or remove users.

### Group Admins

The `GroupAdmins` class manages admin permissions with role-based access control. Administrators can have different roles and permission sets within a group.

### Group Event Box

The `GroupEventBox` class provides a container for efficiently managing group-related events such as notes and chat messages.

## Group Operations

The `NIP29` class implements core operations for group management:

- `deleteEvent`: Delete an event from a group
- `editStatus`: Change group status (public/private, open/closed)
- `addMember`: Add a member to a group
- `removeMember`: Remove a member from a group
- `removePost`: Remove a post from a group (moderation)
- `removeUser`: Remove a user with a moderation event
- `banUser`: Ban a user from a group

## Application Integration

In the application code, `GroupProvider` serves as the main interface for group operations. It:

1. Caches group metadata, members, and admins
2. Provides methods to check permissions
3. Implements higher-level group management functions
4. Handles group invitations
5. Sends moderation notifications

## Event Kinds Used

This implementation uses several NIP-29 specific event kinds:

- `EventKind.groupMetadata` (39000): Group metadata
- `EventKind.groupAdmins` (39001): Group admin list
- `EventKind.groupMembers` (39002): Group member list
- `EventKind.groupAddUser` (9000): Add user to group
- `EventKind.groupRemoveUser` (9001): Remove user from group
- `EventKind.groupEditMetadata` (9002): Edit group metadata
- `EventKind.groupDeleteEvent` (9005): Delete an event from a group
- `EventKind.groupEditStatus` (9006): Edit group status
- `EventKind.groupCreateGroup` (9007): Create a new group
- `EventKind.groupDeleteGroup` (9008): Delete a group
- `EventKind.groupCreateInvite` (9009): Create an invite to a group
- `EventKind.groupJoin` (9021): Join a group
- `EventKind.groupLeave` (9022): Leave a group
- `EventKind.groupModeration` (16402): Group moderation event

## Moderation Features

This implementation includes enhanced moderation features:

1. Post removal: Admins can remove posts from a group
2. User removal: Admins can remove users from a group
3. User banning: Admins can temporarily or permanently ban users
4. Notification messages: Users can receive direct messages explaining moderation actions

## Implementation Considerations

1. Events are sent to the group's designated relay for consistent state management
2. Group administrators are cached locally for permission checks
3. Moderation events are designed not to be cached by cache relays
4. Group membership is validated server-side at the relay level