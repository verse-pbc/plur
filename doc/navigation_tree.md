# Plur App Navigation Tree

## Main Navigation Structure

```
IndexWidget (/)
├── 📱 Tab 0: Communities
│   ├── Communities Grid View
│   │   └── GroupDetailWidget (/groupDetail)
│   │       ├── Tab: Notes
│   │       ├── Tab: Chat
│   │       ├── Tab: Events
│   │       ├── Tab: Asks & Offers
│   │       └── Actions Menu
│   │           ├── GroupInfoWidget (/groupInfo)
│   │           │   ├── GroupMembersWidget (/groupMembers)
│   │           │   ├── GroupAdminScreen (/groupAdmin)
│   │           │   └── GroupEditWidget (/groupEdit)
│   │           ├── InvitePeopleWidget (/inviteToGroup)
│   │           │   └── InviteByNameWidget (/inviteByName)
│   │           └── CommunityGuidelinesScreen (/communityGuidelines)
│   │
│   ├── Communities List View
│   │   └── [Same as Grid View navigation]
│   │
│   └── Communities Feed View
│       └── [Events from all communities]
│
├── 💬 Tab 1: Direct Messages
│   ├── DM Session List
│   │   └── DMDetailWidget (/dmDetail)
│   └── New Message
│       └── User Search → DMDetailWidget
│
└── 🔍 Tab 2: Search
    ├── User Search Result → UserWidget (/user)
    ├── Note Search Result → EventDetailWidget (/eventDetail)
    ├── Tag Search Result → TagDetailWidget (/tagDetail)
    └── Community Search Result → GroupDetailWidget (/groupDetail)
```

## Navigation Drawer

```
Drawer Menu
├── 🏠 Home (Table Mode Only) → Tab 0
├── 💬 DMs → Tab 1
├── 🔍 Search → Tab 2
├── 👥 Communities → Tab 0
├── 🏪 Asks & Offers → ListingsScreen (/listings)
│   ├── Create Listing → CreateEditListingScreen
│   └── Listing Detail → ListingDetailScreen
│       └── Response Dialog
├── ⚙️ Settings → SettingsWidget (/settings)
│   ├── ProfileEditorWidget (/profileEditor)
│   ├── RelaysWidget (/relays)
│   │   └── RelayInfoWidget (/relayInfo)
│   ├── FilterWidget (/filter)
│   ├── KeyBackupWidget (/keyBackup)
│   ├── NwcSettingWidget (/nwcSetting)
│   ├── RelayhubWidget (/relayhub)
│   └── WebUtilsWidget (/webUtils)
└── 👤 Account Manager → AccountManagerWidget (Modal)
```

## User Profile Navigation

```
UserWidget (/user)
├── User Top Section
│   ├── Edit Profile → ProfileEditorWidget (/profileEditor)
│   └── Follow/Unfollow Actions
├── Tab: Notes
├── Tab: Replies
├── Tab: Zaps → UserZapListWidget (/userZapList)
├── Tab: Following → FollowedWidget (/followed)
├── Tab: Communities → FollowedCommunitiesWidget (/followedCommunities)
├── Contact List → UserContactListWidget (/userContactList)
├── History Contacts → UserHistoryContactListWidget (/userHistoryContactList)
└── User Relays → UserRelayWidget (/userRelays)
```

## Event/Thread Navigation

```
Event
├── Reply → EditorWidget (/editor)
├── Thread → ThreadDetailWidget (/threadDetail)
├── Thread Trace → ThreadTraceWidget (/threadTrace)
├── Event Detail → EventDetailWidget (/eventDetail)
│   ├── User Actions → UserWidget
│   ├── Tag Actions → TagDetailWidget
│   └── Reply/Zap Actions
└── Quote → EditorWidget with quoted event
```

## Authentication Flow

```
App Launch
├── Not Logged In → LoginWidget (/login)
│   └── Sign Up → OnboardingWidget (/onboarding)
│       ├── Name Input Step
│       ├── Profile Setup
│       └── Welcome Communities
└── Logged In → IndexWidget (/)
```

## Special Navigation Features

### Deep Linking
- `plur://` custom scheme
- Universal Links support
- Community invite links: `/join/{groupId}`
- QR Code scanning: QRScannerWidget (/qrScanner)

### Modals & Dialogs
- Account Manager (Bottom Sheet)
- Color Picker Dialog
- Tag Info Dialog
- JSON View Dialog
- Various confirmation dialogs

### PC/Tablet Layout
- Fake router system for side panels
- Maintains two panes: main content + details
- Drawer can be toggled between compact/expanded

## Quick Actions

```
FAB Actions (Context Dependent)
├── In Communities Tab → Create Post
├── In DMs Tab → New DM
├── In Group Notes → Create Post
├── In Group Chat → Send Message
├── In Group Events → Create Event
└── In Group Asks & Offers → Create Listing
```

## Navigation Utilities

- **RouterUtil**: Main navigation utility
- **LinkRouterUtil**: Handles deep links
- **PcRouterFake**: Manages PC/tablet layout
- **IndexProvider**: Manages tab state

## Additional Screens

```
Other Navigable Screens
├── BookmarkWidget (/bookmark)
├── DonateWidget (/donate)
├── FollowSetListWidget (/followSetList)
│   ├── FollowSetDetailWidget (/followSetDetail)
│   └── FollowSetFeedWidget (/followSetFeed)
├── LongFormEditWidget (/longFormEdit)
├── NoticeWidget (/notice)
├── PushNotificationTestWidget (/pushNotificationTest)
└── FollowSuggestWidget (/followSuggest)
```

## Navigation Patterns

1. **Tab-based Navigation**: Main sections accessed via bottom tabs
2. **Route-based Navigation**: Detail screens accessed via named routes
3. **Modal Navigation**: Dialogs and bottom sheets for quick actions
4. **Nested Navigation**: Groups have internal tab navigation
5. **State Preservation**: Uses IndexedStack to maintain tab state
6. **Context Actions**: FAB and menu actions change based on current screen

This navigation tree represents the complete app structure as of the current codebase.