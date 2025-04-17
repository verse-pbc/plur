# Asks & Offers Feature – Implementation Status & Design Spec

## 🔄 Current Implementation Status

As of April 2025, the Asks & Offers feature has been implemented with the following components:

### Implemented
- **Core Nostr Integration**: Full implementation of kind:31111 event support with proper NIP-33 replacement logic
- **Data Model**: Complete ListingModel with support for all NIP-XXX fields (type, title, status, content, group scope, etc.)
- **Basic UI Screens**:
  - Listings feed with filtering by type (ask/offer) and status
  - Create/edit listing form
  - Listing detail view
- **Group Integration**: Access from group info pages with proper scoping via h tag
- **State Management**: Riverpod provider for listing state with filtering capabilities
- **Testing**: Unit and widget tests for all main components

### Access Points
- The feature is accessible via the group info page menu (newly added "Asks & Offers" option)
- Groups can now have their own isolated marketplaces for community exchange

### Technical Implementation
- Uses kind:31111 events with the Nostr SDK
- Implements parameterized replaceable events per NIP-33
- Group scoping via h tag as specified in the NIP proposal
- Real-time updates via Nostr subscription

## 🚀 Roadmap

### Phase 2 (Upcoming)
- Enhanced visual design matching the wireframes
- Location and expiration handling
- Payment/contact integration
- Image attachment support
- Specialized filtering by category/tags
- My listings dashboard

### Phase 3 (Future)
- Quick action buttons (I'm interested, I can help)
- Better notifications for listing responses
- Trust indicators and gratitude system
- Enhanced engagement metrics
- Scheduled recurring offerings

---

## ✨ Purpose & Design Spec

The original design spec is preserved below for reference.

Create a lightweight, intuitive space where community members can:
- Request help
- Offer resources, skills, or time
- Build visible trust and generosity
- Reduce burden on moderators
- Strengthen bonds between members

This system is designed based on interviews with community stewards managing both online and hybrid communities ranging from local mutual aid groups to professional peer networks.

---

## 👥 User Motivations

From real community interviews:

- Ask for help without shame
- Give back in meaningful ways
- Organize informal mutual aid
- Discover what's happening in the community
- Normalize generosity and interdependence
- Reduce loneliness and increase engagement

---

## 🧭 User Flows & Wireframes

### 1. 🏠 Main Feed / Home

**Purpose:** Overview of community activity, normalized and alive.

#### Wireframe

```
------------------------------------------------
| 🧩 Filter: All | 🧺 Category: [Any] ⏱️ Recent |
------------------------------------------------
| [ Offer ] 🎁 "Extra riding boots, size 8"     |
|            🧑 Rachel • Horseworld Group       |
|            Available through April 30        |
|            👉 "I'm interested" button         |
------------------------------------------------
| [ Ask ] 🙋‍♀️ "Need childcare help Sat"       |
|            🧑 Maggie • Comms Collective       |
|            Urgent • Brooklyn                 |
|            💬 2 replies  💡 "I can help!"     |
------------------------------------------------
| + Post an Ask | + Post an Offer              |
------------------------------------------------
```

**Features:**
- Filter by Ask / Offer / Category / Fulfilled / Mine
- Cards show icon, category, name, date, location (optional), call to action
- Quick reactions: "I can help", "Interested", "Thanks"
- Friendly tone and emojis

---

### 2. 📝 Create Ask / Offer Form

**Purpose:** Low-friction posting with helpful guidance.

#### Wireframe

```
------------------------------------------------
| What would you like to post?                |
| ( ) Ask for something                       |
| ( ) Offer something                         |
------------------------------------------------
| 🖊️ Title: ________________________________  |
| ✍️ Description (optional): ________________ |
| 📂 Category: ⬇️                            |
| 📍 Location (optional): [Auto/Manual]       |
| 🗓️ Available until: [Select date]          |
| 👁️ Visibility: ⬇️ All / Trusted circle     |
------------------------------------------------
| [Post Ask / Offer]                         |
------------------------------------------------
```

**Features:**
- Friendly prompts (e.g. "What do you need help with?")
- Optional fields (location, visibility)
- Auto-expiry default (7 days)
- Anonymity toggle (optional)

---

### 3. 📖 Post Detail View

**Purpose:** Allow deeper engagement and follow-up.

#### Wireframe

```
------------------------------------------------
| 🙋‍♀️ ASK: "Help with bike repair"           |
| 🧑 Josh • posted 3h ago • DC Neighbors       |
| 🔧 Looking for someone who knows brakes     |
| 📍 NE DC | ⏳ Expires in 4 days              |
------------------------------------------------
| 💬 Replies (3)                              |
| 🧑 Mike: "I can come Thurs evening"         |
| 🧑 Tina: "Try this YouTube vid"             |
------------------------------------------------
| ✅ [Mark as Fulfilled]                      |
| 🫶 [Say thanks publicly / privately]        |
------------------------------------------------
```

**Features:**
- Comment threads
- Trust cue ("Josh has helped 2 members")
- Status indicators (open / fulfilled)
- Ability to close loop with gratitude

---

### 4. 🙋‍♂️ My Posts Dashboard

**Purpose:** Track your own Asks & Offers and impact.

#### Wireframe

```
------------------------------------------------
| Your Posts                                   |
------------------------------------------------
| ✅ OFFER: "UX mentoring" (fulfilled)        |
| 🙋‍♀️ ASK: "Need stroller for trip" (open)   |
| 🎁 OFFER: "Old tack available"             |
| [Edit] [Mark as Fulfilled] [Delete]         |
------------------------------------------------
| 🧾 Community Impact                         |
| ✅ 3 offers fulfilled 🫶 2 thanks received   |
------------------------------------------------
```

**Features:**
- Sort/filter by status
- Visualize contributions
- Build trust via simple stats

---

### 5. 🔔 Notifications & Nudges

**Purpose:** Light, positive engagement loops.

**Examples:**
- "Someone replied to your Ask"
- "Your offer expires in 24h – still available?"
- "You helped Rachel – want to say thanks?"
- "Be the first to respond to this urgent Ask"

---

## 🔒 Trust & Safety Features

- Post expiration/removal
- Visibility toggles (public/trusted/private)
- Simple reporting for inappropriate content
- Soft moderation tools (emoji actions that notify admin)

---

## 🧠 Design Cues from Interviews

- Use emojis, badges, and color to make feed lively
- Text should encourage generosity, not guilt
- Completion and gratitude should feel good
- Let small actions (reactions, thanks) carry real weight

---

## 🛠 Future Features

- Trust leaderboard ("Most helpful this month")
- Scheduled recurring offers (e.g., weekly rideshare)
- Group tagging for orgs that span multiple communities
- QR codes to share offline needs in live events

---

## 🎯 Summary

This feature supports:
- **Mutual aid & peer exchange** (Cressida, Juliette, Josh)
- **Skill-sharing & mentorship** (Dae, Maggie, Rachel, Nuno)
- **Lightweight support for coordination** (Preston, Kaye-Maree, Vui)

It should feel like a **community bulletin board meets acts of kindness tracker**, rooted in visibility, trust, and everyday action.