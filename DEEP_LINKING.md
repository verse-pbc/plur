# Plur App Deep Linking Implementation Guide

This document provides comprehensive instructions on the deep linking implementation in the Plur app, covering both Universal Links and custom URL schemes for iOS.

## Overview

Plur supports multiple deep linking mechanisms to facilitate seamless sharing and access to communities:

1. **Universal Links** - Web URLs that open directly in the app
2. **Custom URL Schemes** - Direct app-to-app communication protocols
3. **API-based Short Codes** - Compact, shareable codes that resolve to full invitation details

## URL Formats

### Universal Links
- **`rabble.community` Domain:**
  - `https://rabble.community/i/{CODE}` - Standard invite that resolves through API
  - `https://rabble.community/j/{SHORT_CODE}` - Short URL invite that redirects to a full invite
  - `https://rabble.community/join/{CODE}` - Web invite with rich metadata display
  - `https://rabble.community/i/plur://join-community?group-id=X&code=Y&relay=Z` - Universal link with embedded protocol
  - `https://rabble.community/join/{GROUP_ID}?code=Y&relay=Z` - Path-based group join
  - `https://rabble.community/join-community?group-id=X&code=Y&relay=Z` - Query parameter join
  - `https://rabble.community/g/{GROUP_ID}?relay=Z` - Direct group navigation

- **`chus.me` Domain:**
  - `https://chus.me/i/{CODE}` - Standard invite that resolves through API
  - `https://chus.me/j/{SHORT_CODE}` - Short URL invite that redirects to a full invite
  - `https://chus.me/join/{CODE}` - Web invite with rich metadata display

### Custom URL Schemes
- `plur://join-community?group-id=X&code=Y&relay=Z` - Direct join with parameters
- `plur://group/{GROUP_ID}?relay=Z` - Direct group navigation
- `rabble://invite/{CODE}` - Short code format

## Implementation Details

### iOS Side

#### 1. Required Files

- **Entitlements Files**
  - `Runner.entitlements` and `RunnerDebug.entitlements`: Configure Associated Domains
  
- **Info.plist**
  - Add URL Types for custom schemes

- **Apple App Site Association (AASA) File**
  - Host at `/.well-known/apple-app-site-association` on your domains
  
- **AppDelegate.swift**
  - Universal Links handler (NSUserActivity processing)
  - Custom URL scheme handler
  - API integration for short codes

#### 2. Code Structure

The iOS implementation uses a unified link handling approach:
1. Central `handleDeepLink` method analyzes incoming URLs
2. Specialized handlers for each URL format type
3. API integration for short codes
4. Normalized parameter passing to Flutter

### Flutter Side

The Flutter implementation is structured as follows:

1. **LinkRouterUtil**
   - Central router for all deep link formats
   - Specialized handlers for different URL types
   - Group joining logic

2. **GroupInviteLinkUtil**
   - Link generation in various formats
   - Random code generation for invites
   - API integration placeholders

## Invitation Flow

### Creating Invites

1. Generate a random code or use a direct parameter-based approach
2. Create a shareable link using `GroupInviteLinkUtil.generateShareableLink()`
3. Share this link via standard sharing mechanisms

### Processing Invites

1. User clicks a link in a browser, email, message, etc.
2. iOS/Android system recognizes the link format
3. The appropriate handler processes the URL
4. For API-based short codes, the server endpoint resolves the code to full parameters
5. Parameters are passed to Flutter for group joining
6. User sees the group join UI

## Configuration

### 1. Apple App Site Association Files

#### For rabble.community

Host this at `https://rabble.community/.well-known/apple-app-site-association`:

```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "GZCZBKH7MY.app.verse.prototype.plur",
        "paths": [
          "/i/*", 
          "/join/*", 
          "/join-community*",
          "/g/*"
        ],
        "appIDs": ["GZCZBKH7MY.app.verse.prototype.plur"],
        "components": [
          {
            "/": "/i/*",
            "comment": "Matches any URL with a path that starts with /i/"
          },
          {
            "/": "/join/*",
            "comment": "Matches any URL with a path that starts with /join/"
          },
          {
            "/": "/join-community*",
            "comment": "Matches any URL with a path that starts with /join-community"
          },
          {
            "/": "/g/*",
            "comment": "Matches any URL with a path that starts with /g/"
          }
        ]
      }
    ]
  },
  "webcredentials": {
    "apps": ["GZCZBKH7MY.app.verse.prototype.plur"]
  }
}
```

#### For chus.me

Host this at `https://chus.me/.well-known/apple-app-site-association`:

