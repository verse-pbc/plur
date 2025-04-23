# macOS Build for Plur

This README provides a quick guide for building the macOS version of Plur.

## Building for macOS

We've created a single consolidated script that handles all the necessary fixes for macOS builds, dealing with the cryptography_flutter architecture compatibility issues.

### Quick Start

To build the macOS version:

```bash
# Run the consolidated build script
./build_macos.sh
```

That's it! The script will handle everything for you:
- Clean the project
- Update dependencies
- Configure architecture settings
- Fix plugin registration issues
- Build the macOS app

### Running the App

After building, you can run the app with:

```bash
flutter run -d macos
```

## Documentation

For detailed information about the macOS build solution:

- **[MACOS_BUILD_FIX.md](MACOS_BUILD_FIX.md)** - Comprehensive documentation of the solution
- **[MACOS_BUILD_MADNESS.md](MACOS_BUILD_MADNESS.md)** - History of the troubleshooting process

## Cleanup

We've consolidated multiple fix scripts into a single solution. To clean up redundant scripts:

```bash
# Optional: Remove all redundant scripts
./cleanup_macos_scripts.sh
```

This will remove all the old fix scripts, leaving only the consolidated solution.

## Troubleshooting

If you encounter issues with the macOS build:

1. Make sure you're on macOS with Xcode installed
2. Check that you have CocoaPods installed (`gem install cocoapods`)
3. Run the build script again (`./build_macos.sh`)
4. See [MACOS_BUILD_FIX.md](MACOS_BUILD_FIX.md) for detailed troubleshooting steps

## Release Builds

For release builds:

```bash
# First run the build script to set up everything
./build_macos.sh

# Then build for release
flutter build macos --release

# If the release build fails, run the build script again
./build_macos.sh
flutter build macos --release --no-tree-shake-icons
```