# Lifeboard — Full Codebase Review

> Comprehensive findings from reviewing every file in the project (models, providers, services, screens, widgets, theme, Firebase rules, Cloud Functions), ordered by severity.

---

## 🔴 Critical — Security & Data Integrity

### 1. Firestore Rules: Space reads too permissive
**File:** `firebase/firestore.rules:47-54`
**Issue:** `allow read: if isAuthenticated()` lets **any** authenticated user read **every** space document (names, members, invite codes). The inline comment acknowledges this is needed for `joinSpace()` invite-code lookup but accepts the data leak.
**Fix:** Move invite-code lookup to a Cloud Function that accepts an invite code and returns only the space ID. Then restrict space reads to members only: `allow read: if isSpaceMember(spaceId)`.

### 2. Storage Rules: Task attachments readable/writable by any authenticated user
**File:** `firebase/storage.rules:4-6`
**Issue:** `match /spaces/{spaceId}/tasks/{taskId}/{allPaths=**}` allows any authenticated user to read and write task attachments in any space, bypassing space membership.
**Fix:** Verify space membership via a custom claim or Cloud Function-mediated upload. At minimum, use a Cloud Function to generate signed URLs scoped to space members.

### 3. Fire-and-forget Firestore writes lose errors silently
**Files:**
- `lib/services/firestore_service.dart` — `createSpace()`, `createBoard()`, `createTask()`, `addComment()` use `unawaited()` or omit `await`

**Issue:** If any write fails (permission denied, network error), the client shows a locally-created object that silently vanishes on next reload.
**Fix:** `await` the write and let the caller handle errors. If you want optimistic UI, use Firestore's offline persistence and listen for write failures.

### 4. `deleteSpace()` orphans subcollections
**File:** `lib/services/firestore_service.dart`
**Issue:** Deleting the space document leaves boards, tasks, comments, homepad_items, and activity subcollections as orphans. These are still readable and billable.
**Fix:** Use a Cloud Function triggered on space deletion to recursively delete subcollections, or use the Firebase CLI `firestore:delete --recursive`.

### 5. `leaveSpace()` doesn't handle sole-member scenario
**File:** `lib/services/firestore_service.dart`
**Issue:** If the sole owner leaves, ownership transfer logic runs but there are no other members. The space becomes an orphan with no members and no way to access/delete it.
**Fix:** Add `if (otherMembers.isEmpty) { await deleteSpace(...); return; }` before the ownership transfer.

### 6. `deleteAccount()` may fail without re-authentication
**File:** `lib/providers/profile_provider.dart`
**Issue:** `user.delete()` requires recent authentication. If the session is old, Firebase throws `requires-recent-login`. The code catches this as a generic error with a vague message.
**Fix:** Catch `FirebaseAuthException` with code `requires-recent-login` and prompt re-authentication before retrying.

---

## 🟠 High — Bugs & Correctness

### 7. Cloud Functions: `actorId` always uses `createdBy`
**File:** `firebase/functions/src/activity.ts:32`
**Issue:** `const actorId = after.createdBy` — when someone other than the creator changes the status, the activity still attributes the action to the original creator. Push notifications go to the wrong person.
**Fix:** Add an `updatedBy` field to task writes on the client side, and use `after.updatedBy || after.createdBy` in the Cloud Function.

### 8. `activity_provider.dart` StreamController never closed
**File:** `lib/providers/activity_provider.dart`
**Issue:** `_combineActivityStreams` creates a `StreamController` with `onCancel` to cancel subscriptions, but `controller.close()` is never called. The controller itself leaks.
**Fix:** Call `controller.close()` inside `onCancel` after canceling subscriptions.

### 9. `ThemeModeNotifier` causes light-mode flash on cold start
**File:** `lib/providers/profile_provider.dart`
**Issue:** Initializes with `ThemeMode.light`, then asynchronously loads from `SharedPreferences`. Dark-mode users see a brief flash of light theme.
**Fix:** Either initialize with `ThemeMode.system` or load the preference synchronously before `runApp()` (e.g., in `main()` using `WidgetsFlutterBinding.ensureInitialized()` + `await SharedPreferences.getInstance()`).

