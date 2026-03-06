# Lifeboard — Implementation Patterns

> Reference file for architecture and implementation details. Loaded on demand from CLAUDE.md.

---

## Real-Time Sync
- Wrap all Firestore `snapshots()` in Riverpod `StreamProvider`.
- Board view: stream tasks filtered by `boardId`, ordered by `order`.
- Home dashboard: stream spaces by `spaceIds` on user doc.

## Drag & Drop (Kanban)
- Use `LongPressDraggable` + `DragTarget` widgets per column.
- Optimistic update: change local state instantly, batch-write to Firestore.
- Reorder within column: update `order` field on affected tasks.
- Move across columns: update `status` + `order`.

## Celebrations
- On status change to `done` → Lottie confetti overlay (2s duration).
- Haptic feedback via `HapticFeedback.mediumImpact()` on mobile.
- Activity feed entry created via Cloud Function trigger.

## Weekly View Logic
- Tasks with `isWeeklyTask: true` and `weekStart` matching Monday of current week.
- "Next Up" auto-populated: tasks with `dueDate` within 7 days, not yet in weekly plan.
- "Plan Week" action: opens a picker to select tasks from backlog into weekly view.

## Notifications
- Cloud Function `onWrite` trigger on `tasks` and `comments` collections.
- Sends FCM push to all space members except the actor.
- Respects per-user `notificationPrefs`.

## Responsive Breakpoints

| Breakpoint  | Layout                                    | Nav             |
|-------------|-------------------------------------------|-----------------|
| < 600px     | Single column, stacked kanban             | Bottom nav bar  |
| 600–1024px  | Side-by-side columns, 2-col grid          | Navigation rail |
| > 1024px    | Full kanban board, sidebar + content area | Side drawer     |

## Platform Notes
- **iOS:** Request notification perms after onboarding. Universal links for invite deep links.
- **Android:** Notification channels configured in `AndroidManifest.xml`. App links for invites.
- **Web:** Firebase service worker for push. PWA manifest. Responsive CSS via Flutter's `LayoutBuilder`.
