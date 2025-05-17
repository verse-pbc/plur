# Changelog
All notable changes to this project will be documented in this file.

We define "Noteworthy changes" as 1) user-facing features or bugfixes 2) significant technical or architectural changes that contributors will notice. If your Pull Request does not contain any changes of this nature i.e. minor string/translation changes, patch releases of dependencies, refactoring, etc. then add the `Skip-Changelog` label.

The **Release Notes** section is for changes that the are relevant to users, and they should know about. The **Internal Changes** section is for other changes that are not visible to users since the changes may not be relevant to them, e.g technical improvements, but the developers should still be aware of.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Release Notes
- Updated app icons and launch images with the Holis logo for iOS
- Fixed iOS build process by removing Sentry SDK completely
- Simplified iOS project configuration for better maintainability
- Updated iOS deployment target to iOS 18.0
- Organized build scripts into a backup directory for reference
- Implemented modern UI design system with consistent visual language
- Redesigned onboarding experience with improved workflow and visuals
- Updated landing page with new messaging and visual design
- Enhanced button styles with rounded corners and cohesive theme

### Internal Changes
- Implemented comprehensive structured logging system:
  - Added category-based filtering (core, network, database, ui, auth, groups, events, performance)
  - Created tag-based filtering to exclude noisy components
  - Added runtime configuration via settings UI with debug override
  - Created developer test screen for verifying log functionality
  - Implemented pre-commit hooks to enforce logging standards
  - Added enhanced stack trace formatting with app code highlighting
  - Created detailed logging documentation with best practices
  - Replaced all print/debugPrint statements with structured logger
  - Fixed logging issues in report event functionality
- Improved content reporting UX:
  - Updated report dialog text to clarify reports go to community organizers
  - Modified toast notifications to mention community organizers
  - Renamed "Flag Content" to "Report to Community Organizers" for clarity
  - Added user reporting capability to profile screens
  - Implemented standardized NIP-56 report event generation for users
- Fix localization issues in calendar events feature with missing 'refresh' string
- Improve code quality with context.mounted handling for BotToast messages
- Update deprecated color API usage throughout the app to use withAlpha instead of withOpacity
- Enhance async error handling in UI components for better stability
- Improve communities grid with responsive column count for different screen sizes
- Fix loading issue with community icons and labels on initial render
- Consolidate macOS build scripts and document comprehensive build process
- Create unified solution for cryptography_flutter architecture compatibility issues on macOS
- Improve build documentation with detailed troubleshooting steps for all platforms
- Fix iOS GitHub Actions deployment with enhanced fastlane configuration 
- Improve CI build reliability with detailed error reporting and proper timeout settings
- Update Flutter flavor handling in CI for more reliable TestFlight deployments
- Remove Sentry completely to fix iOS 18 build compatibility issues
- Fix iOS build process for App Store submissions with updated exportOptions.plist

### Release Notes
- Completely redesigned onboarding flow with 4-step process:
  - Age verification (16+ requirement)
  - Nickname input with validation (3+ characters, profanity filter)
  - Optional email entry with format validation
  - Private key generation and secure storage
- New landing page with clear paths for new and existing users
- Improved login flow with dedicated form for existing users
- Enhanced login options with explicit support for nsecBunker URLs and nsec.app accounts
- Improved login form messaging to better explain login options and warn about read-only limitations
- Progress indicators showing current step in onboarding
- Back navigation between onboarding steps
- Added support for chat messages in groups following NIP-29 protocol
- Made test group joining optional with confirmation dialog
- Improved UI with tabs to toggle between posts and chat in group detail view
- Added reply functionality to chat messages
- Added support for displaying images and videos directly in chat messages
- Implemented NIP-94 imeta tag support for better image display in chat
- Added debug feature to view raw event data in chat
- Fixed blank screen issues when creating and joining communities
- Improved invitation and group creation workflow with better error handling
- Added Communities link to sidebar for easier navigation to groups page
- Added Asks & Offers feature with comprehensive response system:
  - Create and browse community listings categorized as "Asks" or "Offers"
  - Reply to listings with help offers, expressions of interest, or questions
  - Accept or decline responses as the listing creator
  - Track status of listings (active, fulfilled, cancelled, etc.)
  - Connect with community members through direct messaging
