# 🛠️ Updated Product Spec: NIP-56 Content Reporting & Moderation for Nostr Group App

## 🔍 User Personas

* **Regular User**: Wants to report harmful, spammy, or abusive content.
* **Community Admin / Steward**: Needs tools to review, filter, and act on content reports.
* **Relay Operator (optional)**: May implement auto-enforcement or analytics.

---

## 🧹 Key Screens & Functional Components

### 1. **Report Submission Modal** (User-Initiated)

**Trigger**:

* Tap on "..." menu for a note or user profile
* Select **"Report"**

**Elements**:

* **Dropdown: Reason for Report**

  * Options: `spam`, `nudity`, `profanity`, `impersonation`, `malware`, `illegal`, `other`
* **Optional Text Input: Description**

  * Free-form user notes (stored in `content`)
* **Optional Checkbox**: "Include media hash (if available)"
* **Optional Trust Level Disclosure** (for group moderators): Display reporter's trust score (future NIP-32)
* **Submit Button** (Creates `kind:1984` event)

**Event Structure on Submit**:

```json
{
  "kind": 1984,
  "tags": [
    ["p", "<reported-pubkey>", "spam"],
    ["e", "<event-id>", "", "spam"]
  ],
  "content": "User posted phishing links in multiple posts."
}
```

### 2. **Admin Report Inbox Dashboard**

**Layout**:

* **Filter Bar**:

  * Report type (dropdown)
  * Status (New, Dismissed, Confirmed, Resolved)
  * Sort (Newest, Most reported, By reporter)
  * Search (by pubkey, event id, or keyword)
  * **Trust Level Filter** (based on NIP-32 metadata if available)

* **Report Card View**:

  * Reporter ID (npub or username, with optional trust score)
  * Date reported
  * Report reason (tag)
  * Target: Event or Profile
  * Action buttons: `View Note`, `View Profile`, `View Media`
  * Moderation options: `Confirm`, `Dismiss`, `Resolve`, `DM Reporter`, `DM Reported`, `React` (kind:1985)

### 3. **Report Detail View**

**Sections**:

* **Report Metadata**: Reporter, timestamp, trust level, report type
* **Target Content**: Note preview, profile preview, media attachment
* **Context Summary** (auto-generated optional)
* **Admin Notes Section**: For internal moderation notes
* **Moderation Actions**:

  * Remove Content (`kind:9005`)
  * DM users (`kind:4`)
  * Mark As: `Confirmed`, `Dismissed`, `Resolved`
  * Trigger reaction event (`kind:1985`): e.g., "7 Good call. Removed."

### 4. **Moderation Activity Log**

**Table View**:

* Timestamp
* Admin name
* Action (`dismissed`, `deleted`, `messaged`, etc.)
* Target (event or user)
* Link to source report

### 5. **Group Mod Settings**

**Admin Control Panel**:

* Enable/disable content reporting
* Configure auto-moderation:

  * Auto-hide note after X reports
  * Auto-dismiss reports from low-trust accounts
* Set required trust score for reporter (optional)
* Toggle ephemeral report expiration (e.g. auto-delete after 30 days)

---

## ⚙️ Functional Requirements

### Event Creation

* `kind:1984` with `p`, `e`, or `x` tags
* Optional `content` for description

### Event Aggregation

* Group admins can:

  * Subscribe to `kind:1984`
  * Filter by tags
  * Prioritize by trust score or number of unique reporters

### Permission Enforcement

* Only **group admins** can moderate (per NIP-29)
* Relay must support `kind:9005` for removal

### Communication & Feedback

* Use `kind:4` for DMs
* Use `kind:1985` for reactions ("Good call", "Needs review")
* Optional: feedback prompts to reporters ("Was your report handled fairly?")

---

## 🧪 Success Metrics

| KPI                             | Target                           |
| ------------------------------- | -------------------------------- |
| Avg. time to respond to reports | < 24 hours                       |
| % of reports reviewed           | > 90% within 72 hours            |
| Duplicate reports per item      | < 10% via deduplication          |
| False positive rate             | < 5% after confirmation reviews  |
| Reporter satisfaction rate      | > 80% (via optional follow-up)   |
| Group retention rate            | Improved after mod system launch |

---

## 🔬 UX Flows to Design

* Reporting (event/profile)
* Admin triage inbox
* Full report review & action
* Activity log review
* DM popup interface
* Mod settings panel
* Mobile-first UI variants

---

## ⏳ Future Features

* 🔖 Trust-based report filtering (via NIP-32)
* 🧠 ML heuristics for report prioritization
* 🚀 Reputation federation (e.g., mod-to-mod signaling)
* ♻️ Anonymous but auditable report system (e.g., one-time reply keys)
* 🧨 Optional group bot integrations (e.g. for Telegram/Slack bridging)
