Below is an updated draft NIP that generalizes Asks & Offers beyond NIP-29—so that the same kind/tag structure can be used:
	•	Publicly on a user’s main feed,
	•	In a NIP-29 group context (closed or private relay), or
	•	In a future MLS-encrypted group (e.g., per a hypothetical NIP-107, “NIP-nn,” or any other group protocol).

Where group usage is desired, we retain the h tag for scoping to that group; otherwise, it can simply be omitted or left blank. This design keeps the parameterized replaceable approach while allowing the event to “go all the places.”

⸻

NIP-XXX

Title: Asks & Offers with Optional Group Scoping
Status: Draft (Proposed)
Dependencies:
	•	NIP-01
	•	NIP-33 (parameterized replaceable events)
	•	(Optional) NIP-29 for closed/private group relays
	•	(Optional) Proposed NIP-107 or NIP-nn for MLS-encrypted groups

Author: (Your Name or Handle)
Date: 2025-04-12
Type: Informational / Proposed Standard

1. Abstract

This specification introduces a new parameterized replaceable kind—kind:31111—for publishing Asks (requests/needs) and Offers (available items/services) on Nostr. These listings may appear:
	1.	On a public or personal feed (no group context necessary),
	2.	Within a NIP-29 group (using the h tag to scope to that group’s relay), or
	3.	Inside any future group-based encryption protocol (e.g., an MLS-encrypted group from “NIP-107” or “NIP-nn”).

The approach uses Nostr events with minimal required tags (type, title, status, and d) and an optional group identifier tag (h). Users and client software can thus manage listing lifecycles (active, fulfilled, expired, etc.), filter or discover them by group or globally, and optionally encrypt or post them on private/closed relays.

2. Motivation

Communities often desire a simple “ask/offer” marketplace or exchange mechanism. Some want it public on normal relays; others prefer it restricted to a specific group (e.g., a private NIP-29 or MLS-based group). This proposal:
	•	Unifies the concept of Asks & Offers under a single kind (31111), with an optional group tag for scoping.
	•	Enables easy updates (via parameterized replaceable events).
	•	Works equally well for purely public usage or fully private usage (encrypted events, membership gating, etc.).

While NIP-29 is one example of a group structure, the same event format could appear in any group scenario (e.g., a new NIP-107 MLS group). When no group scoping is desired, simply omit the h tag and publish to any standard relay—allowing it to live on a user’s feed.

3. Specification

3.1 Kind Definition
	•	Kind: 31111 (parameterized replaceable, per NIP-33)
	•	Identifier: A combination of (kind, pubkey, d) ensures each listing is uniquely replaceable.

3.2 Required Tags
	1.	d: A unique string (e.g., a UUID). Identifies this specific listing so that updates replace prior versions.
	2.	type: Must be either "ask" or "offer".
	3.	title: A short, descriptive title for the listing (e.g., “Need a couch”).
	4.	status: One of "active", "inactive", "fulfilled", "expired", or "cancelled".

Event Content (.content) SHOULD carry the full description or details (potentially Markdown).

3.3 Optional Tags

Tag Name	Format	Purpose/Usage	Example
h	["h", "<group-id>"]	Group scope (if used). For example, a NIP-29 or MLS group ID.	["h", "my-nip29-group"]
item	String	More specific item name or sub-category.	["item", "Laptop"]
price	["price", "<number>", "<currency>", "<frequency>"]	Price info. 3rd param can be fiat code (USD) or crypto code.	["price", "10000", "sats", "hour"]
location	String	Textual location info.	["location", "City Center Pickup"]
g	Geohash string	Precise lat/lon.	["g", "9q8yyk8y5"]
t (rep)	String	Hashtags/categories.	["t", "furniture"], ["t", "urgent"]
image(rep)	URL string	Image(s) relevant to the listing.	["image", "https://example.com/photo.png"]
expires	Unix timestamp (as string)	Timestamp after which listing is expired.	["expires", "1700000000"]
p (rep)	["p", <pubkey_hex>, <relay_url?>]	Reference to a user’s pubkey.	["p", "abc123...", "wss://relay"]
a (rep)	["a", "<kind>:<pubkey>:<d_tag>", <relay_url?>]	Reference to another addressable event.	["a", "30018:pubkey:xyz", "wss://relay"]
payment(rep)	["payment", "<type>", "<value>"]	Payment instructions (LNURL, NIP-69, etc.).	["payment", "lnurl", "lnurl1xyz..."]

