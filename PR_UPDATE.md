# BotToast, Layout, and Test Group Joining Fixes

## Summary
This PR addresses several critical issues from the CHANGELOG causing blank screens, layout errors, and improves the user experience. It implements error handling improvements, fixes layout constraints, makes the Test Users Group joining optional, and addresses iOS/macOS compatibility issues.

## Implements CHANGELOG Items

### From Release Notes Section
- ✅ **"Made test group joining optional with confirmation dialog"**
- ✅ **"Fixed blank screen issues when creating and joining communities"**
- ✅ **"Improved invitation and group creation workflow with better error handling"**

### From Internal Changes Section  
- ✅ **"Fixed AVIF image loading issues that caused crashes"**
- ✅ **"Improved BotToast error handling to prevent blank screens"**
- ✅ **"Fixed issues with unbounded constraints in layout of community screens"**
- ✅ **"Enhanced error logging and recovery to improve app stability"**

## Technical Changes

### BotToast Error Handling
- Fixed `LateInitializationError: Local 'cancelFunc' has not been initialized` errors
- Added proper toast function tracking and cleanup to prevent memory leaks
- Improved error recovery when toasts fail to display
- Added periodic toast cleanup in SystemTimer

### Layout and Rendering Fixes
- Fixed "Cannot hit test a render box with no size" errors in InvitePeopleWidget
- Fixed MouseTracker assertion errors with safer async state management
- Resolved unbounded height constraints with proper layout constraints
- Used LayoutBuilder, SingleChildScrollView, and ConstrainedBox for proper sizing
- Added _isDisposed flag for safer widget lifecycle management

### UI Improvements
- Enhanced "Join Plur Test Users Group" dialog with Plur design system colors
- Improved button layout and responsiveness in dialogs
- Used proper localization instead of hardcoded text

### User Experience Enhancements
- Made Test Users Group joining optional instead of automatic
- Improved error recovery throughout the app
- Enhanced state management to prevent updates during critical phases

### Sentry and BlurHash Changes
- Added helper files for better Sentry error reporting compatibility on iOS/macOS
- Fixed BlurHash issues on iOS by providing empty implementations when needed
- Improved error logging and recovery to improve app stability

## Testing
- Verified that the app no longer shows blank screens when errors occur
- Confirmed that new users aren't automatically joined to test groups
- Tested that the UI properly renders on different screen sizes without layout errors
- Confirmed proper localization is working for all text elements

## Screenshots
*Before: Join Test Users dialog with incorrect color scheme*
[See attached screenshots in PR]

*After: Join Test Users dialog with Plur color scheme*
[See attached screenshots in PR]