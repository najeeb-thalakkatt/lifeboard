# features.md — Lifeboard Feature Specification

> Complete feature reference for the Lifeboard app. Each feature includes description, acceptance criteria, and platform considerations.

---

## 1. Authentication & Onboarding

### 1.1 Welcome Screen
- **Description:** First screen shown to unauthenticated users. Sets the emotional tone.
- **Elements:**
  - Lifeboard logo (kayaker motif) on `#77B5B3` background
  - Tagline: "Plan life together, simply."
  - "Get Started" button (primary, filled `#2F6264`)
  - "I already have an account" link (text button)
- **Animation:** Subtle wave animation behind logo on load (Lottie or animated container)
- **Platform notes:**
  - iOS/Android: full-screen, no status bar overlap
  - Web: centered card layout with max-width 480px

### 1.2 Sign Up / Log In
- **Methods:**
  - Email + password
  - Google Sign-In
  - Apple Sign-In (required for iOS App Store, available on web)
- **UX:**
  - Single screen with toggle between "Sign Up" and "Log In"
  - Inline validation (email format, password 8+ chars)
  - Loading state on submit
  - Error messages: warm tone ("Hmm, that didn't work. Try again?")
- **Post-auth:** Create Firestore `users/{uid}` doc on first sign-up, then route to Create/Join Space

### 1.3 Create / Join Space
- **Option A — Create:** Enter space name (default "Our Home"), creates space + generates 6-character invite code
- **Option B — Join:** Enter invite code or tap invite link → joins existing space
- **Validation:** Invalid/expired invite code shows friendly error
- **Skip:** Not possible — user must be in at least one space to proceed

### 1.4 Invite Partner
- **Shown after:** Creating a new space
- **Share methods:** Copy invite code, share link (platform share sheet), QR code display
- **Skip option:** "You can always invite later" → proceeds to dashboard
- **Deep link:** `https://lifeboard.app/join?code=XXXXXX` opens app or web with pre-filled code

---

## 2. Home Dashboard

### 2.1 Space Cards
- **Description:** Scrollable list of all spaces the user belongs to.
- **Card contents:**
  - Space name (e.g., "Our Home", "Vacation 2026")
  - Member avatars (max 3 shown, +N overflow)
  - Summary: "4 tasks due this week" / "1 new comment" / "All clear! 🎉"
  - Last activity timestamp
- **Interactions:** Tap → opens board view for that space. Long press → space options (rename, leave, delete if owner)
- **Empty state:** "No spaces yet. Create one to get started!" with illustration

### 2.2 Quick Actions
- **FAB or header button:** "New Space" to create additional spaces
- **Pull-to-refresh:** Refreshes space list and summaries
- **Search:** Filter spaces by name (shown when >5 spaces)

### 2.3 Layout
| Platform | Layout | Navigation |
|----------|--------|------------|
| Mobile   | Single column, vertical card list | Bottom nav (4 tabs) |
| Tablet   | 2-column card grid | Navigation rail |
| Desktop  | 3-column card grid, sidebar | Persistent side drawer |

---

## 3. Board View (Kanban)

### 3.1 Kanban Columns
- **Default 3 columns:**
  - "To Do" (neutral teal tint)
  - "Working on it" (warm amber tint)
  - "We did it! 🎉" (green/celebration tint)
- **Mobile layout:** Vertical stacked columns (each collapsible), or horizontal swipe between columns (user preference in settings)
- **Tablet/Desktop:** Horizontal side-by-side columns, equal width, scrollable within each

### 3.2 Task Cards
- **Preview contents:**
  - Task title (1–2 lines, truncated)
  - Assignee avatar(s) (small, bottom-left)
  - Due date with calendar icon (bottom-right, red if overdue)
  - Emoji tag badge (top-right corner)
  - Subtask progress indicator: "2/4 ✓" (if subtasks exist)
- **Styling:**
  - Rounded 12px corners
  - White surface with soft shadow
  - Left color stripe matching emoji tag category (optional)
- **Interactions:**
  - Tap → open task detail
  - Long press → start drag for reorder / column move
  - Swipe right → quick-complete (move to Done with celebration)

### 3.3 Drag & Drop
- **Within column:** Reorder cards (updates `order` field)
- **Across columns:** Move card between statuses (updates `status` + `order`)
- **Visual feedback:** Card elevates on drag, target column highlights
- **Sync:** Optimistic UI update → Firestore batch write in background
- **Platform notes:**
  - Mobile: long-press-initiated drag
  - Desktop/Web: click-and-drag
  - All: smooth animation on card insert at new position

### 3.4 Quick Add Task
- **Location:** Bottom of each column, "+" icon with "Add a task" placeholder text
- **Behavior:** Tap to expand inline text field, type title, press Enter/Submit
- **Defaults:** Status set to column's status, no assignee, no due date
- **Follow-up:** Optional "Add details" link appears after creation to open task detail

