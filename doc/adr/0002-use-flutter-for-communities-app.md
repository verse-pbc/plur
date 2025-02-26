# 2. Use Flutter For Communities App

Date: 2025-02-05

Authors: Matt Lorentz

## Status

Accepted

## Context & Problem Statement

We have been tasked with building a new app on the Nostr protocol that is focused on private and public communities. The app needs to work well across all platforms (iOS, Android, web, desktop), it needs to be performant, and we need to be able to iterate on it quickly to find product market fit. We want to keep the development team we have built while working on Nos.social, which is a team of native iOS developers.

## Considered Options

Our full research docs are in our company's [Notion](https://www.notion.so/nossocial/Cross-Platform-Development-Evaluation-13d7c4703da08015bf51ca12cca8f697?pvs=4) repository, but we will summarize the top options below.

### Native

**Pros**:
- Most polished UI.
- Best runtime performance.
- Fewest dependencies.

**Cons**:
- Slowest iteration time as code must be written separately for each platform.
- Our team does not have much Android, web, or desktop experience.

### Kotlin Multiplatform

**Pros**:
- Polished UI - you can write native UI for each platform.
- Business logic and model code can be shared across all platforms.
- Kotlin is very similar to Swift which we have a lot of experience with.
- Flexibility: you can later transition to fully native apps incrementally.

**Cons**:
- Our team does not have much Kotlin or Android experience.
- Iteration time is slower than a cross-platform tool because UI must be designed and written separately for each platform.

### Flutter

**Pros**:
- Fastest iteration time - Flutter tooling is well set up for quick iteration cycles, and most code will be shared across all platforms.
- This is the technology that our team has the most experience with after native iOS.
- Good runtime performance and multithreading compared to most other cross-platform tech.
- Good automated testing tools.

**Cons**:
- The Dart programming language does not aid the developer as much as Swift or Kotlin.
- UI will never feel fully native.
- The dependency stack is deep, and Flutter encourages adoption of many small dependencies.

## Decision

We will build this app using Flutter. Flutter best meets our need to iterate quickly, and has good tooling to sustain long term development. It is the tech stack our team is most familiar with. It gives us the flexibility to deploy on whatever platforms we find are necessary, including Windows, macOS, Linux, and the web. 

Giving up native UI is a tradeoff we are willing to make given that most of the competition in the community space are doing the same. We can also accept the inefficiencies that come with the Dart programming language and the ecosystem of many dependencies, given that they are offset by shipping one codebase to all platforms.