- Added Calendar & Events for communities following NIP-52:
  - View community events in list format (with calendar and map views coming soon)
  - Create and manage events with detailed information (date, time, location, visibility)
  - RSVP to events (going, interested, not going) with improved attendee lists
  - View complete lists of event attendees by RSVP status
  - Event discussion tab for community interaction about events
  - Optimistic UI updates for instant RSVP feedback
  - Filter events by visibility and date
  - Support for both time-bounded and date-bounded events
- Upgraded the floating action button to a speed-dial with multiple options:
  - Create a new post
  - Start a new chat
  - Create a new ask/offer listing
  - Create a new community
  - Toggle between grid and feed views
- Added web deployment support through Cloudflare Pages:
  - Fixed browser compatibility issues
  - Added responsive loading animation
  - Configured security headers for better protection
  - Optimized assets with proper caching strategies
  - Implemented automatic deployment via Wrangler CLI
  - Added deployment documentation and workflows
- Expanded language support with improved translations:
  - Added community-related translations for Arabic, Bulgarian, Spanish, Italian, German
  - Added new Hindi language support with community features
  - Added Traditional and Simplified Chinese translations for community features
  - Added Japanese and Korean translations for community screens
  - Added Thai translations for community features
  - Implemented empty state messages in all supported languages
- Added reliable profile lookup feature to ensure consistent user information retrieval across relays
- Fixed issue with asks/offers not appearing in groups due to inconsistent group ID format handling
- Improved chat message styling to ensure readability in both light and dark modes

### Internal Changes
- Refactored code to follow Flutter best practices with smaller, focused functions
- Fixed index mismatch in tab navigation
- Improved tab styling for better readability
- Added comprehensive unit tests for group chat functionality
- Added proper handling of image metadata including blurhash and dimensions
- Implemented aspect ratio preservation for images in chat
- Fixed AVIF image loading issues that caused crashes
- Improved BotToast error handling to prevent blank screens
- Fixed issues with unbounded constraints in layout of community screens
- Enhanced error logging and recovery to improve app stability
- Implemented response system using kind:31112 events for Asks & Offers following Nostr standards
- Enhanced group context display in Asks & Offers listings with proper navigation
- Created utility class for standardizing group ID formats across different parts of the application
- Implemented event chat messaging model and provider for future discussion functionality
- Enhanced event detail screen with tabbed interface for event details and discussions
- Improved RSVP visualization with status cards showing attendance counts
- Fixed loading state timing issues to prevent provider modification during widget lifecycle
- Improved theme support in chat widgets with proper color handling for light and dark modes
- Added user information display in all listings with profile linking
- Improved UI/UX for response options including help offers, expressions of interest, and questions
- Added flutter_speed_dial package for multi-action floating action button
- Refactored floating action button implementation for better UX
- Added view mode toggle to speed dial FAB for quick switching between grid and feed views
- Centralized action management for improved code organization
- Added web platform compatibility enhancements:
  - Fixed User-Agent header handling for web browsers
  - Created conditional imports for platform-specific code
  - Modified HTTP client setup for better cross-platform support
  - Implemented web-compatible cookie handling
  - Added Cloudflare Pages configuration with Wrangler
  - Set up CI/CD workflow for automatic web deployments
  - Added custom Flutter web initialization with error handling
  - Created optimized loading experience with smooth transitions
- Improved internationalization (i18n) infrastructure for adding and maintaining translations
- Added reliable relay profile lookup with fallback mechanisms:
  - Implemented prioritized relay query system
  - Added caching for optimized performance
  - Created fallback strategy for incomplete profile data
  - Enhanced error handling for network failures

## [0.0.5]

