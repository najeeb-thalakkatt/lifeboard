# CLAUDE.md — Lifeboard Technical Reference

> Primary context for Claude Code. Reference docs in `.claude/docs/` are loaded on demand.

## Project Overview

**Lifeboard** — shared life backlog app for couples, parents, and small groups. Agile-inspired structure for everyday life. "Plan life together, simply."

## Tech Stack

| Layer | Technology |
|-------|------------|
| Frontend | Flutter 3.22+ (iOS + Android + Web) |
| Backend | Firebase (Auth, Firestore, Storage, FCM, Functions) |
| State | Riverpod 2.x (StreamProvider + StateNotifier) |
| Routing | GoRouter 17.x |
| Models | Freezed 3.x + JSON Serializable |
| CI/CD | GitHub Actions + Fastlane |

---

## Directory Structure

```
lib/
├── main.dart                    # Firebase init, auth listener, quick actions
├── app.dart                     # GoRouter config, MaterialApp, theme
├── firebase_options.dart        # Auto-generated (never edit)
├── core/
│   ├── constants.dart           # StatusDisplayName, emoji tags, labels
│   ├── errors/app_exceptions.dart
│   └── utils/validators.dart
├── models/                      # 9 freezed models + generated files
├── providers/                   # 14 providers (streams + notifiers)
├── services/                    # 7 services (Firestore, auth, FCM, etc.)
├── screens/                     # 11 feature folders (board, chores, etc.)
├── widgets/                     # 13 reusable widgets
└── theme/                       # AppColors, AppTextStyles, AppTheme
```

> Full file listing: `.claude/file-index.md` | Widget details: `.claude/widgets.md`

---

## Design Essentials

- **Colors:** Primary `#2F6264`, Accent `#F5A623`, Error `#D94F4F` — use `AppColors.statusAccent()`
- **Fonts:** Nunito (headings) + Inter (body) — use `AppTextStyles.*`
- **Status labels:** "Next Up", "Working on it", "We did it!" — use `StatusDisplayName.fromStatus()`
- **Style:** 12-16px corners, soft shadows, emoji empty states, colored accent bars

> Full design system: `.claude/docs/design-system.md`

---

## Key Packages

| Package | Version | Role |
|---------|---------|------|
| `flutter_riverpod` | ^2.6.1 | State management — StreamProvider (reads) + StateNotifier (writes) |
| `go_router` | ^17.1.0 | Declarative routing with auth redirects |
| `freezed` | ^3.1.0 | Immutable models with code gen |
| `cloud_firestore` | ^6.1.2 | Real-time database with offline persistence |
| `firebase_messaging` | ^16.1.1 | Push notifications |
| `local_auth` | ^2.3.0 | Biometric lock screen |
| `lottie` | ^3.3.2 | Celebration animations |

---

## Code Generation (Freezed)

All models use freezed + JSON serializable. After modifying any `*_model.dart`:

```bash
dart run build_runner build --delete-conflicting-outputs
```

- **Never edit** `*.freezed.dart` or `*.g.dart` files
- Models include `fromFirestore()` factory — handles `Timestamp` → `DateTime` conversion
- Nested models (Subtask, Attachment, SpaceMember) are also freezed

---

## Platform Notes

| Platform | Notes |
|----------|-------|
| iOS | Min deployment 15.0 (Firebase SDK requirement). Bundle ID: `com.codehive.lifeboard`. Run `pod repo update` if pods fail. |
| Android | SDK 34. Debug signing only — needs release keystore before production. JVM: 8GB heap. |
| Web | Standard Flutter web. PWA manifest in `web/`. |
| macOS | Supported but secondary. |

---

## Commands

```bash
# Dev
flutter run                          # Default device
flutter run -d chrome                # Web
flutter run -d ios                   # iOS simulator

# Test & Quality
flutter test                         # All tests
flutter test --coverage              # With coverage
flutter analyze                      # Static analysis
dart format lib/ test/               # Formatting

# Build
flutter build apk --release          # Android APK
flutter build ios --release          # iOS
flutter build web --release          # Web

# Firebase
firebase deploy --only firestore --project lifeboard-8cd26
firebase deploy --only functions
flutterfire configure

# Code gen
dart run build_runner build --delete-conflicting-outputs
```

