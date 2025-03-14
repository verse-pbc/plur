# 4. Use Riverpod for state management

Date: 2025-03-14

Authors: Bryan Montz (bryanmontz)

## Status

Accepted

## Context & Problem Statement

Plur currently uses a combination of Flutter's built-in state management APIs (`StatefulWidget`, `ChangeNotifier`, etc.) and Provider, a Google-endorsed package that has some significant shortcomings that could be addressed.

## Considered Options

### [Provider](https://pub.dev/packages/provider)
**Pros**:  
* Plur's existing code uses this.  
* Decent [documentation](https://pub.dev/documentation/provider/latest/).  

**Cons**:  
* Memory management: All of the app's providers (components of state management) are initialized at launch, even if the user never ends up needing them. This does not make the app a good citizen of the operating system. Both Android and iOS terminate apps that overuse memory, potentially confusing and inconveniencing users who expect the app to resume rather than re-launch.  
* Architecture: Initializing all of the app's providers at launch also causes the `main.dart` file, where the app's lifecycle begins, to be difficult to read and maintain.  
* Caching: Caching is manual and difficult to get right, which can cause problems such as data being loaded more or less frequently than would be optimal for user experience.

### [Riverpod](https://riverpod.dev)
**Pros**:  
* Automatic caching (with flexible options).  
* Async APIs.  
* Easier error handling.  
* Efficient memory cleanup.  
* Well [documented](https://riverpod.dev).  
* Busy [developer community](https://github.com/rrousselGit/riverpod/discussions).  
* Excellent tooling, such as [riverpod lint](https://pub.dev/packages/riverpod_lint).  

**Cons**:  
* Will temporarily cause multiple state management strategies to coexist in the codebase.  
* Requires importing a third-party package.  
* The package is essentially maintained by [one person](https://github.com/rrousselGit).  

### Other Options
[Bloc](https://bloclibrary.dev) is another option for state management in Flutter. It was not considered because no one on the team had experience with it.

## Decision

We will use Riverpod for state management moving forward. Decisions about which existing providers to migrate to Riverpod will be made on a case-by-case basis.
