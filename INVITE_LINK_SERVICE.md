# Chus.me Invite Link Service

This document describes how the invite link service for Chus.me works, specifically for integration with the Plur mobile application.

## Overview

The invite link service, hosted at `https://chus.me`, provides several types of invite links to allow users to join community groups. These links are designed to work seamlessly with the Plur mobile app via deep linking and also provide a web-based fallback for users who may not have the app installed.

## Invite Link Types

There are three main types of invite links generated and handled by the service:

1.  **Standard Invites:**
    *   Format: `https://chus.me/i/<code>`
    *   Behavior: Directly redirects to a deep link for the Plur mobile app.
2.  **Web Invites (Rich Invites):**
    *   Format: `https://chus.me/join/<code>`
    *   Behavior: Displays an HTML page with metadata about the group (name, description, avatar). This page provides options to:
        *   Open directly in the Plur app (if installed) via a deep link.
        *   Navigate to the appropriate app store (Google Play Store or Apple App Store) to download the Plur app.
        *   Continue in a web browser (if web app functionality is available).
3.  **Short URL Invites:**
    *   Format: `https://chus.me/j/<shortCode>`
    *   Behavior: These are shortened versions of either standard or web invites. The `chus.me` service resolves the `shortCode` and then redirects to the corresponding full invite URL (`/i/<code>` or `/join/<code>`). The subsequent behavior is then identical to that of the resolved invite type.

## Deep Linking for Flutter App

The primary mechanism for the Flutter app to handle invites is through deep links.

*   **Deep Link Format:** `plur://join-community?group-id={GROUP_ID}&code={CODE}&relay={ENCODED_RELAY_URL}`

*   **Parameters:**
    *   `group-id` (string): The unique identifier of the community group the user is invited to.
    *   `code` (string): The invite code associated with this specific invitation.
    *   `relay` (string, URL encoded): The URL of the relay server to be used for this group. This parameter will be URL encoded.

When the Flutter app is opened via this deep link, it should:
1.  Parse the `group-id`, `code`, and `relay` parameters from the URL.
2.  Use this information to facilitate the process of joining the specified community group.

## Handling Invite Links in the Flutter App

### 1. Standard Invites (`https://chus.me/i/<code>`)
   - When a user clicks this link:
     - The `chus.me` service at `/i/<code>` endpoint will issue a 302 redirect to `plur://join-community?group-id={GROUP_ID}&code={CODE}&relay={ENCODED_RELAY_URL}`.
     - The mobile OS will intercept this deep link and open the Plur app.
     - The Flutter app needs to be configured to handle the `plur://` scheme and the `join-community` host/path.
     - Upon receiving the deep link, the app extracts the `group-id`, `code`, and `relay` to proceed with joining the group.

### 2. Web Invites (`https://chus.me/join/<code>`)
   - When a user clicks this link:
     - The `chus.me` service at `/join/<code>` will render an HTML page.
     - This page contains a button/link "Open in Plur App" which, when clicked, navigates to the `plur://join-community?...` deep link as described above.
     - If the user clicks this button and has the app, the Flutter app will open and handle the deep link.
     - If the user doesn't have the app, they can use links on the page to go to the app stores.

### 3. Short URL Invites (`https://chus.me/j/<shortCode>`)
   - When a user clicks this link:
     - The `chus.me` service at `/j/<shortCode>` first resolves the `shortCode` to its original invite code.
     - It then determines if the original invite was a standard invite or a web invite.
     - It then redirects to either `https://chus.me/i/<code>` or `https://chus.me/join/<code>`.
     - The handling then proceeds as per point 1 or 2 above, depending on the resolved invite type.

## API for Creating Invites (Server-Side)

The Flutter mobile app typically does **not** directly create invites. Invite creation is usually handled server-side or by other administrative tools due to the need for an authorization token.

However, for completeness, the invite creation API endpoint is:

*   **Endpoint:** `POST /api/invite` (on `https://chus.me`)
*   **Authorization:** Requires a Bearer token in the `Authorization` header. The token is stored in the `INVITE_TOKEN` environment variable on the server.
*   **Request Body (JSON):**
    ```json
    {
      "groupId": "string", // Required: ID of the group
      "relay": "string",   // Required: Relay URL for the group
      // Optional metadata for creating a "Web Invite"
      // If these are present, a `/join/<code>` link is created
      // If absent, an `/i/<code>` link is created
      "name": "string",         // Optional: Name of the group
      "description": "string",  // Optional: Description of the group
      "avatar": "string",       // Optional: URL to an avatar image for the group
      "creatorPubkey": "string" // Optional: Public key of the invite creator
    }
    ```
*   **Success Response (200 OK):**
    *   For standard invites:
        ```json
        {
          "code": "generated_code",
          "url": "https://chus.me/i/generated_code"
        }
        ```
    *   For web invites:
        ```json
        {
          "code": "generated_code",
          "url": "https://chus.me/join/generated_code"
        }
        ```
*   **Error Responses:**
    *   `400 Bad Request`: Missing required fields (`groupId`, `relay`).
    *   `401 Unauthorized`: Invalid or missing `INVITE_TOKEN`.
    *   `500 Internal Server Error`: Server-side error during invite creation.

## Error Handling

If an invite code is invalid, expired, or not found, the `chus.me` service will typically display an error page. The Flutter app should be prepared for scenarios where a deep link might be invoked but the underlying invite is no longer valid (e.g., by communicating with a backend service to validate the invite details if necessary before proceeding).

## Universal/App Links Configuration

For the Plur app to seamlessly handle `chus.me` links, proper configuration is required on both iOS and Android:

### iOS:
1. Add `applinks:chus.me` to the Associated Domains entitlement in Xcode.
2. Ensure the `apple-app-site-association` file is hosted at `https://chus.me/.well-known/apple-app-site-association` with proper configuration.

### Android:
1. Add intent filters to your `AndroidManifest.xml` for each type of `chus.me` invite link:
   ```xml
   <!-- Intent filter for chus.me standard invites -->
   <intent-filter android:autoVerify="true">
       <action android:name="android.intent.action.VIEW" />
       <category android:name="android.intent.category.DEFAULT" />
       <category android:name="android.intent.category.BROWSABLE" />
       <data android:scheme="https" android:host="chus.me" android:pathPattern="/i/.*" />
   </intent-filter>

   <!-- Intent filter for chus.me web invites -->
   <intent-filter android:autoVerify="true">
       <action android:name="android.intent.action.VIEW" />
       <category android:name="android.intent.category.DEFAULT" />
       <category android:name="android.intent.category.BROWSABLE" />
       <data android:scheme="https" android:host="chus.me" android:pathPattern="/join/.*" />
   </intent-filter>

   <!-- Intent filter for chus.me short URL invites -->
   <intent-filter android:autoVerify="true">
       <action android:name="android.intent.action.VIEW" />
       <category android:name="android.intent.category.DEFAULT" />
       <category android:name="android.intent.category.BROWSABLE" />
       <data android:scheme="https" android:host="chus.me" android:pathPattern="/j/.*" />
   </intent-filter>
   ```
2. Ensure the `assetlinks.json` file is hosted at `https://chus.me/.well-known/assetlinks.json` with your app's package name and SHA-256 fingerprint.

## Testing and Validation

To validate your implementation, test each link type:

1. Create and share a `https://chus.me/i/<code>` link
2. Create and share a `https://chus.me/join/<code>` link
3. Create and share a `https://chus.me/j/<shortCode>` link

Ensure that each link opens the app directly (when installed) and shows the appropriate fallback experience when the app is not installed. 