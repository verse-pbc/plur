# Profile Lookup Implementation

## Overview

This feature implements a reliable profile lookup mechanism to improve user profile data availability across the federated Nostr network. It addresses situations where users from different relay sets may not have their profiles readily available to other users.

## Problem

In a federated network like Nostr, users publish their profile data (kind 0 events) to their preferred relays. When other users connect to a different set of relays, they may not have access to these profile events, leading to missing display names, profile pictures, and other user metadata in the UI.

## Solution

We implemented a targeted profile lookup mechanism that:

1. Queries well-known, reliable relays (purplepag.es and relay.nos.social) for kind 0 events when a profile isn't found in the user's regular relay set
2. Caches profile data long-term in both memory and database
3. Provides both automatic and manual refresh mechanisms
4. Updates the UI automatically when profiles are found

## Implementation Details

### Key Components

1. **Reliable Relay Lookup** (`UserProvider.fetchUserProfileFromReliableRelays`):
   - Makes targeted requests to reliable relays for specific user metadata
   - Uses non-blocking async operations to avoid UI freezes
   - Returns a boolean indicating whether the profile was found

2. **Force Profile Refresh** (`UserProvider.forceProfileRefresh`):
   - Manually triggers a refresh from reliable relays
   - Shows appropriate UI feedback with loading indicators
   - Can be triggered by user action

3. **Enhanced User Retrieval** (`UserProvider.getUser`):
   - Automatically initiates background lookups for missing profiles
   - Maintains backward compatibility with existing code

4. **UI Components**:
   - Added refresh button to user profile view
   - Modified `UserPicWidget` to automatically request missing profiles
   - Enhanced `AppBar4Stack` to support multiple action buttons

### Implementation Flow

1. When a user profile is not found in the local cache (`getUser` returns null):
   - The app adds the public key to the standard update queue
   - Additionally, it initiates a background lookup from reliable relays
   - Once found, the profile data is stored in both memory and database

2. Users can manually refresh a profile by:
   - Clicking the refresh button in the user profile screen
   - This shows loading indicators and appropriate success/failure messages

3. The `UserPicWidget` automatically attempts to fetch missing profiles:
   - When rendering a profile picture with no available metadata
   - This happens in the background without blocking the UI

### Files Modified

- `lib/provider/user_provider.dart`: Added reliable relay lookup and profile refresh methods
- `lib/component/user/user_pic_widget.dart`: Enhanced to try fetching missing profiles
- `lib/router/user/user_widget.dart`: Added refresh button and manual update functionality
- `lib/component/appbar4stack.dart`: Modified to support multiple action buttons

## Benefits

1. **Improved User Experience**: Users see more complete profile data, even for users on different relay sets
2. **Non-blocking Operation**: Profile lookups happen in the background without affecting UI responsiveness
3. **Efficient Caching**: Profiles are stored long-term to minimize network requests
4. **User Control**: Manual refresh option for when automated lookups fail

## Limitations

1. Relies on the availability of specific relays (purplepag.es and relay.nos.social)
2. Cannot find profiles if they aren't published to the reliable relays
3. May introduce slight delays when profile data is being fetched

## Future Improvements

1. Allow configuring the list of reliable relays in settings
2. Add offline support with cached profile data
3. Implement profile data expiration and auto-refresh for outdated profiles
4. Add comprehensive test coverage for the profile lookup functionality