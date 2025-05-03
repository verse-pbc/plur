## Calendar & Events

_Add a new "Events" module in each Group, alongside Chat, Posts/Notes, and Asks & Offers._

### 1. Objective  
Enable communities to create, discover, RSVP to, and manage events—either scoped privately to the group or made public—using decentralized Nostr standards.

---

### 2. User Stories

- **As a Group Member**, I want to create events with title, description, date/time, location, so that I can organize meetups and activities.  
- **As a Group Admin**, I want to choose whether an event is private (group‑only), unlisted (public_link), or fully public, so I can control visibility.  
- **As a Member**, I want to RSVP (Going, Interested, Not Going) and see who else is attending.  
- **As a Visitor**, I want to browse public events from groups I don't belong to.  
- **As an Organizer**, I want reminder notifications (1 week, 1 day, same‑day) for my upcoming events.  
- **As a Group**, I want recurring events (weekly, monthly) and event templates for common activities.

---

### 3. Functional Requirements

#### 3.1 Event Creation & Editing  
- Form fields: Title, Description (rich text), Cover Image, Start/End (with timezone), Location (address + map link OR virtual link), Capacity, Cost, Tags.  
- Visibility toggle:  
  - **Private** = encrypted to group only  
  - **Unlisted** = plaintext, shareable link, NOT in public listings  
  - **Public** = plaintext, appears in global event feed  
- Save as draft & use templates.

#### 3.2 Event Data Model (NIP‑52 + NIP‑29 + NIP‑44)  
- **Kinds**:  
  - 31922 = date‑based events  
  - 31923 = time‑based events  
  - 31925 = RSVP events  
- **Required tags**:  
  - `["d", UUID]`  
  - `["h", "<relay>'<group-id>"]`  
  - `["v", "private"|"public_link"|"public"]`  
- **Optional tags**: `["location", …]`, `["p", …]` (organizers), `["t", …]` (category), recurrence rules.

#### 3.3 RSVP & Attendance  
- Clicking an RSVP button publishes a kind 31925 reaction with `["l","status"]`, plus the same `h` + `v` tags.  
- Display counts and attendee list in event details.

#### 3.4 Event Listing & Discovery  
- **Group Calendar View**:  
  - List, Month, Week, Map views  
  - Filters: "My RSVPs", Tags, Date range  
- **Global Events Feed**:  
  - Shows events with `v=public`  
  - Search by keyword, location radius, date.  
- **Unlisted Event Pages**:  
  - Accessible via secret URL token in the link.

#### 3.5 Notifications & Reminders  
- Schedule in‑app reminders at configurable offsets.  
- Send Nostr notifications (zaps / DMs) to RSVPed users.

---

### 4. Non‑Functional Requirements

- **Encryption**: All `v=private` events must use NIP‑44 payload encryption.  
- **Offline Support**: Cache upcoming events locally for offline viewing.  
- **Relay Efficiency**: Use tag filters (`#h`, `#v`, kinds) to minimize data.  
- **Accessibility**: WCAG 2.1 AA compliance for date pickers, forms, and maps.  
- **Performance**: Load monthly calendar in under 200 ms on 4G.

---

### 5. UI/UX Flow

1. **Group Home → "Events" Tab**  
2. **Event List** (with toolbar: "Create", Filter dropdown, Search bar)  
3. **Event Detail Page** (title, banner, details, map embed, RSVP buttons, attendee avatars)  
4. **Create/Edit Modal** (multi‑step wizard or single page with anchors)  
5. **Public Events**: `/g/<group-id>/events/public` route for SEO and sharing.

---

### 6. Acceptance Criteria

- [ ] Create Private, Unlisted, and Public events, correctly encrypted or plaintext.  
- [ ] RSVP statuses are published, updated, and displayed.  
- [ ] Group‑scoped calendar shows only `h=<group-id>` events.  
- [ ] Global feed only lists `v=public` events across groups.  
- [ ] Reminder notifications fire at scheduled times.  
- [ ] Drafts & templates persist between sessions.

---

### 7. Roadmap & Next Steps

1. **Prototype UI** (Flutter): form, list, detail → wire up NIP‑52 events.  
2. **Implement Protocol Layer**: tagging, encryption, relay publishing.  
3. **Relay Config**: support encrypted kinds 31922/31923, enforce membership.  
4. **Notification Service**: in‑app scheduler + optional email/SMS hooks.  
5. **User Testing + Iterate**: refine flows, accessible mapping, recurring logic.

```