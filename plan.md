# plan.md — Lifeboard Implementation Plan

> Step-by-step build order for Claude Code. Each phase is a logical milestone. Complete phases in order — each builds on the previous.

---

## Phase 0: Project Scaffold & Infrastructure
**Goal:** Runnable Flutter app with Firebase connected on all platforms.

- [x] **0.1** Create Flutter project: `flutter create lifeboard`
- [x] **0.2** Set up folder structure per `CLAUDE.md` (theme/, core/, models/, providers/, services/, screens/, widgets/)
- [x] **0.3** Add core dependencies to `pubspec.yaml`:
  - `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`
  - `firebase_messaging`, `firebase_analytics`
  - `flutter_riverpod` / `riverpod`
  - `go_router`
  - `google_fonts`
  - `lottie`
  - `freezed`, `json_serializable`, `build_runner` (dev)
- [x] **0.4** Run `flutterfire configure` for iOS, Android, Web (project: lifeboard-8cd26)
- [x] **0.5** Initialize Firebase in `main.dart` with `ProviderScope`
- [x] **0.6** Set up `analysis_options.yaml` with recommended lints
- [x] **0.7** Verify app runs on iOS (confirmed), Android and Web (pending user test)

**Notes:**
- iOS deployment target raised to 15.0 (required by Firebase SDK 12.8.0)
- CocoaPods specs repo needed `pod repo update` for Firebase/Firestore 12.8.0
- Android release signing still uses debug keys (address before production)

**Deliverable:** App boots and connects to Firebase on all 3 platforms.

---

## Phase 1: Design System & Theme
**Goal:** Consistent visual foundation matching brand identity.

- [x] **1.1** Create `app_colors.dart` with all palette colors from CLAUDE.md
- [x] **1.2** Create `app_text_styles.dart` with Nunito (headings) + Inter (body) definitions
- [x] **1.3** Create `app_theme.dart` with light ThemeData:
  - Color scheme from brand palette
  - Card theme (rounded 12px, soft shadow)
  - Button themes (filled teal, rounded)
  - Input decoration theme
  - AppBar theme (flat, teal or white)
  - Bottom nav bar theme
- [x] **1.4** Add dark theme variant (optional but scaffold the toggle)
- [x] **1.5** Add font assets or configure `google_fonts` package
- [x] **1.6** Create `constants.dart` with warm label mappings:
  ```dart
  static const statusLabels = {
    'todo': 'To Do',
    'in_progress': 'Working on it',
    'done': 'We did it! 🎉',
  };
  ```
- [x] **1.7** Create shared widgets: `bottom_nav_bar.dart`, `shared_app_bar.dart`, `avatar_widget.dart`

**Deliverable:** Themed app shell with bottom nav bar and consistent styling.

---

## Phase 2: Authentication
**Goal:** Users can sign up, log in, and persist sessions.

- [x] **2.1** Create `auth_service.dart`:
  - Email/password sign up + sign in
  - Google Sign-In
  - Apple Sign-In (iOS + Web)
  - Sign out
  - Auth state stream
- [x] **2.2** Create `auth_provider.dart` (Riverpod):
  - `authStateProvider` (StreamProvider wrapping `authStateChanges()`)
  - `currentUserProvider`
- [x] **2.3** Create `user_model.dart` (freezed or manual)
- [x] **2.4** Set up Firestore `users/{userId}` document creation on first sign-up
- [x] **2.5** Configure GoRouter with auth redirect:
  - Unauthenticated → onboarding/login
  - Authenticated → home dashboard
- [x] **2.6** Build Welcome Screen (`welcome_screen.dart`):
  - Logo on teal background
  - "Plan life together, simply." tagline
  - "Get Started" and "Log In" buttons
- [x] **2.7** Build Sign Up / Log In screen (email + social buttons)
- [x] **2.8** Write unit tests for `auth_service.dart`

**Deliverable:** Full auth flow — user can sign up, log in, and stay logged in.

---

## Phase 3: Spaces (Core Data Layer)
**Goal:** Users can create and join shared spaces.