If the h tag is present, it indicates the listing is intended for or within that group context—whether NIP-29, an MLS group, or something else. If omitted, the listing can be posted on a public feed or any general-purpose relay.

3.4 Creation & Updates
	1.	Creation: The user picks a unique d, sets type, title, status="active" (or "inactive"), and publishes the event.
	2.	Updates: The user re-publishes the event (same (kind, pubkey, d) triple) with new content or tags. The newest created_at version replaces the old one.
	3.	Fulfillment & Closure: Set status="fulfilled" or status="cancelled" in a new replacement event.
	4.	Expiration: If an expires tag is present, clients should treat the listing as “expired” after that time. The author may also explicitly set status="expired".

3.5 Deletion
	•	Preferred: Update with status="cancelled".
	•	Alternative: NIP-09 “Delete” event referencing the latest event ID.

⸻

4. Relay Behavior

4.1 General-Purpose (Public) Relays
	•	No special enforcement needed if the user is posting publicly (no h tag, or h is ignored).
	•	The relay simply stores these events and returns them in responses to e.g. {"kinds":[31111]} queries.

4.2 NIP-29 Group Relays (Optional)

If a user includes ["h", "<nip-29-group-id>"]:
	1.	The relay enforces membership rules to allow writing only from group members.
	2.	The relay implements parameterized replaceable logic from NIP-33, storing only the latest (kind, pubkey, d).
	3.	The relay might index the h tag (plus others) so clients can filter easily.
	4.	NIP-29’s membership, admin, and timeline checks apply as usual.

4.3 MLS-Encrypted or NIP-107 Groups (Future/Proposed)
	•	Encrypted postings would wrap the entire event content (including the .content, possibly the tags) under an MLS group key.
	•	The same structural tags can exist but are encrypted or partially hidden depending on the group’s rules.
	•	The group’s “ID” can appear in the h tag to unify discovery for group members.
	•	The group “relay” or store would similarly enforce membership and decrypt for authorized members.

⸻

5. Client Guidelines

5.1 Publishing UI
	•	Provide a form: required fields (type, title, optional group ID, etc.).
	•	If user is in a group context, auto-fill h with that group ID. Otherwise, omit it for a public feed post.
	•	If using encryption (MLS or otherwise), handle the encryption steps before sending.
	•	The .content field is recommended for a full description, potentially Markdown.

5.2 Listing & Filtering
	•	Subscribe to {"kinds":[31111]} on relevant relays.
	•	Public usage: any open relay.
	•	NIP-29 or MLS usage: the dedicated group relay with #h:["<group-id>"].
	•	Filter by type (ask or offer), status, t (hashtags), or user-specific searching.
	•	Display a list view with item summary, a detailed view with full .content.

5.3 Lifecycle & Updates
	•	For a user’s own listing, provide an “Edit” or “Mark Fulfilled” button that republishes a new event with updated tags.
	•	Always track the latest version by created_at for (kind, pubkey, d).

5.4 Payment & Communication
	•	If a payment tag is present, link or integrate with LNURL/NIP-69 or show a “Zap” button (NIP-57).
	•	For negotiation, direct to NIP-04 DMs (public or group-based).
	•	If encrypted, ensure the user can read the relevant payment instructions inside the private group scope.

5.5 Expiration & Staleness
	•	If expires is present, show listings as “expired” once the current time surpasses that timestamp.
	•	Clients may choose to hide or gray out expired listings.