### 3.5 Board Toolbar
- **Left:** Board/space name with dropdown to switch boards
- **Right:** Filter icon, "Plan Week" shortcut
- **Filter options:** By assignee, by emoji tag, by due date range, overdue only
- **Board switcher:** Dropdown or bottom sheet listing all boards in the space

### 3.6 Multiple Boards
- **Per space:** Users can create multiple boards (e.g., "Home Repairs", "Vacation Planning")
- **Default board:** Auto-created "General" board when space is created
- **Board themes:** Each board can have a theme tag (Home, Kids, Health, Trips, Finances, Custom)
- **Management:** Rename, reorder, archive boards from board settings menu

---

## 4. Task Detail

### 4.1 Core Fields
| Field | Type | Notes |
|-------|------|-------|
| Title | Inline editable text | Bold, large font. Auto-saves on blur |
| Status | Dropdown | "To Do" / "Working on it" / "We did it! 🎉" |
| Assignees | Avatar picker | Me / Partner / Both / specific member |
| Due date | Date picker | Material date picker, shows relative ("in 3 days") |
| Description | Text area | Plain text with optional markdown. Auto-saves |
| Emoji tag | Picker | 💰🏡❤️🧠💪☀️ — single selection |

### 4.2 Subtasks
- **Checklist-style:** Each subtask has title + checkbox
- **Add:** "+ Add subtask" button at bottom of list
- **Reorder:** Drag handle on each subtask
- **Progress:** Shown on task card as "X/Y ✓"
- **Auto-complete:** When all subtasks checked, prompt "Mark task as done?"

### 4.3 Attachments
- **Supported:** Photos (camera + gallery), files (PDF, docs)
- **Upload:** Firebase Storage, linked in task document
- **Display:** Thumbnail grid for images, file icon + name for documents
- **Limit:** Max 10 attachments per task, max 10MB per file
- **Platform:** Camera option on mobile only; file picker on all platforms

### 4.4 Comments & Reactions
- See Feature §7 below for full spec.

### 4.5 Completion Celebration
- **Trigger:** Status changes to "done" (via dropdown, drag-drop, or "Mark Done" button)
- **Animation:** Full-screen Lottie confetti overlay, 2-second duration
- **Haptic:** `HapticFeedback.mediumImpact()` on iOS/Android
- **Sound:** Optional subtle chime (respects device silent mode)
- **"Mark Done 🎉" button:** Prominent at bottom of task detail, teal filled, large

### 4.6 "Discuss Later" Toggle
- **Purpose:** Flag a task for discussion without cluttering comments
- **Display:** Small toggle at top of task detail
- **Effect:** Adds 💬 badge on task card; shows in a "To Discuss" filter on board

---

## 5. Weekly View ("This Week")

### 5.1 Sections
- **"Our Week":** All tasks marked for this week across all boards in the space (shared view)
- **"My Tasks":** Filtered to tasks assigned to current user
- **"Next Up":** Auto-populated with tasks due in the next 7 days not yet in the weekly plan

### 5.2 Plan Week Flow
- **Entry point:** "Plan Week" button on board toolbar or weekly view
- **Modal/bottom sheet:** Lists backlog tasks (all To Do + In Progress not in weekly plan)
- **Selection:** Tap to toggle tasks into/out of weekly plan
- **Batch action:** "Add X tasks to This Week" confirmation button
- **Auto-suggestion:** Tasks with due dates this week are pre-selected

### 5.3 Week Navigation
- **Header:** "Week of Feb 23 – Mar 1" with ← → arrows
- **Default:** Current week. Can browse past weeks to review.
- **Week start:** Monday (configurable in settings)

### 5.4 Progress Summary
- **Top card:** "You've completed X of Y tasks this week!" with progress bar
- **Completion:** "You did it all! 🎉" with celebration animation when 100%
- **Partner comparison:** Not competitive — framed as "Together you completed X tasks"

### 5.5 Weekly Reflection
- **Trigger:** Sunday evening notification (configurable)
- **In-app prompt:** "You both completed X tasks! Want to plan next week?"
- **Taps:** "Plan Next Week" → opens plan week flow for next week. "Maybe Later" → dismiss.

---

## 6. Shared Access & Collaboration

### 6.1 Space Membership
- **Roles:** Owner (creator, can delete space) and Member (full CRUD on tasks/boards)
- **Max members per space:** 10 (MVP — expandable later)
- **Join methods:** Invite code (6-char), share link, QR code

### 6.2 Task Assignment
- **Options:** Unassigned, Me, Partner/specific member, Both/Everyone
- **Visual:** Assignee avatars shown on task cards and in task detail
- **Filter:** Board can be filtered by assignee

