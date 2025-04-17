# Asks & Offers Response System

## Overview

This document details the implementation plan for the response functionality within the Asks & Offers feature (kind:31111). The response system enables community members to interact with listings, express interest, and facilitate communication between parties.

## 1. Response Event Model

### 1.1 Event Structure

Responses to Asks & Offers will use kind:31112 (response events) with the following structure:

```json
{
  "kind": 31112,
  "pubkey": "responder_pubkey",
  "created_at": 1700000000,
  "tags": [
    ["e", "<original_listing_event_id>"],
    ["p", "<listing_author_pubkey>"],
    ["d", "<unique_response_id>"],
    ["response_type", "<interest|help|question|offer>"],
    ["listing_d", "<original_listing_d_tag>"],
    ["status", "<pending|accepted|declined|withdrawn>"]
  ],
  "content": "I'm interested in this item. Would it be available this weekend?",
  "sig": "<signature>"
}
```

- `kind:31112` is a parameterized replaceable event (per NIP-33)
- The `e` tag points to the original listing event
- The `p` tag identifies the original listing's author
- The `d` tag creates a unique identifier for this response
- The `listing_d` tag links to the original listing's d-value (since listings might be updated)
- The `response_type` tag categorizes the intent of the response
- The `status` tag tracks the state of the response negotiation

### 1.2 Response Types

- **interest** - General expression of interest in an offer
- **help** - Offering to fulfill someone's ask
- **question** - Seeking more information about a listing
- **offer** - Proposing terms or a counteroffer

### 1.3 Status Values

- **pending** - Initial state when response is submitted
- **accepted** - Listing owner has accepted the response/offer
- **declined** - Listing owner has declined the response/offer
- **withdrawn** - Responder has withdrawn their response

### 1.4 Additional Optional Tags

- `["price", "<number>", "<currency>", "<frequency>"]` - For counter-offers
- `["availability", "<timeframe>"]` - When the responder is available
- `["location", "<location>"]` - Suggested meetup location
- `["payment", "<type>", "<value>"]` - Payment instructions 

## 2. Response UI Components

### 2.1 Listing Detail Response Section

```
-------------------------------------------------
| 🙋‍♀️ ASK: "Help with bike repair"            |
| 🧑 Josh • posted 3h ago • DC Neighbors        |
| 🔧 Looking for someone who knows brakes      |
| 📍 NE DC | ⏳ Expires in 4 days               |
-------------------------------------------------
| 📣 [I Can Help!] [Ask a Question] [Other...]  |
-------------------------------------------------
| 💬 Responses (3)                              |
| 🧑 Mike (Help): "I can come Thurs evening"    |
|     ✅ [Accept] ❌ [Decline] 💬 [Message]      |
|                                               |
| 🧑 Tina (Question): "What kind of brakes?"    |
|     ⚠️ You replied: "Disc brakes on a MTB"    |
|                                               |
| 🧑 Sam (Help): "I work at a bike shop..."     |
|     👍 Accepted • 1 hour ago                  |
-------------------------------------------------
```

### 2.2 Response Form

```
-------------------------------------------------
| How would you like to respond?                |
| (•) I can help                                |
| ( ) Ask a question                            |
| ( ) Make an offer                             |
| ( ) Express interest                          |
-------------------------------------------------
| Your message:                                 |
| [                                           ] |
| [                                           ] |
-------------------------------------------------
| Optional details:                             |
| 📅 When: [Date/time picker]                   |
| 📍 Where: [Location field]                    |
| 💰 Price: [Amount] [Currency]                 |
-------------------------------------------------
| [Send Response] [Cancel]                      |
-------------------------------------------------
```

### 2.3 Response Management Section (My Responses)

A dedicated tab in the user's profile showing:

1. Responses they've made to others' listings
2. Responses they've received to their own listings

With status indicators and action buttons for each.

## 3. Notification System

### 3.1 Push Notifications

1. **For listing authors**:
   - "Someone responded to your ask for help with bike repair"
   - "3 people have offered to help with your request"
   - "Sam has withdrawn their offer to help"

2. **For responders**:
   - "Josh accepted your offer to help with bike repair"
   - "Your response to 'Extra riding boots' was declined"
   - "Josh sent you a message about your response"

### 3.2 In-App Notifications

Implement a notification badge and feed showing:
- New responses to your listings
- Status changes on your responses
- Follow-up messages related to responses

