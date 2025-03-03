# Changelog
All notable changes to this project will be documented in this file.

We define "Noteworthy changes" as 1) user-facing features or bugfixes 2) significant technical or architectural changes that contributors will notice. If your Pull Request does not contain any changes of this nature i.e. minor string/translation changes, patch releases of dependencies, refactoring, etc. then add the `Skip-Changelog` label.

The **Release Notes** section is for changes that the are relevant to users, and they should know about. The **Internal Changes** section is for other changes that are not visible to users since the changes may not be relevant to them, e.g technical improvements, but the developers should still be aware of.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Release Notes
- Fixed an issue where the group lists do not refresh after switching accounts. [#228](https://github.com/verse-pbc/issues/issues/228)
- Removed the "Add test groups" button from the side menu. [#256](https://github.com/verse-pbc/issues/issues/256)
- Fixed a bug where replies could be posted publicly instead of inside the group. [#251](https://github.com/verse-pbc/issues/issues/251)

### Internal Changes
- Removed markdown links from TestFlight release notes. [#74](https://github.com/verse-pbc/plur/pull/74)
- Moved nostr_sdk from an external submodule to an internal library. [#229](https://github.com/verse-pbc/issues/issues/229)
- Fixed TestFlight deployments by manually installing iOS 18.2. [#257](https://github.com/verse-pbc/issues/issues/257)

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
