# Testing Invite Links in Plur

This document explains how to test the different types of invite links in the Plur application.

## Accessing the Invite Dialog

There are multiple ways to access the invite dialog in Plur:

1. **From the Group Detail Screen**:
   - Navigate to any group you're a member of
   - Look for an "Invite" button in the actions section
   - Tap this button to open the invite dialog

2. **From the Group Info Screen**:
   - Open any group you're a member of
   - Tap the kebab menu (three dots) in the upper right corner
   - Select "Group Info" from the menu
   - In the Group Info screen, tap the "Invite" button in the actions section

3. **Debug Mode** (for development):
   - If you're a developer, you can access the invite debug dialog
   - To access it, navigate to the Group Detail screen for any group
   - Tap the kebab menu (three dots) in the upper right corner
   - If you're in debug mode, you should see a "Debug Invite Links" option

## Testing Different Link Types

The invite dialog now offers four different link types that you can test:

1. **Direct Protocol (plur://)**: 
   - This is the default and most reliable option
   - Works best when the Plur app is already installed
   - Format: `plur://join-community?group-id=GROUP_ID&code=CODE&relay=RELAY`

2. **Universal (chus.me/i)**: 
   - Web-based link that opens the app when installed or offers download options
   - Format: `https://chus.me/i/CODE`

3. **Short (chus.me/j)**: 
   - Shortened version of the invite link for easier sharing
   - Format: `https://chus.me/j/SHORT_CODE`

4. **Nostr Protocol**:
   - Format compatible with other Nostr clients implementing NIP-29
   - Format: `nostr:nprofile1qGROUP_ID?relay=RELAY&invite=CODE`
   - Note the 'q' after nprofile1 which is required for proper bech32 encoding

## Testing Flow

To properly test the invite links:

1. Generate an invite link using the invite dialog
2. Select the link type you want to test
3. Copy the link to share it (using the copy button)
4. Test the link on different devices:
   - Fresh install (no Plur app): Should direct to app store or offer web fallback
   - Existing install: Should open directly to the join screen
   - Different platforms: Test on iOS, Android, and web if possible

## Reporting Issues

If you encounter any issues with invite links, please report them with:

1. The exact link type you were testing
2. The device and OS version you were using
3. Whether Plur was installed or not
4. The specific behavior you observed versus what you expected
5. Screenshots if possible

Direct protocol links should now be working reliably in all scenarios, as they're the primary format used by the app.
EOF < /dev/null