- [x] **3.1** Create `space_model.dart`
- [x] **3.2** Create Firestore service methods in `firestore_service.dart`:
  - `createSpace(name, userId)` → generates invite code
  - `joinSpace(inviteCode, userId)`
  - `getSpacesForUser(userId)` → stream
  - `getSpaceMembers(spaceId)` → stream
- [x] **3.3** Create `space_provider.dart`:
  - `userSpacesProvider` (StreamProvider)
  - `createSpaceProvider` (mutation)
  - `joinSpaceProvider` (mutation)
- [x] **3.4** Build "Create / Join Space" screen:
  - "Start a new space" option (name input, default "Our Home")
  - "Join a space" option (invite code input)
- [x] **3.5** Build "Invite Partner" screen:
  - Display invite code + share link
  - "Skip for now" option
- [x] **3.6** Deploy initial Firestore security rules
- [x] **3.7** Write tests for space CRUD operations

**Deliverable:** Users can create a space, get an invite code, and partners can join.

---

## Phase 4: Home Dashboard
**Goal:** Central hub showing all user's spaces with previews.

- [x] **4.1** Build `home_dashboard_screen.dart`:
  - "Welcome back, [Name] 👋" header
  - List of space cards (name, task count preview, last activity)
  - Tap card → navigate to board view
  - FAB or button to create new space
- [x] **4.2** Wire up bottom nav bar with 4 tabs:
  - 🏠 Spaces (home dashboard)
  - 📅 This Week (placeholder)
  - 🔔 Activity (placeholder)
  - 👤 Profile (placeholder)
- [x] **4.3** Implement responsive layout:
  - Mobile: bottom nav, single column card list
  - Tablet: navigation rail, 2-column grid
  - Desktop: side drawer, 3-column grid
- [x] **4.4** Add pull-to-refresh

**Deliverable:** Dashboard with live space list, navigation shell working on all sizes.

---

## Phase 5: Boards & Tasks — Core Kanban
**Goal:** The heart of the app — kanban board with tasks.

- [x] **5.1** Create `board_model.dart` and `task_model.dart`
- [x] **5.2** Firestore service methods:
  - `createBoard(spaceId, name, theme)`
  - `getBoards(spaceId)` → stream
  - `createTask(spaceId, task)`
  - `updateTask(spaceId, taskId, fields)`
  - `deleteTask(spaceId, taskId)`
  - `getTasksForBoard(spaceId, boardId)` → stream, ordered by `order`
- [x] **5.3** Create `board_provider.dart` and `task_provider.dart`
- [x] **5.4** Build `board_view_screen.dart`:
  - 3 columns: "To Do", "Working on it", "We did it! 🎉"
  - Mobile: horizontal scroll between columns or vertical stacked view
  - Each column shows task cards, sorted by `order`
  - "+ Add Task" button at bottom of each column
- [x] **5.5** Build `task_card.dart` widget:
  - Title, assignee avatar, due date icon, emoji tag
  - Teal/pastel card styling per theme
- [x] **5.6** Build `kanban_column.dart` with drag-and-drop:
  - `LongPressDraggable` on cards
  - `DragTarget` on columns
  - Optimistic local reorder + Firestore batch write
- [x] **5.7** Quick-add task: inline text field at column bottom
- [x] **5.8** Top bar: board name, filter icon, "Plan Week" shortcut
- [ ] **5.9** Write widget tests for board and task card rendering

**Notes:**
- Firestore composite index (`boardId` + `order`) was missing — created `firebase/firestore.indexes.json` and deployed.
- `firebase.json` updated to include `indexes` path under `firestore` config.
- Known issue: assignee avatars show raw Firebase UID initials (e.g. "5") instead of display names. `board_view_screen.dart:84-90` falls back to userId — needs user doc lookup.

**Deliverable:** Functional kanban board with drag-and-drop, real-time sync, task creation.

---

## Phase 6: Task Detail Screen
**Goal:** Rich task editing — the shared note experience.