### 10. `StorageService.maxFileSize` declared but never enforced
**File:** `lib/services/storage_service.dart:21`
**Issue:** `static const int maxFileSize = 10 * 1024 * 1024` is defined but neither `uploadImage()` nor `uploadFile()` checks file size before uploading. Users can upload arbitrarily large files.
**Fix:** Check `file.length()` before upload and throw a descriptive error.

### 11. Force-unwrap on `currentUser!` in ProfileActionNotifier
**File:** `lib/providers/profile_provider.dart` — multiple methods
**Issue:** Every method uses `FirebaseAuth.instance.currentUser!`. If the user signs out concurrently (e.g., token expiry, another tab), this crashes with a null assertion error.
**Fix:** Guard with null check and early return.

### 12. `HomeDashboardScreen` redirect runs in `addPostFrameCallback` on every rebuild
**File:** `lib/screens/home/home_dashboard_screen.dart:37-53`
**Issue:** `WidgetsBinding.instance.addPostFrameCallback` is called inside `data:` callback of `spacesAsync.when()`. Every time spaces change, it re-triggers `SharedPreferences` read + `context.go()`. This can cause navigation thrashing.
**Fix:** Move the redirect logic to a one-shot effect (e.g., use a `ref.listen` in `initState` or a `Redirect` in `GoRouter` config).

### 13. `_DueDateChip` overdue check compares DateTime with time component
**File:** `lib/widgets/task_card.dart:245`
**Issue:** `date.isBefore(DateTime.now())` — if a task is due today but it's afternoon, it shows as overdue because `DateTime.now()` includes the current time.
**Fix:** Compare date-only: `date.isBefore(DateTime(now.year, now.month, now.day))`. The `_DueDateRow` in `task_detail_screen.dart` does this correctly already.

### 14. `_pickAndUploadPhoto` uses `FirebaseAuth.instance.currentUser!` directly
**File:** `lib/screens/profile/profile_settings_screen.dart:196-197`
**Issue:** Directly accesses `FirebaseAuth.instance` and `FirebaseStorage.instance` instead of using the service layer, bypassing any DI and making this untestable.
**Fix:** Use `ref.read(authServiceProvider)` and `ref.read(storageServiceProvider)`.

### 15. `NotificationService.removeToken()` never called on sign-out
**Files:**
- `lib/providers/profile_provider.dart` — `signOut()` only calls `authService.signOut()`
- `lib/services/notification_service.dart` — `removeToken()` exists but is unused

**Issue:** After sign-out, the FCM token remains in the user's Firestore doc. Push notifications continue to arrive for the signed-out user on that device.
**Fix:** Call `notificationService.removeToken()` before `authService.signOut()`.

---

## 🟡 Medium — Code Quality & Maintainability

### 16. `_PreferencesCard` and `_AccountActionsCard` use `dynamic` type for user
**File:** `lib/screens/profile/profile_settings_screen.dart:978, 1067`
**Issue:** `final dynamic user;` — loses type safety. Any typo in property access will be a runtime error instead of compile-time.
**Fix:** Use `final UserModel? user;`.

### 17. `taskDetailProvider` bypasses service layer
**File:** `lib/screens/task/task_detail_screen.dart`
**Issue:** Streams directly from `FirebaseFirestore.instance` instead of going through `FirestoreService`. Inconsistent with the rest of the codebase.
**Fix:** Add a `watchTask(spaceId, taskId)` stream method to `FirestoreService` and use it here.

### 18. `_CommentBubble` shows truncated userId for non-current users
**File:** `lib/widgets/comments_section.dart:249-252`
**Issue:** `_shortName()` returns first 6 chars of a Firebase UID (e.g., "abc123") instead of the actual display name. Users see meaningless strings.
**Fix:** Accept a `Map<String, String> memberNames` or use `userByIdProvider` to resolve display names.

### 19. Hardcoded colors in HomePad widgets bypass theme system
**Files:**
- `lib/widgets/homepad_category_section.dart` — uses `AppColors.primaryDark` directly
- `lib/widgets/homepad_item_card.dart` — uses `AppColors.primaryDark` directly
- `lib/screens/homepad/add_item_sheet.dart` — uses `AppColors.primaryDark` directly
- `lib/screens/homepad/add_custom_item_sheet.dart` — uses `AppColors.primaryDark` and `Colors.grey.shade300`

**Issue:** These widgets don't use `Theme.of(context).colorScheme` or the `AppColorsExtension`, so they won't adapt to dark mode correctly.
**Fix:** Replace all `AppColors.primaryDark` references with `colors.onSurface` or appropriate theme colors.