### 6.3 Real-Time Sync
- **All data:** Spaces, boards, tasks, comments sync in real-time via Firestore streams
- **Conflict resolution:** Last-write-wins (Firestore default). Optimistic UI with background sync.
- **Offline:** Firestore offline persistence enabled. Changes queue and sync when online.
- **Visual indicator:** Subtle "syncing..." indicator when offline changes are pending

### 6.4 Presence (Future)
- **Not in MVP.** Future: show "Partner is viewing this board" indicator.

---

## 7. Comments & Reactions

### 7.1 Task Comments
- **Location:** Bottom section of task detail screen
- **Display:** Chronological list, each showing author avatar, name, text, relative timestamp
- **Input:** Text field at bottom with send button
- **Real-time:** Firestore subcollection stream, new comments appear instantly

### 7.2 Reactions
- **On comments:** Quick-tap emoji reactions: ❤️ 👍 😂 😅
- **Display:** Reaction pills below each comment (emoji + count)
- **Toggle:** Tap to add/remove your reaction
- **On activity feed items:** Same reaction system

### 7.3 "Discuss Later" Integration
- Comments section can be accessed from tasks flagged "Discuss Later"
- 💬 badge on board view for flagged tasks

---

## 8. Activity Feed & Notifications

### 8.1 Activity Feed
- **Location:** 🔔 Activity tab in bottom nav
- **Content:** Chronological feed of space activity:
  - "Alex moved *Clean Garage* to Done 🎉"
  - "Jamie added a comment to *Plan Anniversary Trip* ❤️"
  - "3 tasks due this weekend"
  - "Sam joined the space!"
- **Interactions:** Tap activity card → navigate to related task. Quick reactions on feed items.
- **Scope:** Aggregated across all user's spaces, grouped by space

### 8.2 Push Notifications
- **Triggers:**
  - Task moved to Done by partner
  - New comment on a task you're assigned to or commented on
  - New member joined your space
  - Tasks due today (morning digest)
  - Weekly reflection prompt (Sunday evening)
  - Gentle nudge: "How about finishing [task] together?" (configurable frequency)
- **Delivery:** Firebase Cloud Messaging (FCM)
- **Platform setup:**
  - iOS: Request permission after onboarding, APNs configuration
  - Android: Default notification channel "Lifeboard Updates"
  - Web: Service worker for FCM, browser notification permission

### 8.3 Notification Preferences
- **Per-user settings:**
  - Push notifications: on/off
  - Task updates: on/off
  - Comments: on/off
  - Weekly reflection: on/off
  - Gentle nudges: on/off + frequency (daily, every 3 days, weekly)
- **Do not disturb:** Quiet hours setting (e.g., 10pm–8am)

### 8.4 Badge Count
- **Bottom nav:** Unread count badge on 🔔 Activity tab
- **App icon:** Platform badge count (iOS + Android)

---

## 9. Profile & Settings

### 9.1 Profile
- **Display name:** Editable
- **Photo:** Upload from camera/gallery, stored in Firebase Storage
- **Mood emoji:** Pick one emoji to display on your avatar (optional, fun)

### 9.2 Space Management
- **List:** All spaces with member count
- **Actions:** Rename (owner only), leave space, delete space (owner only, confirmation required)
- **Invite:** Regenerate invite code, share link

### 9.3 App Settings
- **Theme:** Light / Dark / System default
- **Week start:** Monday (default) or Sunday
- **Kanban layout (mobile):** Stacked vertical or horizontal swipe
- **Notifications:** See §8.3 above

### 9.4 "Our Stats" (Gamification Display)
- **Total tasks completed together:** All-time count
- **Current streak:** Consecutive weeks where at least 1 task completed
- **Best streak:** All-time record
- **Badges earned:** Visual grid of unlocked badges (see §10)
- **This month:** Tasks completed, tasks created, comments made

### 9.5 Account
- **Change password** (email auth only)
- **Sign out**
- **Delete account:** Confirmation dialog, removes user data, leaves spaces (transfers ownership if sole owner)

---

## 10. Gamification & Motivation

### 10.1 Streaks
| Streak | Definition | Display |
|--------|-----------|---------|
| Weekly streak | At least 1 task completed per week | 🔥 X weeks on profile |
| Duo streak | At least 1 task completed by each member per week | ❤️‍🔥 X weeks on profile |
| Daily streak | At least 1 task completed per day | ⚡ X days (secondary) |

### 10.2 Badges
| Badge | Trigger | Icon |
|-------|---------|------|
| First Steps | Complete first task | 👶 |
| Team Player | Complete 10 tasks together | 🤝 |
| On a Roll | 4-week streak | 🎯 |
| Unstoppable | 12-week streak | 🚀 |
| Century | 100 total tasks completed | 💯 |
| Planner Pro | Use weekly view 4 weeks in a row | 📋 |
| Communicator | Leave 50 comments | 💬 |