### Release Notes
- Fixed issue where new notes toast was not getting displayed in groups. [#250](https://github.com/verse-pbc/issues/issues/250)
- Fixed an issue where we would lose connection to the relay, resulting in content failing to load. [#260](https://github.com/verse-pbc/issues/issues/260)
- Updated the confirm button disabled color. [#279](https://github.com/verse-pbc/issues/issues/279)
- Added Admin Panel. [#263](https://github.com/verse-pbc/issues/issues/263)
- Made it easier to dismiss fullscreen images. [#286](https://github.com/verse-pbc/issues/issues/286)
- Added Cancel button when adding accounts. [#254](https://github.com/verse-pbc/issues/issues/254)

### Internal Changes
- Added functions to send push notification registration events to our relay. [#137](https://github.com/verse-pbc/plur/pull/137)
- Renamed Metadata to User for clarity. [#275](https://github.com/verse-pbc/issues/issues/275)

## [0.0.4]

### Release Notes
- Fixed an issue with mentioning users in a group. [#232](https://github.com/verse-pbc/issues/issues/232)
- Fixed issue where invite links do not work if app is not already running. [#249](https://github.com/verse-pbc/issues/issues/249)
- Fixed an issue where the group metadata events where fetch from more groups than needed. [#273](https://github.com/verse-pbc/issues/issues/273)
- Add ability to view list of members in a group [#262](https://github.com/verse-pbc/issues/issues/262)
- Added a warning that group media is public. [#246](https://github.com/verse-pbc/issues/issues/246)
- Fixed an issue where the invite button on a group page was not generating the right link. [#276](https://github.com/verse-pbc/issues/issues/276)

### Internal Changes
- Fixed bundle id and provisioning profile names for staging builds. [#220](https://github.com/verse-pbc/issues/issues/220)
- Moved fastlane scripts from `ios/fastlane/` to `fastlane/` [#104](https://github.com/verse-pbc/plur/pull/104)
- Added linting with main comparison [65](https://github.com/verse-pbc/issues/issues/65)
- Updated linting in CI to be more intelligent in comparison [65](https://github.com/verse-pbc/issues/issues/65).
- Migrated TimestampProvider from Provider to Riverpod Notifier.
- Fixed many typos.
- Fixed lint job that fails when there is a slash in the branch name.
- Add an ADR for the decision to use Riverpod [#272](https://github.com/verse-pbc/issues/issues/272)
- Fixed several lint errors with Claude Code [#116](https://github.com/verse-pbc/plur/pull/116)
- Integrated Firebase Cloud Messaging for notifications [#239](https://github.com/verse-pbc/issues/issues/239)
- Moved nostr_sdk into packages folder. [#122](https://github.com/verse-pbc/plur/pull/122)
- Fixed issue where RelayTypes were not passed to RelayPool. [#274](https://github.com/verse-pbc/issues/issues/274)
- Minor refactor of checking isAdmin and GroupDetailWidget.

## [0.0.3]

### Release Notes
- Fixed an issue where the group lists do not refresh after switching accounts. [#228](https://github.com/verse-pbc/issues/issues/228)
- Removed the "Add test groups" button from the side menu. [#256](https://github.com/verse-pbc/issues/issues/256)
- Fixed a bug where replies could be posted publicly instead of inside the group. [#251](https://github.com/verse-pbc/issues/issues/251)
- Fixed version number displayed in the main menu. [#255](https://github.com/verse-pbc/issues/issues/255)

### Internal Changes
- Removed markdown links from TestFlight release notes. [#74](https://github.com/verse-pbc/plur/pull/74)
- Added a CONTRIBUTING.md file. [#78](https://github.com/verse-pbc/plur/pull/78)
- Add a task.json that helps VSCode/Cursor execute the unit tests. [#81](https://github.com/verse-pbc/plur/pull/81)
- Moved nostr_sdk from an external submodule to an internal library. [#229](https://github.com/verse-pbc/issues/issues/229)
- Fixed TestFlight deployments by manually installing iOS 18.2. [#257](https://github.com/verse-pbc/issues/issues/257)
- Enabled separate builds for production, staging, and dev. [#220](https://github.com/verse-pbc/issues/issues/220)
- Added push notification entitlements. [#195](https://github.com/verse-pbc/issues/issues/195)
- Replaced print statemanets with the Flutter logger. [#259](https://github.com/verse-pbc/issues/issues/259)
- Fixed failing release deployment. [#220](https://github.com/verse-pbc/issues/issues/220)
- Fixed staging app id in Fastfile. [#220](https://github.com/verse-pbc/issues/issues/220)
- Replaced color constants with theme colors. [#169](https://github.com/verse-pbc/issues/issues/169)

## [0.0.2]

### Release Notes
- Change the color of rounded avatars in feeds.
- Removed unneeded options from the main menu.
- Added a new screen that allows you to generate a new keypair.
- Updated the Login screen.
- Replaced the add note button with a floating button.
- Fixed a typo in the main menu options.
- Fixed an issue where you could join the same group twice.
- Added an error message when joining a group fails.
- Added UI to create a private community.
- Added the ability for admins to generate a new invitation link for a community.
- Added ability to join a group via an invitation link (assuming Plur is installed).
- Added a new screen when viewing an empty group.
- Fixed an issue where notes wouldn't show up after being posted.
- Changed the default relay to communities.nos.social.
- Added "write post" tooltip to newly created group. [#81](https://github.com/verse-pbc/issues/issues/81)
- Fixed an issue where groups created externally would not show up. [#146](https://github.com/verse-pbc/issues/issues/146)
- Fix posting note on new group bugs. [#100](https://github.com/verse-pbc/issues/issues/100)
- Fixed an issue where the group name would not show up. [#161](https://github.com/verse-pbc/issues/issues/161)
- Updated colors for light and dark mode. [#151](https://github.com/verse-pbc/issues/issues/151)
- Fixed an issue where a user could not join a group by invitation link. [#149](https://github.com/verse-pbc/issues/issues/149)
- Fixed an issue that prevented users from logging in with a bunker URL. [#221](https://github.com/verse-pbc/issues/issues/221)
- Added a new group info screen and moved the edit group button. [#188](https://github.com/verse-pbc/issues/issues/188)
- Removed table mode option [#245](https://github.com/verse-pbc/issues/issues/245)
- Updated home screen navigation bar to match design. [#152](https://github.com/verse-pbc/issues/issues/152)
- Fixed an issue where a capitalized deep links would not work. [#252](https://github.com/verse-pbc/issues/issues/252)
- Fixed an issue when photos could not be published to a group. [#231](https://github.com/verse-pbc/issues/issues/231)


### Known Issues
- Communities.nos.social sometimes loses group data and prevents publishing of new notes to the group.

### Internal Changes
- Added unit test runs to CI, with PR comment updates [#167](https://github.com/verse-pbc/issues/issues/167)
- Added automatic sentry symbol upload [#217](https://github.com/verse-pbc/issues/issues/217)
- Added sentry crash reporting [#153](https://github.com/verse-pbc/issues/issues/153).
- Set up continuous deployment of Plur iOS to TestFlight [#54](https://github.com/verse-pbc/issues/issues/54)
- Add an ADR for the decision to use Flutter [#10](https://github.com/verse-pbc/issues/issues/10)
- Fixed the Check Changelog job [#54](https://github.com/verse-pbc/issues/issues/54)
- Added create account test. [#154](https://github.com/verse-pbc/issues/issues/154)
- Added group subscription to the communities screen to automatically refresh group data when group-related events are received. [#146](https://github.com/verse-pbc/issues/issues/146)
- Fixed an issue where video content was crashing the app. [#174](https://github.com/verse-pbc/issues/issues/174)
- Simplified imports of nostr_sdk. [#88](https://github.com/verse-pbc/issues/issues/88)
- Fixed an issue causing tests to fail. [#223](https://github.com/verse-pbc/issues/issues/223)
- Added a bypass for the linting jobs in CI. [#300](https://github.com/verse-pbc/issues/issues/300)