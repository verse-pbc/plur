# Invite Improvements

This feature adds several improvements to the group invitation system in Plur.

## Changes

### Tabbed Interface for Members and Invites

The Group Info screen now organizes members and pending invites in separate tabs for better clarity:

- **Members Tab**: Shows all active members of the group
- **Invites Tab**: Shows all pending invites with their details

### Improved Invite Display

- Better visual distinction between members and pending invites
- Properly sized avatars that aren't cut off
- Clear labels for pending invites, displaying intended recipient when available
- Dotted borders around pending invite avatars

### Technical Implementation

- Added tab selection state to the `_GroupInfoWidgetState` class
- Created dedicated methods for building each tab's content
- Improved sorting logic to prioritize admins and active members
- Enhanced handling of invite metadata extraction from nostr events
- Fixed type casting issues for role lists

## Future Improvements

- Add ability to resend invites
- Add ability to cancel pending invites
- Improve invite expiration handling
- Localization of "Invites" string (currently hardcoded)