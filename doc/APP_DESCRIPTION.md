# Plur: A Community-Focused Social App

## Overview

Plur is a decentralized social application built on the Nostr protocol that puts communities at the center of the user experience. Unlike traditional social networks that focus on individual feeds and algorithmically curated content, Plur is designed around shared spaces where people with common interests can congregate, share, and organize.

The app redefines online communities through a blend of public forums, real-time chat, and social coordination tools—all built on decentralized infrastructure that gives users control of their data and community spaces.

## Vision

The vision for Plur is to create a community platform that combines the best aspects of forums, chat applications, and social networks while maintaining user sovereignty and privacy. We aim to build tools that help communities flourish through better organization, resource sharing, and coordination.

## Core Principles

1. **Community-Centric:** Communities are first-class citizens, not an afterthought.
2. **User Sovereignty:** Users own their data and identity through the Nostr protocol.
3. **Practical Utility:** Features focus on practical tools that help communities function better.
4. **Simplicity:** Complex features are made accessible through thoughtful UI/UX.
5. **Interoperability:** Works with the broader Nostr ecosystem.

## How Groups Work in Plur

Groups are the foundational unit of organization in Plur, implemented using Nostr's NIP-29 standard for secure, encrypted group communication.

### Group Structure

- **Group Creation**: Any user can create a new community group, establishing a unique identifier on the Nostr network
- **Membership Management**: Creator becomes the initial admin with ability to invite others and designate additional admins
- **Encryption**: All group content is encrypted with group-specific keys, ensuring only members can access content
- **Persistence**: Group content is stored across Nostr relays but only decryptable by authorized members

### Group Interactions

Groups support multiple interaction forms:

1. **Notes Feed**: Similar to a forum or social media stream where longer-form content is shared
   - Public-within-group content visible to all members
   - Media support for images and videos
   - Threaded comments for discussion
   - Reactions (zaps, likes, emoji responses)

2. **Chat**: Real-time messaging channel within the group
   - Casual, immediate conversation
   - Message reactions
   - Inline media sharing
   - Typing indicators and read receipts

3. **Asks & Offers**: Resource sharing marketplace within each group
   - Members can post requests for assistance or resources
   - Members can post offers of skills, items, or services
   - Category-based organization (e.g., labor, goods, rides, services)
   - Direct responses and private follow-up

4. **Media Gallery**: Shared collection of images and videos posted to the group
   - Chronological and grid views
   - Search and filter capabilities
   - Album organization

### Group Discovery & Joining

- **Invitation Links**: Secure, shareable links that grant access to groups
- **QR Codes**: Scannable codes for in-person group joining
- **Public Discovery**: Optional public listings for groups that wish to be discoverable
- **Relay Recommendations**: Groups can specify preferred relays for optimal performance

### Group Administration

- **Roles**: Support for admin and member roles, with planned support for custom roles
- **Moderation Tools**: Content removal, member muting or removal
- **Guidelines**: Ability to establish and display group rules and norms
- **Activity Metrics**: Insights into group engagement and growth

### Technical Implementation

- Built on Nostr's group chat protocol (NIP-29)
- Event types for different content categories (chat, posts, etc.)
- Client-side encryption with libsecp256k1
- Group metadata stored in Kind 39000 events
- Group messages in Kind 39001-39008 events depending on content type

## Key Features

### Current Features

1. **Community Groups**
   - Creating and joining community spaces
   - Community chat and discussion 
   - Posts and media sharing within communities
   - Community guidelines and moderation tools

2. **Asks/Offers System**
   - Resource sharing functionality
   - Community members can post requests for help or offers to share
   - Categorization and filtering of asks/offers
   - Responses and private messaging

3. **Multi-Format Communication**
   - Standard posts/notes
   - Real-time chat
   - Media sharing (images, videos)
   - Rich content embedding

4. **Nostr Protocol Integration**
   - Decentralized identity
   - Relay management
   - Encrypted messaging
   - Cross-platform compatibility

### Planned Features

1. **Community Calendar** (In Development)
   - Event scheduling and management
   - RSVP functionality
   - Event discovery
   - Integration with asks/offers for event coordination
   - Reminders and notifications

2. **Resource Directory**
   - Organized repository of community resources
   - Searchable and categorized information
   - Wiki-like collaboration features

3. **Polls and Decision Making**
   - Community polling and voting
   - Consent-based decision processes
   - Results visualization

4. **Enhanced Media Sharing**
   - Better support for images, videos, and documents
   - Gallery views for community media
   - Media organization tools

5. **Location-Based Features**
   - Geographical community discovery
   - Local event coordination
   - Map visualization for in-person meetups

## Calendar Feature Concept

The upcoming calendar feature will enhance Plur's ability to support community organizing and coordination by creating a robust event system within groups—inspired by protest.net, Meetup, lu.ma, and Facebook Group events but built on decentralized infrastructure.

### Core Calendar Functionality

1. **Community-Focused Event Creation**
   - Group-specific events (every event belongs to a specific group)
   - Rich event details including:
     - Title and description with rich text formatting
     - Cover image/banner for visual appeal
     - Date and time with timezone awareness
     - Duration specification 
     - Location details (physical address with map integration or virtual meeting link)
     - Attendance capacity limits
     - Cost information (if applicable)
     - Multiple organizers and contact information
   - Event visibility options:
     - Group-only (visible only to group members)
     - Public-linkable (accessible via direct link, even to non-members)
     - Fully public (discoverable in public event listings)
   - Event categorization with customizable tags per group
   - Event series and recurring events (daily, weekly, monthly, custom)
   - Draft saving and event templates for frequent event types