```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "GZCZBKH7MY.app.verse.prototype.plur",
        "paths": [
          "/i/*", 
          "/join/*", 
          "/j/*",
          "/join-community*",
          "/g/*"
        ],
        "components": [
          {
            "/": "/i/*",
            "comment": "Matches any URL with a path that starts with /i/"
          },
          {
            "/": "/join/*",
            "comment": "Matches any URL with a path that starts with /join/"
          },
          {
            "/": "/j/*",
            "comment": "Matches any URL with a path that starts with /j/ (short URL)"
          },
          {
            "/": "/join-community*",
            "comment": "Matches any URL with a path that starts with /join-community"
          },
          {
            "/": "/g/*",
            "comment": "Matches any URL with a path that starts with /g/"
          }
        ]
      }
    ]
  },
  "webcredentials": {
    "apps": ["GZCZBKH7MY.app.verse.prototype.plur"]
  }
}
```

### 2. Android App Links Configuration

#### assetlinks.json for rabble.community

Host this at `https://rabble.community/.well-known/assetlinks.json`:

```json
[{
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "app.verse.prototype.plur",
    "sha256_cert_fingerprints":
    ["6F:36:C3:68:74:18:5E:03:B4:79:3D:82:EF:54:CE:34:26:ED:6E:C8:12:B7:CD:E2:F4:FA:9C:81:2F:C7:14:F4"]
  }
}]
```

#### assetlinks.json for chus.me

Host this at `https://chus.me/.well-known/assetlinks.json`:

```json
[{
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "app.verse.prototype.plur",
    "sha256_cert_fingerprints":
    ["6F:36:C3:68:74:18:5E:03:B4:79:3D:82:EF:54:CE:34:26:ED:6E:C8:12:B7:CD:E2:F4:FA:9C:81:2F:C7:14:F4"]
  }
}]
```

### 3. Android Manifest Intent Filters

Add these to the main activity in `AndroidManifest.xml`:

```xml
<!-- Intent filters for rabble.community -->
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="https" android:host="rabble.community" android:pathPattern="/i/.*" />
</intent-filter>
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="https" android:host="rabble.community" android:pathPattern="/join/.*" />
</intent-filter>

<!-- Intent filters for chus.me -->
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="https" android:host="chus.me" android:pathPattern="/i/.*" />
</intent-filter>
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="https" android:host="chus.me" android:pathPattern="/join/.*" />
</intent-filter>
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="https" android:host="chus.me" android:pathPattern="/j/.*" />
</intent-filter>
```

### 4. Server API Endpoints

For more details about the `chus.me` API endpoints, please see the dedicated [INVITE_LINK_SERVICE.md](./INVITE_LINK_SERVICE.md) documentation.

#### Standard Invite Resolution
Implement an endpoint at `https://rabble.community/api/invite/{code}` that returns:

```json
{
  "groupId": "R6PCSLSWB45E",
  "code": "8Z4K7JMV",
  "relay": "wss://communities.nos.social"
}
```

#### Web Invite Resolution
Implement an endpoint at `https://rabble.community/api/invite/web/{code}` that returns:

```json
{
  "groupId": "R6PCSLSWB45E",
  "code": "8Z4K7JMV",
  "relay": "wss://communities.nos.social",
  "name": "My Community Group",
  "description": "A group for discussing important topics",
  "avatar": "https://example.com/avatar.jpg",
  "createdAt": 1713745631000
}
```

#### Short URL Resolution
Implement an endpoint at `https://rabble.community/api/invite/short/{shortCode}` that returns:

```json
{
  "code": "8Z4K7JMV"
}
```

## Testing

### 1. Universal Links
- Create test links for both domains (`rabble.community` and `chus.me`)
- Share via message/email to a device with the app installed
- Click link and verify app opens with correct parameters

### 2. Custom URL Schemes
- Type a plur:// link directly in Safari
- Verify app opens correctly

### 3. Short Codes
- Generate a test short code with random characters
- Add a corresponding entry in your API endpoint
- Share and test the short code link

## Troubleshooting

### Universal Links Not Working
- Verify AASA files are properly hosted and accessible for both domains
- Check they're served with content-type: application/json
- Ensure the Team ID and Bundle ID match your app
- Associated Domains capability must be enabled
- The app must be installed from TestFlight/App Store for testing

### Custom URL Schemes Issues
- Verify URL schemes are correctly registered in Info.plist
- Check formatting of the URL
- Test with proper encoding of special characters

### API Integration
- Verify your server endpoints are reachable
- Check error handling in the app
- Validate JSON format

## iOS Runtime Verification (For Debugging)

On an iOS device, you can verify your app is properly registered for universal links using the Settings app:
1. Go to Settings > Developer
2. Scroll down to find "Universal Links"
3. Check that your app is registered for both domains

## Additional Resources

- [Apple Documentation: Universal Links](https://developer.apple.com/documentation/xcode/supporting-universal-links-in-your-app)
- [Apple Developer Tool: AASA Validator](https://search.developer.apple.com/appsearch-validation-tool/)
- [Android App Links Documentation](https://developer.android.com/training/app-links)
- [Generate Random Codes](https://www.random.org/strings/)