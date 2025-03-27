<div align="center">

<img src="./assets/imgs/logo/logo_android.png" alt="Nostrmo Logo" title="Nostrmo logo" width="80"/>

# Plur

Thousands of communities by and for the people.<br/></div>

## Overview

Plur is an experimental social app built for communities. Plur is built on the Nostr protocol and the [NIP-29](https://github.com/nostr-protocol/29.md) spec for communities, from the [team](https://www.verse-pbc.org/) that brought you [Nos.social](https://nos.social) and [Planetary.social](https://planetary.social).

We are indebted to the haorendashu and the [Nostrmo](https://github.com/haorendashu/nostrmo) app, whose code we used as the foundation for Plur.

## Contributing

Basic build instructions can be found below, but more instructions can be found in [CONTRIBUTING.md](CONTRIBUTING.md)

### Setting up Git Submodules

This project uses git submodules, so after you clone, be sure to initialize and update git submodules:

```bash
git submodule init
git submodule update
```

### Installing required tools

Plur uses Flutter to build, with tools and configuration files to ensure the right versions of Flutter, Dart, and Java are used. You can use either [mise-en-place](https://mise.jdx.dev) or [Homebrew](https://brew.sh) for this.

#### Using Homebrew and FVM
Homebrew is a package manager for macOS. It allows you to install tools and use them from the command line. For Plur, FVM specifies the version of Flutter that’s required to build the app. With the Homebrew setup, the required version of Java is not specified outside of this README.

1. Install [Homebrew](https://brew.sh)
2. Install CocoaPods
3. Install Java 17: `brew install openjdk@17`
4. Install [FVM](https://fvm.app), then remember to always preface Flutter commands with `fvm`.
5. Install Flutter with FVM from the `plur` directory. The correct version is specified in `.fvmrc`. Install it with `fvm install`.
6. Point Flutter at the proper version of Java: `fvm flutter config --jdk-dir /opt/homebrew/opt/openjdk@17`
7. Ensure everything is set up properly (look for green checkmarks): `fvm flutter doctor -v`
8. If the **Android toolchain** section shows a Java version of 21.0.x (or anything other than 17), Flutter will not be able to build. Try again to set the Java version using `flutter config --jdk-dir <JAVA_DIRECTORY_HERE>`

## Building the app

#### Android

##### Command line
Remember that if you’re using FVM, you always want to preface your Flutter commands with `fvm` so you can be sure you’re using the version of Flutter specified in the `.fvmrc` file. If you’re using `mise`, that’s handled internally by `mise` and the `.mise.toml` file, so you can just run `flutter` commands on their own.

1. Get dependencies with `[fvm] flutter pub get`
2. Build the app with `[fvm] flutter build apk --debug`

##### Android Studio
1. Open the root folder (`plur`) in Android Studio.
2. Android Studio may automatically prompt you to install the plugins for Dart and Flutter since you’ve opened a Flutter project. If so, you can install them from the prompt. Otherwise, search for them and install them from Settings > Plugins.
3. When prompted, restart Android Studio.
4. In Android Studio, open Settings > Languages & Frameworks > Dart. Check "Enable Dart support for the project 'plur’”.
5. Set the Dart SDK path. The location will depend on which setup you used. For mise, you run the following from your `plur` directory to copy your Dart SDK path to the clipboard: `echo $(mise where flutter)/bin/cache/dart-sdk | pbcopy`, then paste it into Android Studio (it’ll be something like `/Users/josh/.local/share/mise/installs/flutter/3.24.5-stable/bin/cache/dart-sdk`). For FVM, the path will contain your project folder and will look something like this: `/Users/josh/Code/plur/.fvm/flutter_sdk/bin/cache/dart-sdk`.
6. In Settings > Languages & Frameworks > Flutter, ensure that the path is set properly. It should either be like `/Users/josh/.local/share/mise/installs/flutter/3.24.5-stable` or  `/Users/josh/Code/plur/.fvm/flutter_sdk`.
7. Run an Android emulator using the Device Manager in the right side bar.
8. Select the running emulator in the top bar, then click the Run button.

#### iOS and macOS

##### Xcode
To run the iOS or macOS app from Xcode, start in Terminal at the root of this repository:

1. `flutter pub get`
2. `flutter build ios --debug`
3. Open the workspace, which you can do from Terminal: `open ios/Runner.xcworkspace/`
4. In the top middle of Xcode, Select `Runner` and choose a simulator or device.
5. Build and run!

##### Android Studio
To run the iOS app from Android Studio:

1. Open the root folder (`plur`) in Android Studio.
2. Android Studio should automatically prompt you to install the plugins for Dart and Flutter since you’ve opened a Flutter project. If not, search for them and install them from Settings > Plugins.
3. In the top bar, near the middle of the screen is the configuration selector. Ensure that `main.dart` is selected.
4. In the Flutter Device Selection dropdown, you can choose a device or “Open iOS simulator”. After a simulator is open, you can choose it as the run destination.
5. Click the green Run button to build and run!

Building for Mac Designed for iPad is not supported from Android Studio, and macOS (desktop) does not seem to be, either. You can use Xcode to select My Mac (Designed for iPad) and run from there.

#### Windows

```
flutter build windows --release
```

#### Web

```
flutter build web --release --web-renderer canvaskit
```

#### Linux

Linux depend on ```libsqlite``` and ```libmpv```, you can try to run this script to install before it run: 

```
sudo apt-get -y install libsqlite3-0 libsqlite3-dev libmpv-dev mpv
```

```
flutter build linux --release
```

## Project Analysis

This project uses `flutter test` and `flutter analyze` during CI, where regressions and code-quality concerns are caught as a part of the PR process. It is possible to use these tools locally, as well, alongside Dart's auto-remediation command (`dart fix`):
- Run tests locally: `fvm flutter test`
- Run linting locally: `fvm flutter analyze`
- Dry run auto-remediation: `fvm dart fix -n`
- Apply auto-remediations: `fvm dart fix --apply`

### Linting Rule Adjustments

In the scenario that specific linting rules need to be bypassed, check out the comments and links in the 
[analysis_options.yaml](./analysis_options.yaml) file, where these configurations are applied. Linting rule 
adjustments need to pass through the PR-review process alongside any other project changes.