- [x] **6.1** Build `task_detail_screen.dart`:
  - Inline-editable title
  - Assignee picker (Me / Partner / Both) with avatars
  - Status dropdown (warm labels)
  - Due date picker (Material date picker, styled)
  - Description field (rich text or plain with checklist toggle)
  - Subtasks list (add, check off, delete)
  - Emoji tag picker
  - Attachment section (photos from camera/gallery, files)
- [x] **6.2** Build `emoji_tag_picker.dart` (grid of emoji options)
- [x] **6.3** Implement file upload via `storage_service.dart` + Firebase Storage
- [x] **6.4** "Mark Done 🎉" button at bottom
- [x] **6.5** Build `celebration_overlay.dart`:
  - Lottie confetti animation (find/add Lottie JSON asset)
  - Triggered on status change to done
  - Haptic feedback on mobile
- [x] **6.6** Wire all edits to Firestore via providers (debounced auto-save)
- [x] **6.7** Test task detail CRUD operations

**Deliverable:** Full task editing with celebrations, attachments, subtasks, and emoji tags.

---

## Phase 7: Comments & Reactions
**Goal:** Lightweight communication on tasks.

- [ ] **7.1** Create `comment_model.dart`
- [ ] **7.2** Firestore methods: `addComment`, `getComments` (stream), `addReaction`
- [ ] **7.3** Comments section in task detail screen:
  - Scrollable comment list with author avatar, text, timestamp
  - Text input at bottom
  - Quick reaction buttons on each comment (❤️ 👍 😂 😅)
- [ ] **7.4** Real-time stream for comments subcollection
- [ ] **7.5** Test comment creation and reaction toggling

**Deliverable:** Users can comment on tasks and react to comments in real-time.

---

## Phase 8: Weekly View ("This Week")
**Goal:** Focused planning view for the current week.

- [x] **8.1** Build `weekly_view_screen.dart`:
  - "Our Week Plan" section — shared tasks marked for this week
  - "My Tasks" section — filtered to current user
  - "Next Up" section — tasks with due dates in next 7 days
- [x] **8.2** Implement "Plan Week" flow:
  - Bottom sheet or modal listing backlog tasks
  - Select tasks → toggle `isWeeklyTask` + set `weekStart`
- [x] **8.3** Week navigation: previous/next week arrows
- [x] **8.4** Weekly summary card at top: "You've completed X of Y tasks this week!"
- [x] **8.5** Wire to bottom nav "📅 This Week" tab
- [x] **8.6** Gentle prompt at week end: "Want to plan next week together?"

**Deliverable:** Weekly planning and review view with shared + personal task filtering.

---

## Phase 9: Activity Feed & Notifications
**Goal:** Keep partners in sync with real-time updates.

- [ ] **9.1** Create `activity_model.dart`
- [ ] **9.2** Write Cloud Functions (TypeScript):
  - `onTaskWrite` → create activity entry + send FCM to other members
  - `onCommentCreate` → create activity entry + send FCM
- [ ] **9.3** Deploy Cloud Functions
- [ ] **9.4** Build `activity_feed_screen.dart`:
  - Chronological feed of activity cards
  - "Alex moved Clean Garage to Done 🎉"
  - Quick reactions on feed items
- [ ] **9.5** Implement `notification_service.dart`:
  - FCM token management
  - Foreground/background notification handling
  - Platform-specific setup (iOS permissions, Android channels)
- [ ] **9.6** Wire to bottom nav "🔔 Activity" tab
- [ ] **9.7** Badge count on activity tab icon

**Deliverable:** Real-time activity feed + push notifications across platforms.

---

## Phase 10: Profile & Settings
**Goal:** User management, preferences, and fun stats.

- [x] **10.1** Build `profile_settings_screen.dart`:
  - Profile section: name, photo (upload), emoji mood
  - Spaces management: list, leave, delete
  - Notification preferences: push toggle, email toggle
  - Theme toggle: light/dark mode
- [x] **10.2** "Our Stats" section:
  - Total tasks completed together
  - Current streak (consecutive weeks with completed tasks)
  - Fun badges display area