### 20. `AppTextStyles` uses non-final static fields
**File:** `lib/theme/app_text_styles.dart`
**Issue:** All styles are `static TextStyle` (not `final`), and `GoogleFonts.*()` creates new instances on each access.
**Fix:** Change to `static final TextStyle`.

### 21. Board member names use userId as display name fallback
**File:** `lib/screens/board/board_view_screen.dart`
**Issue:** Comment says "In a real app, you'd fetch user docs." — member names map uses raw user IDs as names, so avatar initials show UID characters.
**Fix:** Watch `userByIdProvider` for each member to resolve display names.

### 22. Large screen files need decomposition
- `lib/screens/task/task_detail_screen.dart` — **1749 lines**, 10+ private widget classes
- `lib/screens/profile/profile_settings_screen.dart` — **1828 lines**, 15+ private widget classes
- `lib/screens/homepad/homepad_screen.dart` — **830 lines**

**Fix:** Extract private widget classes into separate files under a `widgets/` subdirectory per feature.

### 23. Cloud Functions use `firebase-functions` v1 API
**Files:** `firebase/functions/src/activity.ts`, `notifications.ts`, `homepad_notifications.ts`
**Issue:** `functions.firestore.document(...).onWrite(...)` is the v1 API. Firebase recommends v2 (`onDocumentWritten` from `firebase-functions/v2/firestore`). v1 will eventually be deprecated.
**Fix:** Migrate to v2 API when ready. No urgency but plan for it.

### 24. Duplicate `admin.initializeApp()` guard in every Cloud Function file
**Files:** `activity.ts:5-7`, `notifications.ts:5-7`, `homepad_notifications.ts:5-7`, `fcm.ts:5-7`, `test-push-function.ts:5-7`, `test-push.ts:18-20`
**Issue:** `if (!admin.apps.length) { admin.initializeApp(); }` repeated 6 times. Also `const db = admin.firestore()` repeated in every file.
**Fix:** Create a shared `lib/admin.ts` that initializes once and exports `db`.

### 25. `getCompletedTaskCount()` and `getCompletionWeeks()` are sequential
**File:** `lib/services/firestore_service.dart`
**Issue:** Iterates spaces sequentially with `for` loops and `await`. For N spaces, this makes N sequential network calls.
**Fix:** Use `Future.wait()` to parallelize across spaces.

### 26. Missing Firestore indexes for production queries
**File:** `firebase/firestore.indexes.json`
**Issue:** Only 3 indexes defined. Queries like `getSpacesForUser` (members map + role) and `getCompletionWeeks` (status + completedAt) may need composite indexes.
**Fix:** Run all queries against the emulator and capture missing index URLs from error messages.

### 27. `NotificationService._saveToken()` has redundant web check
**File:** `lib/services/notification_service.dart`
**Issue:** Both branches of `if (kIsWeb)` call `_messaging.getToken()` with identical code.
**Fix:** Remove the `if/else` and just call `_messaging.getToken()` once.

### 28. `DropdownButtonFormField` uses `initialValue` instead of `value`
**Files:**
- `lib/screens/homepad/add_item_sheet.dart:397`
- `lib/screens/homepad/add_custom_item_sheet.dart:133`

**Issue:** `DropdownButtonFormField` has a `value` parameter, not `initialValue`. This may cause a compile warning or unexpected behavior depending on Flutter version.
**Fix:** Change `initialValue:` to `value:`.

---

## 🔵 Low — Polish & Minor Issues

### 29. `Validators.validateEmail` regex is too loose
**File:** `lib/core/utils/validators.dart`
**Issue:** `r'^[\w\-.+]+@[\w\-]+\.[\w\-]+$'` accepts emails like `a@b.c` and doesn't handle subdomains.
**Fix:** Use the `email_validator` package or a more robust regex.

### 30. `splash_screen.dart` text color may be invisible on light scaffold
**File:** `lib/screens/splash/splash_screen.dart:49`
**Issue:** Uses `Colors.white` for text, but `ext.scaffold` background color depends on the theme. If the scaffold color is light, white text won't be visible.
**Fix:** Use a color that contrasts with the scaffold background, or ensure the splash always uses a dark background.