2. **Activist-Friendly Features**
   - Security level settings (protest.net-inspired):
     - Public events
     - Semi-private (location revealed only to confirmed attendees)
     - Private organizing events (by invitation only)
   - Legal observer and emergency contact designation
   - Action/event roles assignment
   - Optional event encryption for sensitive organizing
   - Contingency planning section

3. **Social RSVP and Attendance Management**
   - Multi-option RSVP (Going, Interested, Not Going)
   - Private RSVP option for sensitive events
   - Attendance tracking and check-ins
   - Customizable attendance questions:
     - Transportation needs/offers
     - Dietary preferences
     - Accessibility requirements
     - Skills offering
     - Equipment bringing
   - Waitlist management with automatic promotion
   - Guest list management with manual approval options
   - Co-host and organizer delegation
   - Attendance metrics and insights

4. **Rich Interactive Event Pages**
   - Dedicated event discussion threads
   - Photo sharing for event documentation
   - Post-event feedback and surveys
   - Document attachments (agendas, maps, etc.)
   - Weather integration for outdoor events
   - Dynamic updates with change tracking
   - Related events suggestion

5. **Calendar Views and Discovery**
   - Group calendar (showing all events within a group)
   - Consolidated personal calendar (events across all joined groups)
   - Multiple view options:
     - List view (chronological, categorized)
     - Calendar grid (day, week, month)
     - Map view for geographical browsing
     - Timeline view
   - Saved filters and custom views (e.g., "My RSVPs", "Weekend Events")
   - Upcoming events highlight on group home page
   - Event recommendations based on interests and past attendance

6. **Resource Coordination (Integration with Asks/Offers)**
   - Event-specific resource needs automatically converted to asks
   - Task assignments and volunteer sign-ups
   - Equipment and supply tracking
   - Ride sharing and carpooling coordination
   - Skill-matching for event roles
   - Budget tracking and expense sharing
   - Post-event resource redistribution

7. **Notification and Communication System**
   - Smart notification schedule:
     - Event announcement
     - RSVP deadline reminders
     - Upcoming event alerts (1 week, 1 day, same day)
     - Event changes or updates
     - Post-event follow-ups
   - Multi-channel notifications (in-app, email, optional SMS)
   - Event-specific messaging to attendees
   - Organizer broadcast messages
   - Weather alerts for outdoor events
   - Custom notification preferences per event type
   - Calendar subscription options

8. **Technical Architecture**
   - Events stored as specialized Nostr events (Kind 31111) with calendar-specific tags
   - RSVP system using Nostr reactions with specialized RSVP metadata
   - Group context maintained through encrypted h-tags
   - Local caching for offline viewing of event details
   - Incremental synchronization to minimize data usage
   - Attendance tracking through specialized "attended" reactions
   - Calendar export/import using standard iCal format
   - Future integration with external calendars (Google, Apple, Outlook)

### User Experience Priorities

- **Simplified Creation:** Quick event creation with smart defaults based on group type
- **Discoverability:** Easy browsing and filtering of relevant events
- **Mobile Optimization:** Complete mobile experience for on-the-go coordination
- **Engagement Tools:** Features that encourage participation and follow-through
- **Privacy Controls:** Granular privacy settings recognizing the sensitivity of organizing data
- **Organizer Insights:** Metrics and tools to help organizers improve events over time

## Target Users

1. **Community Organizers**
   - People who lead or facilitate local communities
   - Event planners and coordinators
   - Resource coordinators and mutual aid organizers

2. **Interest-Based Communities**
   - Hobby groups
   - Skill-sharing circles
   - Special interest communities

3. **Local Neighborhood Groups**
   - Neighborhood associations
   - Local mutual aid networks
   - Geographically based communities

4. **Existing Nostr Users**
   - Users looking for better community tools within the Nostr ecosystem
   - Users who value data sovereignty and privacy

## Technical Foundation

Plur is built on:
- Flutter for cross-platform development
- Nostr protocol for decentralized social networking
- Riverpod for state management
- Local-first architecture with relay synchronization

## Success Metrics

1. **Community Engagement**
   - Active users within communities
   - Message and content creation frequency
   - Resource sharing activity

2. **Organizational Effectiveness**
   - Successful asks/offers connections
   - Event attendance and coordination
   - Community resource utilization

3. **User Growth and Retention**
   - New user acquisition
   - Community creation rate
   - User retention rates

4. **Feature Utility**
   - Feature usage metrics
   - User feedback on feature effectiveness
   - Time spent using organizational features vs. passive consumption

## Long-term Vision

Plur aims to be the platform of choice for communities that want to organize effectively without surrendering their data or autonomy to centralized platforms. By building practical, community-oriented tools on the decentralized Nostr protocol, we hope to enable more resilient, self-determined communities both online and in the physical world.

Our roadmap emphasizes features that help communities coordinate resources, share knowledge, and organize activities—supporting the full spectrum of community functions rather than just content consumption or basic messaging.