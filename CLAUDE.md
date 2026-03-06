# CLAUDE.md — Lifeboard Technical Reference

> Primary context for Claude Code. Reference docs in `.claude/docs/` are loaded on demand.

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
| State Management | Riverpod 2.x                      |
| Routing          | GoRouter                          |
| CI/CD            | GitHub Actions + Fastlane         |

---

## Design Essentials

- **Colors:** Primary `#2F6264`, Light `#E2EAEB`, Background `#77B5B3`, Accent `#F5A623`, Error `#D94F4F`
- **Status accents:** todo=#2F6264, in_progress=#F5A623, done=#4CAF50 — use `AppColors.statusAccent()`
- **Fonts:** Nunito (headings, bold, 20–28sp) + Inter (body, 14–16sp)
- **Status labels:** "Backlog"→"Next Up", "Sprint"→"This Week", "Done"→"We did it! 🎉", "In Progress"→"Working on it" — use `StatusDisplayName.fromStatus()`
- **Style:** Rounded corners 12–16px, soft shadows, warm empty states with emoji, gradient bg (`#FAFCFC`→`#E2EAEB`), colored left accent bars on task cards

> Full design system, UX research, and color reference: `.claude/docs/design-system.md`

---

## Reference Files

Load these on demand — only when the task requires it:

| File | When to Load |
|------|-------------|
| `.claude/docs/design-system.md` | UI/UX work, theming, colors, typography, design decisions |
| `.claude/docs/data-models.md` | Firestore queries, schema changes, security rules, data layer |
| `.claude/docs/project-structure.md` | Finding files, understanding codebase layout, navigation |
| `.claude/docs/implementation-patterns.md` | Architecture questions, real-time sync, drag-drop, notifications, responsive layout |

---

## Commands

```bash
# Dev
flutter run                          # Default device
flutter run -d chrome                # Web
flutter run -d ios                   # iOS simulator

# Test
flutter test                         # All tests
flutter test --coverage              # With coverage

# Build
flutter build apk --release          # Android
flutter build ios --release          # iOS
flutter build web --release          # Web

# Firebase
firebase deploy --only firestore:rules
firebase deploy --only functions
flutterfire configure

# Code gen & quality
dart run build_runner build --delete-conflicting-outputs
flutter analyze
dart format lib/ test/
```

---

## Environment Setup

1. Flutter SDK ≥ 3.22 / Dart SDK ≥ 3.5
2. Firebase CLI + `flutterfire_cli`
3. `flutterfire configure` → generates `firebase_options.dart`
4. Xcode 15+ (iOS), Android Studio + SDK 34 (Android)
5. `.env` from `.env.example` (never commit secrets)
6. `flutter pub get`

---

## Conventions

- **Files:** `snake_case.dart` | **Classes:** `PascalCase` | **Providers:** `camelCaseProvider`
- **Commits:** Conventional — `feat:`, `fix:`, `chore:`, `docs:`, `refactor:`
- **Branches:** `feature/xyz`, `fix/xyz`, `chore/xyz`
- **No hardcoded strings** — all user-facing text in `lib/core/constants.dart` or l10n
- **Warm labels** — use `StatusDisplayName.fromStatus()` everywhere
- **Tests required** — services/providers need unit tests, screens need widget tests

---

## Sub-Agents

| Agent | File | When to Use |
|-------|------|-------------|
| iOS UI/UX Expert | `.claude/agents/ios-uiux-expert-agent.md` | Any UI/UX design, screen layout, design review, competitive analysis |
| Code Reviewer | `.claude/agents/code-reviewer.md` | PR reviews, architecture audits, code quality checks |
| Kanban PO | `.claude/agents/kanban-po.md` | Feature scoping, user stories, prioritization, agile process |

**Directives:**
- For ANY UI/UX design work, screen layout, or design review — ALWAYS spawn the iOS UI/UX Expert agent first. Read and follow `.claude/agents/ios-uiux-expert-agent.md`.
- For PR reviews or architecture audits — spawn the Code Reviewer agent.
- For feature scoping, user stories, or prioritization — spawn the Kanban PO agent.

---

## Subagent-First Rule

Delegate verbose/heavy operations to subagents to protect the main context window:

- Running `flutter test` or `flutter analyze` → subagent
- Reading/exploring 3+ files for research → Explore subagent
- Code review of changed files → Code Reviewer agent
- UI/UX design or competitive research → iOS UI/UX Expert agent
- Firebase log inspection or Firestore queries → subagent

**Only bring results back as a concise summary — never dump raw output into main context.**

---

## Session Management

- Use `/compact` to compress context when the session gets long
- Use `/clear` to reset context entirely for a fresh start
- Delegate research and exploration to subagents rather than loading many files into main context
- For multi-file refactors, use an Explore agent first to understand scope, then implement

---

## Compact Instructions

When auto-compaction runs, preserve: current task context, file paths being edited, errors/blockers, user preferences stated this session. Discard: raw file contents already processed, verbose tool outputs, intermediate search results, completed subtask details.
