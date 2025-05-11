# Mocked and Simulated Systems in Plur

This document lists all the mocked, simulated, and stubbed implementations in the Plur codebase. These are temporary implementations that should be replaced with real implementations when the corresponding services or features are ready.

## Invite Link System

### Short URL Generation

The short URL generation system in `GroupInviteLinkUtil` is currently mocked and doesn't make real API calls to the chus.me service.

**File:** `/Users/rabble/code/verse/plur/lib/util/group_invite_link_util.dart`

**Description:**
- The `createShortInviteUrl` method is a temporary implementation that doesn't require API access
- It generates a short code locally and constructs a short URL
- Contains placeholder for the real API implementation (commented out)
- Simulates network delay for realism
- Contains a note: "Original implementation (uncomment when API is ready)"

**Related UI components:**
- In `invite_to_community_dialog.dart`, there are debug labels indicating "CURRENTLY MOCKED - NOT A REAL API CALL"
- In `invite_people_widget.dart`, there are also indications that the short link generation is mocked

### chus.me API Key

**File:** `/Users/rabble/code/verse/plur/lib/util/group_invite_link_util.dart`

**Description:**
- There's a placeholder API key for the chus.me service: `_inviteApiKey = 'YOUR_INVITE_TOKEN'`
- A comment indicates: "For production, replace with your actual API key provided by the chus.me service"
- The `getApiKeyPlaceholderStatus` method checks if the API key is a placeholder

## Web Platform Compatibility

### Web Cookie Handling

**File:** `/Users/rabble/code/verse/plur/lib/util/web_cookie_stub.dart`

**Description:**
- Stub implementation for web cookie handling
- Used as a platform-specific implementation for web builds

### Web Path Provider

**File:** `/Users/rabble/code/verse/plur/lib/util/web_stub_path_provider.dart`

**Description:**
- Stub implementation for path provider functionality on web
- Used to maintain cross-platform compatibility

## PC/Desktop UI Simulation

### Fake PC Router

**File:** `/Users/rabble/code/verse/plur/lib/component/pc_router_fake.dart`

**Description:**
- Contains fake PC/desktop UI routing implementation
- Used to simulate desktop-specific navigation patterns on mobile devices

### PC Router Provider

**File:** `/Users/rabble/code/verse/plur/lib/provider/pc_router_fake_provider.dart`

**Description:**
- Provider for the fake PC router
- Manages state for the simulated desktop UI components

## Image Processing

### BlurHash Component Stubs

**Files in `/Users/rabble/code/verse/plur/lib/component/blurhash_image_component/`:**
- `stub_platform.dart`
- `empty_blurhash.dart`
- `empty_blurhash_ffi.dart`
- `empty_blurhash_dart.dart`
- `empty_image.dart`

**Description:**
- Contains stub implementations for different platforms
- Provides platform-specific implementations for the BlurHash image component
- Used to ensure cross-platform compatibility

## Push Notification Testing

**File:** `/Users/rabble/code/verse/plur/lib/util/push_notification_tester.dart`

**Description:**
- Simulates push notification functionality for testing
- Used during development to test notification handling without sending real notifications

## Test Mocks

Multiple mock implementations exist in the test directory for testing purposes:

- Mock database implementation in `test/helpers/mock_database.dart`
- Mock test data in `test/helpers/test_data.dart`
- Various mocked providers and repositories in test directories

## Recommended Action Items

1. Replace the mocked short URL generation with real API calls to the chus.me service
2. Add a proper API key for the chus.me service in production builds
3. Evaluate which web stubs need to be implemented with real functionality
4. Consider adding a development flag to disable mocks in production builds
5. Document API integration requirements for the chus.me service
6. Add tests for the real API implementations once they're in place

## Notes for Contributors

When working with these mocked systems:

1. Look for "MOCKED", "Temporary implementation", or similar comments that indicate placeholder functionality
2. Check if there are TODOs or commented-out code that contains the intended real implementation
3. Be aware that simulated network delays and random code generation might affect testing
4. Always test both the mocked and real implementations when replacing mocks with real code