- [x] **10.3** Account actions: change password, sign out, delete account
- [x] **10.4** Wire to bottom nav "👤 Profile" tab

**Deliverable:** Complete profile and settings with stats gamification.

---

## Phase 11: Gamification & Motivation
**Goal:** Badges, streaks, and celebratory feedback loops.

- [ ] **11.1** Define badge/streak logic:
  - Weekly streak: tasks completed every week
  - Duo streak: tasks completed together
  - Milestone badges: 10, 50, 100 tasks done
- [ ] **11.2** Cloud Function to compute streaks (weekly scheduled)
- [ ] **11.3** Badge display in profile "Our Stats"
- [ ] **11.4** Weekly reflection notification: "You both completed X tasks this week!"
- [ ] **11.5** Gentle nudge notifications (configurable):
  - "How about finishing [task] together this weekend?"
  - Respects notification preferences

**Deliverable:** Streak tracking, badges, weekly reflections, and motivational nudges.

---

## Phase 12: Polish & Platform Optimization
**Goal:** Production-ready quality across iOS, Android, and Web.

- [ ] **12.1** Responsive layout audit: test all screens on phone, tablet, desktop
- [ ] **12.2** Platform-specific polish:
  - iOS: Cupertino-style date pickers, haptics, safe area handling
  - Android: Material You support, back gesture handling
  - Web: PWA manifest, service worker, keyboard shortcuts
- [ ] **12.3** Offline support: Firestore offline persistence (enabled by default, verify)
- [ ] **12.4** Loading states & error handling: shimmer placeholders, error snackbars, retry logic
- [ ] **12.5** Empty states: friendly illustrations for no tasks, no spaces, no activity
- [ ] **12.6** Onboarding tooltips for first-time board/task usage
- [ ] **12.7** App icon and splash screen (teal bg + kayaker logo)
- [ ] **12.8** Deep linking for invite codes (Universal Links / App Links)
- [ ] **12.9** Performance profiling: Firestore read optimization, image caching
- [ ] **12.10** Accessibility audit: screen reader labels, focus order, contrast

**Deliverable:** Polished, accessible, performant app on all platforms.

---

## Phase 13: Testing & CI/CD
**Goal:** Automated quality gates and deployment pipeline.

- [ ] **13.1** Unit tests: all services and providers (target 80%+ coverage)
- [ ] **13.2** Widget tests: all screens and key widgets
- [ ] **13.3** Integration tests: auth flow, create space → add task → complete → celebrate
- [ ] **13.4** GitHub Actions workflows:
  - PR: `flutter analyze` + `flutter test`
  - Main: build + deploy web to Firebase Hosting
  - Release: build APK/IPA via Fastlane
- [ ] **13.5** Fastlane setup for iOS (TestFlight) and Android (Play Console internal track)

**Deliverable:** CI/CD pipeline running tests and building releases automatically.

---

## Phase 14: Analytics & Launch Prep
**Goal:** Instrumented app ready for beta.

- [ ] **14.1** Firebase Analytics events:
  - `sign_up`, `login`, `space_created`, `space_joined`
  - `task_created`, `task_completed`, `board_viewed`
  - `weekly_plan_created`, `invite_sent`
- [ ] **14.2** Crash reporting: Firebase Crashlytics integration
- [ ] **14.3** Privacy: privacy policy page, data deletion flow
- [ ] **14.4** App Store / Play Store listing assets (screenshots, description)
- [ ] **14.5** Beta distribution via TestFlight + Firebase App Distribution

**Deliverable:** Instrumented, privacy-compliant app distributed to beta testers.

---

## Implementation Notes

- **Always build mobile-first**, then adapt for larger screens.
- **Real-time by default**: every list/board should use Firestore streams, not one-time fetches.
- **Optimistic UI**: update local state immediately on user actions, sync in background.
- **Warm language everywhere**: never show raw status strings — always map through display labels.
- **Test as you go**: write tests within each phase, not as an afterthought.