### 31. `createSpace()` generates invite codes without uniqueness check
**File:** `lib/services/firestore_service.dart`
**Issue:** With 32^6 ≈ 1B possibilities collisions are rare but possible. No uniqueness check against existing codes.
**Fix:** Accept the low probability or add a query-then-retry loop.

### 32. Web VAPID key not configured
**File:** `lib/services/notification_service.dart`
**Issue:** Comment says "Web requires a VAPID key" but the code still calls `getToken()` without one, which will fail on web.
**Fix:** Pass the VAPID key via environment config or skip token registration on web.

### 33. `StaggeredListItem` uses `AnimatedBuilder` (non-standard name)
**File:** `lib/widgets/stagger_animation.dart:78`
**Issue:** Uses `AnimatedBuilder` — this is actually a valid Flutter widget but is less commonly used than `AnimatedWidget`. The implementation works correctly.
**Note:** No fix needed, but consider using `SlideTransition` + `FadeTransition` for a more conventional approach.

### 34. `_WeeklyTaskCard._statusColor` hardcodes colors instead of using `AppColors.statusAccent()`
**File:** `lib/screens/weekly/weekly_view_screen.dart:587-596`
**Issue:** The `done` color is `Color(0xFF4CAF50)` hardcoded, while the rest of the app uses `AppColors.statusDone`.
**Fix:** Use `AppColors.statusAccent(status)` for consistency.

### 35. `flushHomePadNotifications` mutates `items` array during message construction
**File:** `firebase/functions/src/homepad_notifications.ts:155-156`
**Issue:** `const last = items.pop()!` mutates the original array. If any subsequent code uses `items`, it will be missing the last element. Currently safe but fragile.
**Fix:** Use `items[items.length - 1]` and `items.slice(0, -1).join(", ")` instead.

---

## ✅ Strengths

The codebase has several notable positives:

- **Consistent architecture**: Clean separation of models → services → providers → screens, with Riverpod used consistently throughout.
- **Freezed + json_serializable**: Models use code generation for immutability and serialization, reducing boilerplate and bugs.
- **Responsive design**: `ResponsiveShell` with mobile/tablet/desktop layouts via `LayoutBuilder` is well-implemented.
- **Theme system**: `AppColorsExtension` via `ThemeExtension` is a solid pattern (though not yet used everywhere — see #19).
- **Accessibility**: Good use of `Semantics` widgets on interactive elements across task cards, emoji pickers, and assignee chips.
- **Haptic feedback**: Thoughtful use of `HapticFeedback` for micro-interactions (drag, complete, toggle).
- **Cloud Function design**: The HomePad notification batching/debounce strategy (pending docs + scheduled flush) is well-architected.
- **FCM token cleanup**: `fcm.ts` properly removes invalid tokens after failed sends — this prevents token rot.
- **Firestore rules**: Subcollection rules correctly use `get()` to verify parent space membership. Comment-level author checks for update/delete are correct.
- **Onboarding flow**: Clean Welcome → Auth → Create/Join Space → Invite Partner flow with proper error handling and custom exceptions (`SpaceNotFoundException`, `AlreadyMemberException`).
- **Celebration overlay**: Nice UX touch with Lottie confetti animation + haptic feedback on task completion.

---

## Summary by Priority

| Severity | Count | Key themes |
|----------|-------|------------|
| 🔴 Critical | 6 | Security rules, storage rules, silent write failures, data orphaning |
| 🟠 High | 9 | Incorrect attribution, memory leaks, crashes, navigation bugs |
| 🟡 Medium | 13 | Theme inconsistency, type safety, large files, deprecated APIs |
| 🔵 Low | 7 | Validation, color consistency, web support |

**Total issues: 35**

### Recommended Fix Order
1. **Security rules** (#1, #2) — deploy immediately
2. **Silent write failures** (#3) — await critical writes
3. **Orphan data** (#4, #5) — add Cloud Function for cleanup
4. **Actor attribution** (#7) — add `updatedBy` field
5. **HomePad theme colors** (#19) — dark mode broken for HomePad features
6. **Type safety** (#16) — change `dynamic` to `UserModel?`
7. **Navigation fix** (#12) — prevent redirect thrashing
8. **Token cleanup on sign-out** (#15) — prevent ghost notifications
9. **Cloud Functions refactor** (#24) — shared admin init
10. **File decomposition** (#22) — improve maintainability
11. **Everything else** — in priority order above
