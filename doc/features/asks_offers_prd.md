# IMPORTANT: DO NOT IMPLEMENT UNLESS IT IS A TASK FROM TASK-MASTER-AI

PRD: Asks & Offers (Kind: 31111)

1. Overview

1.1 Purpose

This document outlines the requirements and implementation plan for adding Asks & Offers functionality to our Nostr client (and optionally to our group relay). This feature uses the kind:31111 event model, per our updated specification, enabling users to publish listings either publicly or within private groups (NIP-29 or future MLS-encrypted groups).

1.2 Objectives
	•	Allow users to create, view, and update “ask” or “offer” listings.
	•	Provide an optional group scope (h tag) for listings in private/closed contexts.
	•	Parameterize these listings with status changes, expiration, location, images, pricing, etc.
	•	Maintain a simple, intuitive UI for posting and browsing these listings.
	•	Ensure correctness and reliability via parameterized replaceable events (NIP-33 logic).

2. Scope

2.1 In-Scope
	•	Client-Side:
	•	UI flows for creating and editing Asks/Offers (kind:31111).
	•	Displaying a feed of such listings, filtering by type, status, tags, etc.
	•	Handling lifecycle updates (fulfillment, cancellation, expiration).
	•	Optional group integration (NIP-29 or an MLS approach) with h tag scoping.
	•	Relay-Side (Optional):
	•	If we operate a NIP-29 relay, implement indexing/filtering for kind:31111 events.
	•	Enforce membership/permissions for group-scoped events.
	•	Store only the latest (kind, pubkey, d) event version.

2.2 Out-of-Scope (Initial Phase)
	•	Advanced Payment flows (like NIP-69 or NIP-57 “Zaps” logic) beyond basic handling of payment tags.
	•	Reputation or rating systems for authors/buyers.
	•	Escrow or dispute resolution.
	•	MLS Encryption implementation (unless we already have a separate track for that).

3. Product Requirements

3.1 User Stories
	1.	Post an Ask:
“As a user, I want to publish a request (an Ask) on my main feed or in a private group, so others can see what I need.”
	2.	Post an Offer:
“As a user, I want to post something I have or can do (an Offer) for others to discover.”
	3.	View Listings:
“As a user, I want to see all Asks/Offers in one list, filterable by type, status, group, and keywords.”
	4.	Update/Cancel a Listing:
“As the author of a listing, I want to edit its details or mark it as fulfilled/cancelled/expired so people know its current status.”
	5.	Group-Scoped Listings:
“As a user in a private group, I want my listings to remain visible only to group members (if the group relay enforces that).”
	6.	Optional Payment/Contact:
“As a user, I want to see contact or payment instructions (e.g., LNURL) to follow up with an Ask/Offer author.”

3.2 Functional Requirements
	1.	Create Event:
	•	Must generate a kind:31111 event with required tags: d, type, title, status.
	•	.content should hold a longer description.
	•	h tag is optional. If present, it references the group ID.
	•	On submit, the client signs and publishes the event to selected relay(s).
	2.	Update Event:
	•	Re-publish with the same (kind, pubkey, d), new created_at, changes in tags or content.
	•	Relay replaces the old one (NIP-33 logic).
	3.	Lifecycle:
	•	status can be active, inactive, fulfilled, expired, or cancelled.
	•	The client must allow the user to change from active → fulfilled/cancelled/etc..
	4.	Filtering & Display:
	•	Must be able to subscribe to {"kinds":[31111]} with optional #h:["group-id"] or #type:["ask"/"offer"].
	•	UI should let users filter by type, status, or perform text search in title/.content.
	5.	Expiration (optional):
	•	If ["expires", <timestamp>] is present, the client visually indicates “Expired” once current time > <timestamp>.
	•	The user can manually set status="expired" or rely on client logic for filtering.
	6.	Group Integration (NIP-29 or MLS):
	•	If the user selects a private group, the client sets the h tag = <group-id> and publishes to that group’s relay.
	•	The relay enforces membership or encryption rules.
	7.	Payment/Contact (optional):
	•	If payment tag is present, show or link it. (E.g., LNURL, NIP-69, a simple address, or “dm_for_details”.)
	•	Provide a “Direct Message” (NIP-04) button or link to chat.

3.3 Non-Functional Requirements
	•	Performance: Listing queries should return results in under 2 seconds for typical group sizes (<1000 listings).
	•	Scalability: No inherent limit on listings. Must handle large # of events gracefully.
	•	Reliability:
	•	Must correctly handle NIP-33 replaceable logic, ensuring the latest version is displayed.
	•	Should handle relay downtime or connection issues gracefully (caching & retries).
	•	Security:
	•	Standard Nostr signature verification.
	•	If group usage is private, rely on the group protocol (NIP-29 or MLS) for admission control/encryption.
	•	Present disclaimers about no built-in escrow or protection from fraud.
	•	Usability:
	•	Straightforward listing UI, consistent with existing app flows.
	•	Minimal friction in toggling group vs. public posting.

4. UX & Design
	1.	Main Listings Screen:
	•	Displays all user-submitted Asks/Offers, sorted by newest or status.
	•	Filter bar: type = ask/offer, status, optional text search.
	2.	Posting Flow:
	•	Form:
	•	Type dropdown: Ask/Offer
	•	Title (required)
	•	Description (text area)
	•	Status (default = Active)
	•	Tags (price, location, images, etc.) in an “Advanced Options” section
	•	Group select (none/public or pick from known groups) → sets h
	•	Publish button signs & sends event.
	3.	Detail View:
	•	Shows the listing’s full .content, plus images, price, location, etc.
	•	“Author Info” → link to user’s profile or DMs.
	•	If payment is present, display a “Pay” or “Tip” button.
	4.	Manage My Listings:
	•	A dedicated screen showing a user’s own published listings.
	•	“Edit” or “Mark Fulfilled/Cancelled” buttons create a replacement event with updated status or tags.

