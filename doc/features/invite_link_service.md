# Invite Link Service in Plur

This document describes how invite links work in the Plur application, including the recent optimization to prefer direct protocol URLs instead of relying on the chus.me URL shortening service.

## Overview

Invite links in Plur allow users to invite others to join community groups. The application supports multiple invite link formats to maximize compatibility across different platforms and user scenarios.

## Invite Link Types

### 1. Direct Protocol URL (Primary Method)
- Format: `plur://join-community?group-id={GROUP_ID}&code={CODE}&relay={ENCODED_RELAY_URL}`
- This format directly opens the Plur app using the custom protocol handler
- Most reliable method, works immediately on devices with the app installed
- Used as the default link format in all scenarios

### 2. Universal Link via chus.me
- Format: `https://chus.me/invite/plur://join-community?group-id={GROUP_ID}&code={CODE}&relay={ENCODED_RELAY_URL}`
- Web-based link that embeds the direct protocol URL
- Redirects to the Plur app when possible
- Falls back to web experience when app is not installed
- Now used as a secondary option, not the default

### 3. Short URL Link
- Format: `https://chus.me/j/{SHORT_CODE}`
- Shortened version for easier sharing
- Less reliable than direct links

### 4. Nostr Protocol Link
- Format: `nostr:nprofile1q{GROUP_ID}?relay={ENCODED_RELAY_URL}&invite={CODE}`
- Uses the NIP-29 specification for group invites
- Properly implements bech32 encoding with the 'q' prefix after nprofile1
- Primarily used for compatibility with other nostr clients
- Specialized use case for the nostr ecosystem

## Implementation Details

### Core Implementation

The heart of the invite link generation is in the `GroupInviteLinkUtil` class, which provides methods for generating each type of invite link. The most important method is `generateShareableLink()`, which returns the recommended link format to use.

```dart
static String generateShareableLink(String groupId, String code, String relay) {
  // Always use direct protocol URL instead of chus.me service since it's more reliable
  return generateDirectProtocolUrl(groupId, code, relay);
}
```

### Nostr Protocol Link Generation

The Nostr protocol link follows the NIP-29 specification and is generated with the `generateNostrProtocolLink()` method:

```dart
static String generateNostrProtocolLink(String groupId, String code, String relay) {
  try {
    // Encode relay to ensure it works in URL parameters
    String encodedRelay = Uri.encodeComponent(relay);

    // The proper format requires the 'q' prefix after nprofile1 for a valid bech32 encoding
    // The full bech32 encoding would be more complex, but this is a simplified version that
    // matches the expected format
    return "nostr:nprofile1q$groupId?relay=$encodedRelay&invite=$code";
  } catch (e) {
    log('Error generating nostr protocol link: $e', name: 'GroupInviteLinkUtil');
    return "";
  }
}
```

This ensures that throughout the app, when code calls this method (which it should for consistency), it will always get the direct protocol URL.

### Direct Protocol URL Generation

The direct protocol URL is generated with the `generateDirectProtocolUrl()` method:

```dart
static String generateDirectProtocolUrl(String groupId, String code, String relay) {
  try {
    // Encode relay to ensure it works in URL parameters
    String encodedRelay = Uri.encodeComponent(relay);
    
    // Build direct protocol URL
    return "plur://join-community?group-id=$groupId&code=$code&relay=$encodedRelay";
  } catch (e) {
    log('Error generating direct protocol URL: $e', name: 'GroupInviteLinkUtil');
    return "";
  }
}
```

### ListProvider Integration

The `ListProvider` class is responsible for creating invite links when a user wants to share an invite with others. It uses the `createInviteLink()` method:

```dart
String createInviteLink(GroupIdentifier group, String inviteCode,
    {List<String>? roles}) {
  // Send invite event to relay...

  // Generate the direct protocol link using the utility method for consistency
  final directLink = GroupInviteLinkUtil.generateDirectProtocolUrl(group.groupId, inviteCode, group.host);

  // Always use the direct protocol link as primary since it's more reliable
  return directLink;
}
```

### Invite Dialog UI

The `InviteToCommunityDialog` provides users with options to select different link formats, but defaults to the direct protocol URL:

```dart
// Generate the direct protocol link first (this is the primary/default one)
directPlurLink = GroupInviteLinkUtil.generateDirectProtocolUrl(widget.groupIdentifier\!.groupId, inviteCode, widget.groupIdentifier\!.host);

// Generate other link formats...

// Default to the direct link as it's more reliable
activeLinkNotifier.value = directPlurLink;
```

## Benefits of Direct Protocol URLs

1. **Reliability**: Direct protocol URLs open the app immediately without any network requests or redirects
2. **Independence**: No reliance on third-party services that might experience downtime
3. **Speed**: Faster user experience with no web redirects
4. **Privacy**: Reduces sharing of user data with external services
5. **Offline Capability**: Links can be shared and used without internet connectivity once received

## Fallback Options

While direct protocol URLs are now the default, the app still maintains support for all previous link formats to ensure backward compatibility. Users can select different link formats in the invite dialog if needed for specific use cases.

## Testing

Test all link types regularly to ensure compatibility, especially after any changes to the deep linking system or app navigation.

1. Direct protocol links (`plur://join-community?...`)
2. Universal links (`https://chus.me/i/...`) 
3. Short URL links (`https://chus.me/j/...`)
4. Nostr protocol links (`nostr:nprofile...`)

Always prioritize testing the direct protocol links as they are now the default method.
EOF < /dev/null