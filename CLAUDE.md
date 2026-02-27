# CLAUDE.md — Lifeboard Technical Reference

> This file is the primary technical context for Claude Code when working on the Lifeboard project.

---

## Project Overview

**Lifeboard** is a shared life backlog app for couples, parents, and small groups. It brings agile-inspired structure to everyday life — without the corporate feel. Think "a calm Jira with heart."

**Tagline:** "Plan life together, simply."

---

## Tech Stack

| Layer            | Technology                        |
|------------------|-----------------------------------|
| Frontend         | Flutter (iOS + Android + Web)     |
| Backend          | Firebase                          |
| Auth             | Firebase Auth (Email, Google, Apple Sign-In) |
| Database         | Cloud Firestore (real-time sync)  |
| Storage          | Firebase Storage (attachments, photos) |
| Notifications    | Firebase Cloud Messaging (FCM)    |
| Analytics        | Firebase Analytics                |
| State Management | Riverpod 2.x                      |
| Routing          | GoRouter                          |
| CI/CD            | GitHub Actions + Fastlane         |

---

## Brand & Design System

### Color Palette

| Role              | Hex       | Usage                                      |
|-------------------|-----------|---------------------------------------------|
| Primary Dark      | `#2F6264` | Icons, text, buttons, headers               |
| Primary Light     | `#E2EAEB` | Icon backgrounds, card surfaces, subtle fills |
| Background        | `#77B5B3` | App background, splash screen, logo bg      |
| Surface/White     | `#FFFFFF` | Cards, modals, input fields                 |
| Accent Warm       | `#F5A623` | Celebrations, streaks, badges               |
| Error             | `#D94F4F` | Validation errors, destructive actions      |
| Text Primary      | `#2F6264` | Headings, body text on light surfaces       |
| Text Secondary    | `#E2EAEB` | Text on dark/teal backgrounds, muted labels |

### Typography

- Google Fonts: **Nunito** (headings — warm, rounded) + **Inter** (body — clean, readable)
- Headings: Nunito Bold, 20–28sp
- Body: Inter Regular, 14–16sp
- Captions: Inter Regular, 12sp

### Design Language

- **Warm, not corporate.** Rounded corners (12–16px), soft shadows (elevation 2–4), pastel accents.
- **Emotionally smart labels.** All status/section names go through a display label mapper:
  - "Backlog" → "Next Up"
  - "Sprint" → "This Week"
  - "Done" → "We did it! 🎉"
  - "In Progress" → "Working on it"
- **Mobile-first kanban.** 3-column vertical scroll layout on phones. Horizontal scroll on tablet/desktop.
- **Celebration built in.** Confetti/Lottie animation + haptic on task completion.
- **Accessibility.** Min contrast 4.5:1, dynamic type support, semantic labels on all interactive elements.

### UX Research Outcomes (Feb 2026)

Competitive audit of Todoist, Any.do, Apple Reminders, Notion, Things 3, and Structured — plus iOS 26 design trend analysis — identified the following issues and solutions, now implemented:

**Key Problems Found:**
- Flat `#E2EAEB` background made white cards nearly invisible (low contrast)
- Space cards showed zero task info — users had to tap in to see anything
- Custom pill tab indicators on kanban felt non-native
- Task cards had no visual status indication
- Empty states lacked warmth and personality

**Patterns Adopted (Implemented):**
- **Gradient background** (`#FAFCFC` → `#E2EAEB`) for card-vs-background depth (from Todoist/Things 3)
- **Colored left accent bars** on task cards (4px, status-colored: teal=todo, orange=in-progress, green=done)
- **`CupertinoSlidingSegmentedControl`** replacing custom pill tabs on kanban (iOS-native feel)
- **Swipe-to-complete** via `Dismissible` on non-done task cards (green check, endToStart)
- **Glanceable dashboard** — space cards show task counts, mini progress bar, rotating accent colors
- **Warm empty states** with emoji and encouraging copy ("Ready to plan together?", "What needs to happen?")
- **Stagger animations** (slide-up + fade-in) for list item entrance

