# Admin-Only Posts Feature and UI Improvements

## Summary
This PR adds a new admin-only posts feature for communities, completely redesigns the group invitation dialog, and fixes critical issues with community creation. It also addresses iOS build issues.

## Implements CHANGELOG Items

### From Release Notes Section
- ✅ **"Added admin-only posts feature for community admins"**
- ✅ **"Redesigned group invitation dialog with better UX and clear next steps"**
- ✅ **"Fixed issue with community creation button allowing multiple submissions"**

## Features and Fixes

1. **Admin-Only Posts Feature**:
   - Added a toggle in group settings for "Admin-only posts" option
   - Implemented permission checks to restrict posting to admins when enabled
   - Only allows admins to create new posts, while all members can still chat
   - Added localization for all new UI text

2. **Invite Dialog Redesign**:
   - Completely redesigned the invitation dialog after group creation
   - Added clear next steps for community setup including guidelines creation
   - Improved UI with better spacing, readability, and clear calls to action
   - Fixed rendering issues that previously caused layout exceptions

3. **Community Creation Improvements**:
   - Fixed issue where creating a community button could be clicked multiple times
   - Added input blocking during community creation to prevent duplicate submissions
   - Improved error handling to provide better feedback on failures

4. **iOS Fixes**:
   - Fixed iOS build issues with the Podfile
   - Disabled Sentry on iOS/macOS by adding appropriate preprocessor definitions
   - Added DisableSentry flag in Info.plist

## Technical Implementation
- Added `adminOnlyPosts` property to GroupMetadata class
- Updated NIP29 protocol implementation to support admin-only posts tags
- Modified permission checks in editor_widget.dart to enforce admin-only restrictions
- Redesigned invite_people_widget.dart to improve layout and prevent rendering issues
- Used AbsorbPointer to block UI interactions during async operations
- Added improved error handling and state management

## Testing
- Verified that only admins can create posts when admin-only posts is enabled
- Confirmed that all members can still chat in admin-only posts groups
- Tested the new invite dialog to ensure proper rendering on different devices
- Verified that the community creation button cannot be clicked multiple times
- Confirmed that the app builds and runs correctly on iOS devices