---

## Gotchas

1. **Timestamp handling** — Firestore returns `Timestamp`, not `DateTime`. All `fromFirestore()` factories cast: `(data['field'] as Timestamp?)?.toDate()`
2. **Assignee avatar bug** — `board_view_screen.dart:84-90` shows UID initials instead of real names. Needs user doc lookup.
3. **Pod resolution** — If iOS pods fail: `cd ios && pod install --repo-update`
4. **Auth guard** — All StreamProviders must watch `authStateProvider` and return `Stream.empty()` when null
5. **Generated files** — Don't forget to run build_runner after model changes. Stale generated files cause confusing type errors.

---

## Conventions

- **Files:** `snake_case.dart` | **Classes:** `PascalCase` | **Providers:** `camelCaseProvider`
- **Commits:** `feat:`, `fix:`, `chore:`, `docs:`, `refactor:`
- **Branches:** `feature/xyz`, `fix/xyz`, `chore/xyz`
- **No hardcoded strings** — use `lib/core/constants.dart` or l10n
- **Warm labels** — always use `StatusDisplayName.fromStatus()`
- **Tests required** — services/providers need unit tests, screens need widget tests
- **Imports:** Always `package:lifeboard/...` (enforced by lint)

---

## Reference Files

Load on demand — only when the task requires it:

| File | When to Load |
|------|-------------|
| `.claude/docs/design-system.md` | UI/UX work, theming, colors, typography |
| `.claude/docs/data-models.md` | Firestore queries, schema, security rules |
| `.claude/docs/project-structure.md` | Codebase layout, navigation |
| `.claude/docs/implementation-patterns.md` | Architecture, real-time sync, drag-drop |
| `.claude/file-index.md` | Finding specific files, understanding structure |
| `.claude/widgets.md` | Reusable widget registry with constructor params |
| `.claude/patterns/*.dart` | Code patterns: model, state, API, navigation, theme, tests |

---

## Slash Commands

| Command | Purpose |
|---------|---------|
| `/project:init` | Session kickstart — read context, check health |
| `/project:status` | Analyze + test + outdated deps check |
| `/project:build-runner` | Regenerate freezed models |
| `/project:add-feature` | Scaffold model + provider + screen + route + test |
| `/project:add-model` | Create freezed model + run build_runner |
| `/project:add-screen` | Scaffold screen + register route |
| `/project:debug` | Debug checklist (analyze, pub get, clean, platform) |
| `/project:test` | Run tests for specific feature/file |
| `/project:release` | Build release for platform |
| `/project:context` | Dump minimal context for new session |

---

## Sub-Agents

| Agent | File | When to Use |
|-------|------|-------------|
| iOS UI/UX Expert | `.claude/agents/ios-uiux-expert-agent.md` | UI/UX design, screen layout, design review |
| Code Reviewer | `.claude/agents/code-reviewer.md` | PR reviews, architecture audits |
| Kanban PO | `.claude/agents/kanban-po.md` | Feature scoping, user stories, prioritization |

**Directives:**
- UI/UX design work → spawn iOS UI/UX Expert agent first
- PR reviews / architecture audits → spawn Code Reviewer agent
- Feature scoping / prioritization → spawn Kanban PO agent

---

## Subagent-First Rule

Delegate verbose operations to subagents to protect main context:

- `flutter test` / `flutter analyze` → subagent
- Reading 3+ files for research → Explore subagent
- Code review → Code Reviewer agent
- UI/UX design → iOS UI/UX Expert agent

**Only bring results back as concise summary.**

---

## Session Management

- `/compact` to compress context | `/clear` to reset
- Delegate research to subagents instead of loading files into main context
- Multi-file refactors: Explore agent first, then implement

## Compact Instructions

Preserve: current task, file paths, errors/blockers, user preferences. Discard: raw file contents, verbose tool output, search results, completed subtasks.
