# Lifeboard — Brand & Design System

> Reference file for design-related tasks. Loaded on demand from CLAUDE.md.

---

## Color Palette

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

## Typography

- Google Fonts: **Nunito** (headings — warm, rounded) + **Inter** (body — clean, readable)
- Headings: Nunito Bold, 20–28sp
- Body: Inter Regular, 14–16sp
- Captions: Inter Regular, 12sp

## Design Language

- **Warm, not corporate.** Rounded corners (12–16px), soft shadows (elevation 2–4), pastel accents.
- **Emotionally smart labels.** All status/section names go through a display label mapper:
  - "Backlog" → "Next Up"
  - "Sprint" → "This Week"
  - "Done" → "We did it! 🎉"
  - "In Progress" → "Working on it"
- **Mobile-first kanban.** 3-column vertical scroll layout on phones. Horizontal scroll on tablet/desktop.
- **Celebration built in.** Confetti/Lottie animation + haptic on task completion.
- **Accessibility.** Min contrast 4.5:1, dynamic type support, semantic labels on all interactive elements.

## UX Research Outcomes (Feb 2026)

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

## Extended Color System

- Status accents: `statusTodo` (#2F6264), `statusInProgress` (#F5A623), `statusDone` (#4CAF50)
- 5 rotating `spaceAccents` for dashboard card variety
- `AppColors.statusAccent(String status)` helper for consistent status coloring

**New Files Created:**
- `lib/providers/dashboard_provider.dart` — `spaceTaskSummaryProvider` (streams per-space task counts)
- `lib/widgets/stagger_animation.dart` — reusable `StaggeredListItem` widget

## Logo

- Kayaker-on-waves motif → `/assets/images/logo.png`
- Splash/onboarding background: `#77B5B3`
- App icon uses the kayaker mark on teal background.