5. Development Plan

5.1 Milestones & Phases
	1.	Phase 1: Basic Public Implementation
	•	Create the UI for posting an Ask/Offer (kind:31111) with minimal tags.
	•	Display them in a feed.
	•	Implement the replaceable logic on the client side (pull the latest event).
	•	Minimal filter by type and status.
	2.	Phase 2: Group Support
	•	Add h tag usage.
	•	If user picks a group, publish to that group’s relay.
	•	Relay enforces membership (if it’s a NIP-29 relay).
	•	Provide a “Group” filter in the UI.
	3.	Phase 3: Optional Extras
	•	Payment flows (e.g., LNURL or NIP-69).
	•	Image previews.
	•	Expiration auto-filtering.
	•	Potential encryption if we’re implementing an MLS-based group.

6. Dependencies & Assumptions
	•	NIP-33 support on relays. If a relay does not implement parameterized replaceable events, older versions might remain. We assume standard compliance among relays we care about.
	•	For private group usage, we assume a functioning NIP-29 or future MLS-based solution (membership gating, encryption, etc.).
	•	For images, we assume the user can store them on an external server or NIP-94 media approach. Our client just references the URL in image tags.

7. Risks & Mitigations
	1.	Spam or Fake Listings:
	•	Public relays can be spammy. We rely on typical Nostr blocking or relay moderation.
	•	In private groups, the admin or membership gating mitigates spam.
	2.	Stale or Conflicting Updates:
	•	If the user edits a listing from multiple devices quickly, potential conflicts arise. We rely on created_at sorting to pick the newest.
	3.	Scams / No Escrow:
	•	We must display disclaimers that trades are peer-to-peer.
	4.	Relay Connectivity:
	•	Standard approach: handle offline mode gracefully, retry publications, etc.

⸻

Implementation Checklist

Below is a checklist to track tasks through development, testing, and release.

A. Client Development
	1.	Event Model & Data Structures
	•	Create a data model for Asks/Offers in the client (fields for d, type, title, status, etc.).
	•	Support optional tags (price, location, expires, payment, etc.).
	2.	Posting & Signing Flow
	•	Implement a “New Ask/Offer” form.
	•	On submit, build a kind:31111 event.
	•	Generate unique d if new; reuse d if editing.
	•	Sign and publish to selected relays (or group relay if h is specified).
	3.	Reading & Displaying
	•	Add subscription logic: {"kinds":[31111]}.
	•	Parse tags: type, title, status, h, etc.
	•	Store only the latest event for (pubkey, d) as indicated by created_at.
	•	Display a “Listings” screen with relevant details.
	4.	Filtering
	•	Basic filter by type = ask/offer and status.
	•	Search in title/.content.
	•	Optional “group filter” if h is used.
	5.	Lifecycle & Editing
	•	Provide “Edit” UI that reuses the d tag to republish.
	•	Let user set status to fulfilled, cancelled, etc.
	•	Ensure newest event overrides older ones in local state.
	6.	Expiration Handling (if used)
	•	Check if current time > expires. Mark or hide listing.
	•	(Optional) Auto-update status="expired" in the UI or prompt the user.
	7.	Payment Integration (Optional)
	•	If payment is present, display a button or link.
	•	Provide a simple LNURL or NIP-69 flow if relevant to the client.
	8.	Group Selection
	•	If user is in a NIP-29 group (or MLS), show a “Select Group” dropdown.
	•	Insert ["h", "<group-id>"] if chosen.
	•	Publish only to that group’s relay if that’s the user’s preference.

B. Relay (If We Operate One)
	1.	Parameterized Replaceable Logic
	•	Ensure the relay implements NIP-33 for kind:31111 (store the latest (pubkey, d) version).
	2.	Tag Indexing
	•	Index h, type, status for query efficiency (especially for group usage).
	3.	Group Enforcement (NIP-29)
	•	Check membership to allow kind:31111 writes if h references our group ID.
	•	Possibly reject events if user not in the group.
	4.	(Optional) Admin Tools
	•	Allow admins to remove or ban spammers, delete events if needed.

C. Testing
	1.	Unit Tests
	•	Test event creation with required tags.
	•	Test updates (versioning, ensuring older events are replaced).
	•	Test filtering logic (type, status, group).
	2.	Integration Tests
	•	Publish events to a real test relay. Confirm listing appears in the client.
	•	Edit the event → confirm the new version is shown.
	•	Test membership gating in a private group environment.
	3.	User Acceptance Testing
	•	End-to-end with actual users posting Asks & Offers.
	•	Validate usability, clarity of statuses, basic spam handling.

D. Documentation & Release
	1.	Documentation
	•	Update any user manuals or in-app help pages about “Asks & Offers.”
	•	Document how to enable group usage, if relevant.
	2.	Deployment
	•	Release the updated client version with new UI.
	•	Deploy relay changes (if we run a group relay) to production environment.
	3.	Post-Launch
	•	Monitor usage, gather feedback.
	•	Fix discovered bugs or UI friction.
	•	Evaluate future expansions (payment flows, MLS encryption, advanced search, etc.).
