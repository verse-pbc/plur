# Changelog
All notable changes to this project will be documented in this file.

We define "Noteworthy changes" as 1) user-facing features or bugfixes 2) significant technical or architectural changes that contributors will notice. If your Pull Request does not contain any changes of this nature i.e. minor string/translation changes, patch releases of dependencies, refactoring, etc. then add the `Skip-Changelog` label.

The **Release Notes** section is for changes that the are relevant to users, and they should know about. The **Internal Changes** section is for other changes that are not visible to users since the changes may not be relevant to them, e.g technical improvements, but the developers should still be aware of.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Release Notes
- Added member list to Group Info screen. [#306](https://github.com/verse-pbc/issues/issues/306)

### Internal Changes

## [0.0.5]

### Release Notes
- Fixed issue where new notes toast was not getting displayed in groups. [#250](https://github.com/verse-pbc/issues/issues/250)
- Fixed an issue where we would lose connection to the relay, resulting in content failing to load. [#260](https://github.com/verse-pbc/issues/issues/260)
- Updated the confirm button disabled color. [#279](https://github.com/verse-pbc/issues/issues/279)
- Added Admin Panel. [#263](https://github.com/verse-pbc/issues/issues/263)
- Made it easier to dismiss fullscreen images. [#286](https://github.com/verse-pbc/issues/issues/286)
- Added Cancel button when adding accounts. [#254](https://github.com/verse-pbc/issues/issues/254)
- Start caching groups metadatas thus improving the loading times. [#261](https://github.com/verse-pbc/issues/issues/261)
- Added Onboarding Age Verification screen before signup. [#283](https://github.com/verse-pbc/issues/issues/283)
- Added Community Guidelines to groups. [#264](https://github.com/verse-pbc/issues/issues/264)
- Fix inconsistent navbar background color. [#305](https://github.com/verse-pbc/issues/issues/305)
- Admin Panel: Added confirmation dialog when dismissing with unsaved changes. [#299](https://github.com/verse-pbc/issues/issues/299)

### Internal Changes
- Added functions to send push notification registration events to our relay. [#137](https://github.com/verse-pbc/plur/pull/137)
- Renamed Metadata to User for clarity. [#275](https://github.com/verse-pbc/issues/issues/275)
- Fixed all remaining lint issues. [#308](https://github.com/verse-pbc/issues/issues/308)
- Reverted deletion of Examine Lint Changes workflow job.

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
