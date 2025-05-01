# Testing Web and Short URL Invites

## Prerequisites
- [ ] Deploy latest version to production environment
- [ ] Ensure test accounts are available on iOS and Android devices
- [ ] Prepare clean browser sessions (incognito/private mode)

## API Testing

### Web Invite API Verification
- [ ] Verify `/invite` endpoint returns proper response codes (200 for valid, 404 for invalid)
- [ ] Confirm invite payload contains expected community metadata
- [ ] Test authentication requirements for creating new invites
- [ ] Verify rate limiting is functioning properly
- [ ] Test invite expiration functionality

### Short URL API Verification
- [ ] Verify short URL redirection returns proper status codes
- [ ] Test URL parameter handling (correct handling of UTM parameters)
- [ ] Validate that invalid/expired short URLs return appropriate error responses
- [ ] Check that analytics are properly captured for short URL clicks

## Browser Testing

### Desktop Browsers
- [ ] Test invite link in Chrome
- [ ] Test invite link in Firefox
- [ ] Test invite link in Safari
- [ ] Test invite link in Edge

### Mobile Browsers
- [ ] Test invite link in mobile Chrome (iOS)
- [ ] Test invite link in mobile Safari (iOS)
- [ ] Test invite link in mobile Chrome (Android)
- [ ] Test invite link in mobile Firefox (Android)

### User Flows
- [ ] New user flow: Test invite acceptance for non-registered users
- [ ] Existing user flow: Test invite acceptance for users who already have accounts
- [ ] Logged-out flow: Test behavior when receiving invite while logged out
- [ ] Test handling of already-accepted invites

## Deep Link Testing

### iOS Deep Links
- [ ] Test Universal Links through Apple's validation tool
- [ ] Test opening invite links from Messages app
- [ ] Test opening invite links from Mail app
- [ ] Test opening invite links from Notes app
- [ ] Test opening invite links from third-party apps (Slack, WhatsApp)
- [ ] Verify app navigation to correct community after deep link

### Android Deep Links
- [ ] Validate App Links in Google Play Console
- [ ] Test opening invite links from Messages app
- [ ] Test opening invite links from Gmail app
- [ ] Test opening invite links from third-party apps (Slack, WhatsApp)
- [ ] Verify app navigation to correct community after deep link
- [ ] Test Instant App behavior (if applicable)

## Edge Cases

### Network Conditions
- [ ] Test invite links under poor network conditions
- [ ] Test behavior when offline then online

### Device States
- [ ] Test with app in background
- [ ] Test with app not installed (should prompt install)
- [ ] Test with app installed but not signed in

### Security Testing
- [ ] Verify invites can't be forged or tampered with
- [ ] Test cross-site scripting (XSS) protection
- [ ] Verify user permissions are correctly enforced

## Analytics and Monitoring

- [ ] Verify invite acceptance events are tracked properly
- [ ] Check dashboard for successful invite metrics
- [ ] Monitor error rates related to invite flows
- [ ] Validate conversion funnel (link click → install → signup → join community)