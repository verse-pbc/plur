# Changelog
All notable changes to this project will be documented in this file.

We define "Noteworthy changes" as 1) user-facing features or bugfixes 2) significant technical or architectural changes that contributors will notice. If your Pull Request does not contain any changes of this nature i.e. minor string/translation changes, patch releases of dependencies, refactoring, etc. then add the `Skip-Changelog` label.

The **Release Notes** section is for changes that the are relevant to users, and they should know about. The **Internal Changes** section is for other changes that are not visible to users since the changes may not be relevant to them, e.g technical improvements, but the developers should still be aware of.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Release Notes
- Fixed an issue where you could join the same group twice.
- Added an error message when joining a group fails.
- Added UI to create a private community.
- Added the ability for admins to generate a new invitation link for a community.
- Added ability to join a group via an invitation link (assuming Plur is installed).
- Added a new screen when viewing an empty group.
- Fixed an issue where notes wouldn't show up after being posted.
- Changed the default relay to communities.nos.social.
- Added "write post" tooltip to newly created group. [#81](https://github.com/verse-pbc/issues/issues/81)
- Fix posting note on new group bugs. [#100](https://github.com/verse-pbc/issues/issues/100)

### Known Issues
- Communities.nos.social sometimes loses group data and prevents publishing of new notes to the group.

### Internal Changes
- Set up continuous deployment of Plur iOS to TestFlight [#54](https://github.com/verse-pbc/issues/issues/54)
