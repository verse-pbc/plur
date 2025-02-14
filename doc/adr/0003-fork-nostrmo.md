# 3. Fork Nostrmo

Date: 2025-02-14

Authors: Matt Lorentz (mplorentz)

## Status

Accepted

## Context & Problem Statement

We are building a new app on the Nostr protocol that is focused on private and public communities, and we need to be able to iterate on it quickly to find product market fit. Given that there are several good open source Flutter Nostr clients it makes sense to explore forking one of them and customizing it for our needs. We would like a codebase that implements basic Nostr functionality like key management, handling for common event types, paging, and relay communication. 

We have already forked Nostrmo to do some initial prototyping and Flutter exploration. We chose it for the prototyping because the app seemed fully featured and had minimal bugs and already had support for NIP-29 groups. We think it would take roughly a month to port our work to another app.

## Considered Options

### Nostrmo

**Pros**:
- Most complete Nostr client.
- Already supports NIP-29 groups.
- Least buggy.
- We already built a prototype with this codebase.

**Cons**:
- Some technical debt and code that isn't up to our standards.

### Yana

**Pros**:
- Documentation and code quality seem better than Nostrmo.
- NDK seems like a nicer library than nostr_sdk.

**Cons**:
- No NIP-29 group support.

### 0xChat

**Pros**:
- Already supports NIP-29 and other group types.
- Supports Cashu.
- Clear separation of concerns between classes.

**Cons**:
- App is very buggy.
- Codebase is very large.
- Does not ship a web version.

### Other options:
We also considered camelus, Loure, flostr, nostr_console, qiqstr, and cosanostr. All of these were either no longer maintained or significantly behind the other 3 in functionality.

## Decision

We will fork Nostrmo and use it as a starting point for our app. Even though the code is not the cleanest, we have already acquired significant domain knowledge and built a prototype with it without encountering any major issues. It implements an impressive amount of Nostr functionality and it has a lightweight architecture that keeps easy tasks easy.

More notes can be found in [Notion](https://www.notion.so/nossocial/13e7c4703da080c2b6cee28e2f7810e9?v=d5e3c92e135145d1898ab45db972225b&pvs=4) (if you have access).