### 3.3 Email Notifications (Optional)

For users who opt-in, send email digests of:
- New responses requiring attention
- Accepted responses with next steps
- Reminders about expiring listings with active responses

## 4. Communication Flow

### 4.1 Direct Messaging Integration

After initial response, facilitate direct communication:

1. Add a "Message" button that opens a DM thread with context
2. Include the listing title and response content in the first message
3. Maintain connection to original listing (include e tag to listing)

### 4.2 Group Context Preservation

For responses within groups:
1. Keep all communications within the group context
2. Ensure proper h-tag inclusion
3. Respect group permissions for visibility

### 4.3 Public vs. Private Communication

Offer options for:
1. Public responses (visible to all)
2. Private responses (visible only to listing author)
3. Thread transparency toggle (allow/disallow others to see the conversation)

## 5. Implementation Phases

### Phase 1: Basic Response System
- Implement kind:31112 event creation/parsing
- Build UI for responding to listings
- Show responses on listing detail view
- Allow accept/decline actions

### Phase 2: Enhanced Management
- Add "My Responses" section to user profile
- Implement notification system
- Add status updates and history
- Build response management dashboard

### Phase 3: Communication & Integration
- Deeper DM integration with context
- Payment integration for accepted offers
- Response analytics (response rates, resolution times)
- Trust indicators based on response history

## 6. Trust & Safety Considerations

### 6.1 Spam Prevention

- Rate limit responses per user
- Allow blocking users from responding
- Flag suspicious response patterns
- Group admins can moderate responses in their groups

### 6.2 Privacy Controls

- Option to hide responder identities until accepted
- Control who can see the list of responses
- Private response option for sensitive matters

### 6.3 Dispute Resolution

- Simple reporting system for bad-faith responses
- Way to flag no-shows or unfulfilled commitments
- Optional community vouching system

## 7. User Scenarios

### Scenario 1: Offering Help
1. Alice posts an ask for "Help moving furniture"
2. Bob sees it and clicks "I Can Help"
3. Bob fills out when he's available and sends response
4. Alice receives notification, reviews Bob's response
5. Alice accepts Bob's offer
6. Both receive confirmation with contact details
7. They arrange details via DM
8. After completion, Alice marks her ask as fulfilled
9. Both can leave optional feedback

### Scenario 2: Expressing Interest in an Offer
1. Carlos posts an offer for "Free desk, pickup only"
2. Diana expresses interest with a question about dimensions
3. Carlos responds with measurements
4. Diana confirms interest and suggests pickup time
5. Carlos accepts Diana's response
6. System facilitates coordination via DM
7. After pickup, Carlos marks offer as fulfilled

### Scenario 3: Multiple Responses
1. Elena posts an ask for "JavaScript tutoring"
2. Multiple people respond offering help
3. Elena reviews all responses in her dashboard
4. She accepts one that matches her needs best
5. Other responders receive "declined" notifications
6. Elena and selected tutor proceed to coordination

## 8. Technical Details

### 8.1 Data Structures

```typescript
interface ResponseEvent {
  kind: 31112;
  pubkey: string;
  created_at: number;
  tags: [
    ["e", string],  // Original listing event ID
    ["p", string],  // Original listing author
    ["d", string],  // Unique response ID
    ["response_type", "interest" | "help" | "question" | "offer"],
    ["listing_d", string],  // Original listing's d-tag
    ["status", "pending" | "accepted" | "declined" | "withdrawn"]
    // Optional additional tags
  ];
  content: string;
  sig: string;
}
```

### 8.2 Response Storage and Indexing

Relays should index responses by:
- The original listing event ID (e tag)
- The original listing's d-tag (listing_d tag)
- The listing author's pubkey (p tag)
- The responder's pubkey (event.pubkey)

This enables efficient queries for:
- All responses to a specific listing
- All responses a user has made
- All responses to a user's listings

## 9. Code Implementation Plan

1. Create models for response events
2. Implement UI components for response creation and display
3. Build response management dashboard
4. Integrate with existing notification system
5. Add direct message integration
6. Implement analytics and reporting

## 10. Success Metrics

- Response rate per listing
- Resolution rate (% of asks/offers that get fulfilled)
- Time to first response
- Time to resolution
- User satisfaction with response process
- Repeat usage rate

This response system will create a complete loop for Asks & Offers, enabling community members to not just post needs and offerings, but to connect, communicate, and complete exchanges efficiently.