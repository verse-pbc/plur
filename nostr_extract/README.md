# Nostr SDK and NIP-29 Implementation

This directory contains an extraction of the Nostr SDK and NIP-29 (group messaging) implementation from the Plur/Verse application. The code here demonstrates how to implement and interact with Nostr group functionality according to the NIP-29 specification.

## Directory Structure

- `nip29/`: Contains the core NIP-29 implementation for Nostr groups
- `lib/`: Contains shared library code that supports the NIP-29 implementation
- `app/`: Contains application-specific code that uses the NIP-29 library

## NIP-29 Features Implemented

- Group creation and management
- Group metadata handling
- Group member management (add/remove)
- Admin permissions and roles
- Group moderation (post removal, user banning)
- Group invitations

## Usage

The code in this directory serves as a reference implementation of Nostr groups based on NIP-29. You can use it as a starting point for your own Nostr client implementation that supports groups.

See the documentation in each subdirectory for more specific information about the implementation details.