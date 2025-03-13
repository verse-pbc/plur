fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

### debug_version

```sh
[bundle exec] fastlane debug_version
```



----


## iOS

### ios release

```sh
[bundle exec] fastlane ios release
```

Push a new Plur Release build to TestFlight

### ios deploy_staging

```sh
[bundle exec] fastlane ios deploy_staging
```

Push a new Plur staging build to TestFlight

### ios stamp_release

```sh
[bundle exec] fastlane ios stamp_release
```

Mark a deployed commit as having been deployed to our public beta testers

### ios certs

```sh
[bundle exec] fastlane ios certs
```

Refresh certificates in the match repo

### ios nuke_certs

```sh
[bundle exec] fastlane ios nuke_certs
```

Clean App Store Connect of certificates

### ios bump_major

```sh
[bundle exec] fastlane ios bump_major
```

Bump major version

### ios bump_minor

```sh
[bundle exec] fastlane ios bump_minor
```

Bump minor version

### ios bump_patch

```sh
[bundle exec] fastlane ios bump_patch
```

Bump patch version

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