⸻

6. Security & Abuse Considerations
	1.	Public vs. Private:
	•	Public usage on open relays is subject to the usual spam and impersonation concerns.
	•	Private groups (NIP-29, MLS) rely on membership gating or encryption to mitigate outsiders.
	2.	Fraud & Scams:
	•	This NIP does not provide escrow or dispute resolution.
	•	Clients should warn users about peer-to-peer transaction risks.
	3.	Encrypted Groups:
	•	If using an MLS approach (NIP-107 or similar), only authorized members can read or post listings.
	•	The relay sees only ciphertext (if fully encrypted) or partially encrypted tags, depending on the group protocol.
	4.	Replaceable Consistency:
	•	Race conditions may occur if multiple updates happen rapidly.
	•	Clients must fetch the latest event by timestamp to see the correct status.

⸻

7. Example Events

7.1 Public “Ask” on General-Purpose Relay

{
  "kind": 31111,
  "pubkey": "abcdef1234...",
  "created_at": 1700000000,
  "tags": [
    ["d", "unique-ask-123"],
    ["type", "ask"],
    ["title", "Looking for a Desk"],
    ["status", "active"],
    ["location", "NYC"],
    ["t", "furniture"]
  ],
  "content": "Need a small desk in good condition. Will pick up if in NYC area.",
  "sig": "<signature>"
}

7.2 Listing in a NIP-29 Group

{
  "kind": 31111,
  "pubkey": "groupmember123...",
  "created_at": 1700000000,
  "tags": [
    ["d", "offer-abc999"],
    ["h", "my-nip29-group-id"],
    ["type", "offer"],
    ["title", "Offering Carpool Rides"],
    ["status", "active"],
    ["location", "Local Area"],
    ["expires", "1700010000"]
  ],
  "content": "I can offer daily rides to the group meeting place. Contact me via DM.",
  "sig": "<signature>"
}

7.3 Status Update (Fulfilled)

{
  "kind": 31111,
  "pubkey": "groupmember123...",
  "created_at": 1700001000,
  "tags": [
    ["d", "offer-abc999"],
    ["h", "my-nip29-group-id"],
    ["type", "offer"],
    ["title", "Offering Carpool Rides"],
    ["status", "fulfilled"] // changed
  ],
  "content": "Carpool is fully booked now. Thanks, everyone!",
  "sig": "<signature>"
}

7.4 (Hypothetical) MLS-Encrypted Example

{
  "kind": 31111,
  "pubkey": "encrypted-pubkey123...",
  "created_at": 1700002000,
  "tags": [
    ["d", "mls-offer-456"],
    ["h", "my-mls-group-id"],
    // Possibly other encrypted tags, depending on the approach
    ["type", "offer"], 
    ["title", "Encrypted Offer - See Encrypted Content"],
    ["status", "active"]
  ],
  // .content is ciphertext readable only by group members
  "content": "-----BEGIN ENCRYPTED DATA-----ABCDEF...-----END-----",
  "sig": "<signature>"
}



⸻

8. Conclusion

NIP-XXX offers a single, flexible way to post Asks & Offers anywhere on Nostr:
	•	Public feed usage needs no special group logic—just omit h.
	•	Private group usage (NIP-29, MLS, or any membership-based approach) can attach h = <group-id> and rely on the group relay or encryption layers.

By sticking to a parameterized replaceable kind (31111) with minimal required tags, implementers can easily handle listing creation, updates, and discovery while optionally leveraging group-based membership or encryption. This approach balances simplicity with extensibility, letting each community or user decide how public or private they want their marketplace interactions to be.

Future Steps:
	1.	Gather community input and finalize kind number and spec details.
	2.	Encourage client and relay developers to experiment with support.
	3.	If desired, unify with new or existing NIPs for encrypted group usage (e.g., a proposed “NIP-107” MLS approach).
