# 5. Implement Intent-Based Post Composer ("Start Something" Flow)

Date: 2025-07-04

Authors: Rabble, Claude

## Status

Proposed

## Context & Problem Statement

Currently, the Plur app has a single-purpose compose screen that doesn't adequately address the variety of content types users might want to create within NIP-29 private groups. This limits user expression and community functionality. We need a more flexible and scalable approach to content creation that can support various Nostr event kinds while providing clear user guidance.

The existing post creation interface:
1. Does not clearly indicate what types of content can be created
2. Lacks extensibility for new content types (events, audio rooms, etc.)
3. Presents a potentially overwhelming number of options in a single interface
4. Doesn't provide guidance to users about the different posting formats

## Considered Options

### Option 1: Enhanced Single Composer
Enhance the existing compose UI with tabs or sections for different content types within a single screen.

**Pros**:
- Requires less navigation for users
- Familiar pattern for existing users
- Simpler implementation

**Cons**:
- Less scalable as we add more content types
- May become cluttered and confusing
- Difficult to provide clear intent guidance

### Option 2: Intent-Based Composer ("Start Something" Flow)
Replace the single-purpose compose button with a modular "Start Something" launcher that allows users to select their content creation intent before entering a specialized composer.

**Pros**:
- More scalable for future content types
- Clearer user guidance on available options
- Better separation of concerns in code
- Easier to feature flag and progressively roll out new content types
- Improves discoverability of different post types

**Cons**:
- Requires additional navigation step
- More code to maintain (separate composer for each type)
- Learning curve for existing users

### Option 3: Hybrid Approach
Keep the current composer for simple text posts but add a separate "Start Something" flow for more specialized content types.

**Pros**:
- Preserves familiarity for common use cases
- Introduces specialized flows where they add value
- Smoother transition for users

**Cons**:
- Potentially confusing having two entry points
- More complex implementation logic
- Less consistent user experience

## Decision

We will implement Option 2, the Intent-Based Composer ("Start Something" flow), replacing the current compose button with a modular launcher that guides users to the appropriate specialized composer based on their intent.

This approach includes:

1. A new entry point button labeled "+ Start Something" replacing or augmenting the existing compose button
2. An intent selector screen displaying a grid of content types, each routing to its corresponding composer
3. Specialized composer screens for each content type, with appropriate fields and UX
4. A modular system for adding new content types over time

Initial content types will include:
- Text Update (Kind 1)
- Chat Thread (Kind 1 with e tag)
- Event (Kind 30311)
- Audio Room (Kind 30023 + tag)
- Livestream (Kind 30023 + tag)
- Doc/Agenda (TBD)
- Ask/Offer (Kind 31990)
- Question/Poll (Kind 30023 + tag)

Each specialized composer will:
- Gather appropriate user input for that content type
- Construct a valid Nostr event with the correct kind and tags
- Handle appropriate encryption for NIP-29 groups
- Publish the event to the appropriate relays

We will implement this with feature flags to allow progressive rollout of different content types, starting with the most essential ones (Update and Thread).

## Technical Implementation Details

1. Navigation and Routing
   - Add new route for the intent selector: `/start`
   - Create routes for each specialized composer: `/compose/{type}`
   - Implement navigation flow from intent selection to composer to post-publish view

2. UI Components
   - Intent selector grid with icons and descriptive labels
   - Specialized composer forms for each content type
   - Consistent styling across composers with type-specific fields

3. Nostr Event Generation
   - Modular event construction based on content type
   - NIP-29 encryption for group privacy
   - Standardized publishing flow

4. Progressive Feature Flags
   - Toggle visibility of different content types in the intent selector
   - Allow phased rollout of new composer types

## Implementation Phases

1. **MVP Phase**
   - Implement the basic intent selector UI
   - Create composers for Update and Thread content types
   - Set up the navigation framework

2. **Expansion Phase**
   - Add Event and Question/Poll composers
   - Implement feature flagging system

3. **Complete Phase**
   - Add remaining content types
   - Implement analytics and refinements based on user feedback

This approach allows us to progressively enhance the posting experience while maintaining a clear, guided flow for users to create different types of content within their communities.