**Extended Color System:**
- Status accents: `statusTodo` (#2F6264), `statusInProgress` (#F5A623), `statusDone` (#4CAF50)
- 5 rotating `spaceAccents` for dashboard card variety
- `AppColors.statusAccent(String status)` helper for consistent status coloring

**New Files Created:**
- `lib/providers/dashboard_provider.dart` — `spaceTaskSummaryProvider` (streams per-space task counts)
- `lib/widgets/stagger_animation.dart` — reusable `StaggeredListItem` widget

### Logo

- Kayaker-on-waves motif → `/assets/images/logo.png`
- Splash/onboarding background: `#77B5B3`
- App icon uses the kayaker mark on teal background.

---

## Project Structure

```
lifeboard/
├── lib/
│   ├── main.dart
│   ├── app.dart                      # MaterialApp, ProviderScope, GoRouter
│   ├── theme/
│   │   ├── app_colors.dart           # All color constants
│   │   ├── app_theme.dart            # ThemeData (light + dark)
│   │   └── app_text_styles.dart      # Text style definitions
│   ├── core/
│   │   ├── constants.dart            # App-wide constants, label maps
│   │   ├── extensions/               # Dart extensions (DateTime, String, etc.)
│   │   ├── utils/                    # Helpers (date formatting, validators)
│   │   └── errors/                   # Custom exceptions, error handling
│   ├── models/                       # Data classes (freezed or manual)
│   │   ├── user_model.dart
│   │   ├── space_model.dart
│   │   ├── board_model.dart
│   │   ├── task_model.dart
│   │   ├── comment_model.dart
│   │   └── activity_model.dart
│   ├── providers/                    # Riverpod providers
│   │   ├── auth_provider.dart
│   │   ├── space_provider.dart
│   │   ├── board_provider.dart
│   │   ├── task_provider.dart
│   │   └── notification_provider.dart
│   ├── services/                     # Firebase service wrappers
│   │   ├── auth_service.dart
│   │   ├── firestore_service.dart
│   │   ├── storage_service.dart
│   │   ├── notification_service.dart
│   │   └── analytics_service.dart
│   ├── screens/
│   │   ├── onboarding/
│   │   │   ├── welcome_screen.dart
│   │   │   ├── create_join_space_screen.dart
│   │   │   └── invite_partner_screen.dart
│   │   ├── home/
│   │   │   └── home_dashboard_screen.dart
│   │   ├── board/
│   │   │   ├── board_view_screen.dart
│   │   │   └── kanban_column.dart
│   │   ├── task/
│   │   │   └── task_detail_screen.dart
│   │   ├── weekly/
│   │   │   └── weekly_view_screen.dart
│   │   ├── activity/
│   │   │   └── activity_feed_screen.dart
│   │   └── profile/
│   │       └── profile_settings_screen.dart
│   └── widgets/                      # Shared/reusable widgets
│       ├── task_card.dart
│       ├── emoji_tag_picker.dart
│       ├── celebration_overlay.dart
│       ├── avatar_widget.dart
│       ├── bottom_nav_bar.dart
│       └── shared_app_bar.dart
├── assets/
│   ├── images/                       # Logo, onboarding illustrations
│   ├── animations/                   # Lottie JSON files (confetti, etc.)
│   └── fonts/                        # Nunito, Inter font files
├── test/
│   ├── unit/
│   ├── widget/
│   └── integration/
├── firebase/
│   ├── firestore.rules
│   ├── firestore.indexes.json
│   └── functions/                    # Cloud Functions (JS/TS)
│       ├── src/
│       │   ├── notifications.ts      # FCM triggers
│       │   └── activity.ts           # Activity feed writer
│       └── package.json
├── pubspec.yaml
├── analysis_options.yaml
├── CLAUDE.md
├── plan.md
└── features.md
```

---

## Data Models (Firestore)

### `users/{userId}`
```
displayName: string
email: string
photoUrl: string?
moodEmoji: string?
spaceIds: string[]
notificationPrefs: { pushEnabled: bool, emailEnabled: bool }
createdAt: timestamp
```

### `spaces/{spaceId}`
```
name: string (default: "Our Home")
members: map<userId, { role: 'owner' | 'member', joinedAt: timestamp }>
inviteCode: string (6-char alphanumeric, unique)
themes: string[] (e.g., ["Home", "Kids", "Finances"])
createdAt: timestamp
```

### `spaces/{spaceId}/boards/{boardId}`
```
name: string
theme: string
columns: ["To Do", "In Progress", "Done"]
createdBy: userId
createdAt: timestamp
```

### `spaces/{spaceId}/tasks/{taskId}`
```
title: string
description: string?
status: 'todo' | 'in_progress' | 'done'
boardId: string
assignees: string[] (userIds)
dueDate: timestamp?
emojiTag: string? (💰🏡❤️🧠💪☀️)
subtasks: [{ id: string, title: string, completed: bool }]
attachments: [{ url: string, type: string, name: string }]
isWeeklyTask: bool
weekStart: timestamp?
order: int
completedAt: timestamp?
createdBy: userId
createdAt: timestamp
updatedAt: timestamp
```

### `spaces/{spaceId}/tasks/{taskId}/comments/{commentId}`
```
text: string
authorId: userId
reactions: map<emoji, userId[]>
createdAt: timestamp
```

### `spaces/{spaceId}/activity/{activityId}`
```
type: 'task_moved' | 'task_created' | 'task_completed' | 'comment_added' | 'member_joined'
actorId: userId
taskId: string?
message: string
createdAt: timestamp
```

---

## Firestore Security Rules (Summary)

- Users read/write only spaces where they are a member.
- Tasks scoped to spaces — only members can CRUD.
- Users can only update their own `users/{userId}` doc.
- `inviteCode` field on spaces is readable by any authenticated user (for join flow).
- Activity collection: read by members, write only via Cloud Functions (admin SDK).

---

## Key Implementation Patterns

### Real-Time Sync
- Wrap all Firestore `snapshots()` in Riverpod `StreamProvider`.
- Board view: stream tasks filtered by `boardId`, ordered by `order`.
- Home dashboard: stream spaces by `spaceIds` on user doc.

### Drag & Drop (Kanban)
- Use `LongPressDraggable` + `DragTarget` widgets per column.
- Optimistic update: change local state instantly, batch-write to Firestore.
- Reorder within column: update `order` field on affected tasks.
- Move across columns: update `status` + `order`.

### Celebrations
- On status change to `done` → Lottie confetti overlay (2s duration).
- Haptic feedback via `HapticFeedback.mediumImpact()` on mobile.
- Activity feed entry created via Cloud Function trigger.

### Weekly View Logic
- Tasks with `isWeeklyTask: true` and `weekStart` matching Monday of current week.
- "Next Up" auto-populated: tasks with `dueDate` within 7 days, not yet in weekly plan.
- "Plan Week" action: opens a picker to select tasks from backlog into weekly view.

### Notifications
- Cloud Function `onWrite` trigger on `tasks` and `comments` collections.
- Sends FCM push to all space members except the actor.
- Respects per-user `notificationPrefs`.

### Responsive Breakpoints
| Breakpoint  | Layout                                    | Nav             |
|-------------|-------------------------------------------|-----------------|
| < 600px     | Single column, stacked kanban             | Bottom nav bar  |
| 600–1024px  | Side-by-side columns, 2-col grid          | Navigation rail |
| > 1024px    | Full kanban board, sidebar + content area | Side drawer     |

### Platform Notes
- **iOS:** Request notification perms after onboarding. Universal links for invite deep links.
- **Android:** Notification channels configured in `AndroidManifest.xml`. App links for invites.
- **Web:** Firebase service worker for push. PWA manifest. Responsive CSS via Flutter's `LayoutBuilder`.

---

## Commands

```bash
# Development
flutter run                                    # Default device
flutter run -d chrome                          # Web
flutter run -d ios                             # iOS simulator
flutter run -d android                         # Android emulator

# Testing
flutter test                                   # All tests
flutter test --coverage                        # With coverage
flutter test test/unit/                        # Unit only
flutter test test/widget/                      # Widget only

# Build
flutter build apk --release                   # Android APK
flutter build appbundle --release              # Android AAB (Play Store)
flutter build ios --release                    # iOS
flutter build web --release                    # Web

# Firebase
firebase deploy --only firestore:rules         # Security rules
firebase deploy --only functions               # Cloud Functions
flutterfire configure                          # Reconfigure platforms

# Code generation
dart run build_runner build --delete-conflicting-outputs

# Quality
flutter analyze                                # Static analysis
dart format lib/ test/                         # Format code
```

---

## Environment Setup

1. Flutter SDK ≥ 3.22 / Dart SDK ≥ 3.5
2. Firebase CLI (`npm install -g firebase-tools`) + `flutterfire_cli`
3. Run `flutterfire configure` to generate `firebase_options.dart`
4. Xcode 15+ for iOS; Android Studio + SDK 34 for Android
5. Create `.env` from `.env.example` (never commit secrets)
6. `flutter pub get` to install dependencies

---

## Conventions

- **Files:** `snake_case.dart`
- **Classes:** `PascalCase`
- **Providers:** `camelCaseProvider` (e.g., `taskListProvider`)
- **Commits:** Conventional commits — `feat:`, `fix:`, `chore:`, `docs:`, `refactor:`
- **Branches:** `feature/xyz`, `fix/xyz`, `chore/xyz`
- **No hardcoded strings:** All user-facing text in `lib/core/constants.dart` or l10n files.
- **Warm language mapping:** Use `StatusDisplayName.fromStatus()` helper everywhere.
- **Tests required:** Every service and provider must have unit tests. Screens need widget tests.

## Sub-Agents

When doing iOS UI/UX work, read and follow the instructions in `.claude/ios-uiux-expert-agent.md`
```