### 10.3 Nudges & Encouragement
- **Gentle nudges:** "How about finishing *[task]* together this weekend?"
- **Positive reinforcement:** "You're on a 3-week streak! Keep it going 💪"
- **No shaming:** Never "You haven't completed any tasks this week" — always constructive
- **Partner celebrations:** "Alex just completed *[task]*! 🎉"
- **Configurable:** All nudges can be turned off in notification preferences

### 10.4 Weekly Reflection
- **Trigger:** Sunday evening (configurable time)
- **Content:** "This week: You completed X tasks together! Top accomplishment: [most recent done task]"
- **CTA:** "Plan next week?" → opens planning flow

---

## 11. Cross-Platform & Responsive Design

### 11.1 Breakpoints
| Size | Width | Target |
|------|-------|--------|
| Small | < 600px | Phones (iOS + Android) |
| Medium | 600–1024px | Tablets, small laptops |
| Large | > 1024px | Desktop browsers |

### 11.2 Navigation Patterns
| Size | Navigation | Board Layout |
|------|-----------|-------------|
| Small | Bottom nav bar (4 tabs) | Stacked columns or horizontal swipe |
| Medium | Navigation rail (left) | 3 columns side-by-side, scrollable |
| Large | Side drawer (persistent) | 3 columns + sidebar with task detail inline |

### 11.3 Platform-Specific Behaviors
| Feature | iOS | Android | Web |
|---------|-----|---------|-----|
| Auth | Apple + Google Sign-In | Google Sign-In | Apple + Google Sign-In |
| Notifications | APNs via FCM | FCM native | Browser notifications |
| Haptics | UIImpactFeedbackGenerator | Vibrator API | None |
| Share | UIActivityViewController | Android share intent | Web Share API / clipboard |
| Camera | AVFoundation | CameraX | MediaDevices API |
| Deep links | Universal Links | App Links | URL routing |
| Install | App Store | Play Store | PWA (Add to Home Screen) |

### 11.4 Offline Support
- Firestore offline persistence: enabled by default on mobile, configured for web
- Tasks and boards available offline (cached)
- Writes queued and synced on reconnection
- Visual indicator: subtle banner "You're offline — changes will sync when connected"

---

## 12. Accessibility

### 12.1 Standards
- WCAG 2.1 Level AA compliance target
- Minimum contrast ratio 4.5:1 for text, 3:1 for UI components
- All interactive elements have semantic labels

### 12.2 Features
- **Screen reader support:** All task cards, buttons, and navigation labeled with `Semantics` widgets
- **Dynamic type:** Supports system font size scaling (iOS + Android)
- **Keyboard navigation (Web/Desktop):** Tab order, Enter to activate, Escape to close modals
- **Reduce motion:** Respect system "reduce motion" preference, disable confetti animation
- **Color-blind safe:** Status columns use shape/icon indicators in addition to color
- **Focus indicators:** Visible focus rings on interactive elements

---

## 13. Data & Privacy

### 13.1 Data Storage
- All data stored in Firebase (Firestore + Storage)
- Region: configurable per Firebase project (default: closest multi-region)
- Encryption: at rest (Firebase default) and in transit (HTTPS)

### 13.2 Privacy
- **Minimal data collection:** Only name, email, profile photo (optional)
- **No third-party data sharing** (beyond Firebase/Google infrastructure)
- **Analytics:** Firebase Analytics with anonymized user IDs
- **GDPR compliance:** Data export and deletion endpoints
- **Privacy policy:** Accessible from settings and onboarding

### 13.3 Account Deletion
- **Flow:** Settings → Delete Account → Confirmation → 30-day grace period → permanent deletion
- **Scope:** Removes user doc, leaves spaces (ownership transferred), anonymizes activity history

---

## Feature Priority Matrix

| Priority | Features | Phase |
|----------|---------|-------|
| **P0 — Must Have** | Auth, Spaces, Kanban Board, Task CRUD, Real-time Sync | 0–5 |
| **P0 — Must Have** | Task Detail (assignees, due dates, status), Bottom Nav | 6 |
| **P1 — Should Have** | Comments/Reactions, Weekly View, Activity Feed | 7–9 |
| **P1 — Should Have** | Push Notifications, Profile/Settings | 9–10 |
| **P2 — Nice to Have** | Gamification (streaks, badges), Celebrations, Emoji Tags | 6, 11 |
| **P2 — Nice to Have** | Subtasks, Attachments, "Discuss Later" toggle | 6 |
| **P3 — Future** | AI-powered "Next Up" suggestions, Presence indicators | Post-MVP |
| **P3 — Future** | Calendar integration, Recurring tasks, Templates | Post-MVP |
| **P3 — Future** | Multi-language support (l10n), Custom themes | Post-MVP |
