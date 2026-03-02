# Lifeboard — Full Codebase Review

> Consolidated findings from reviewing every file in the project, ordered by severity.

---

## 🔴 Critical — Security & Data Integrity

### 1. Firestore Rules: Space reads too permissive
**File:** `firebase/firestore.rules:47`  
**Issue:** `allow read: if isAuthenticated()` lets **any** authenticated user read **every** space document (names, members, invite codes). This was likely added for invite-code lookup but leaks all space data.  
**Fix:** Restrict reads to space members, and add a separate Cloud Function or collection-group query for invite-code lookup that only returns the space ID.

### 2. Firestore Rules: Comment update/delete allows any member
**File:** `firebase/firestore.rules:84-85`  
**Issue:** Any space member can update or delete **any** comment, not just their own.  
**Fix:** Add `resource.data.authorId == request.auth.uid` check for update/delete on comments.

### 3. Fire-and-forget Firestore writes lose errors silently
**Files:**
- `lib/services/firestore_service.dart:72` — `createSpace()` calls `docRef.set()` without `await`
- `lib/services/firestore_service.dart:174` — `createBoard()` uses `unawaited()`
- `lib/services/firestore_service.dart:208` — `createTask()` uses `unawaited()`
- `lib/services/firestore_service.dart:304` — `addComment()` uses `unawaited()`

**Issue:** If any write fails (permission denied, network error), the client shows a locally-created object that never actually persists. The user sees a "created" space/task/comment that silently vanishes on next reload.  
**Fix:** `await` the write and let the caller handle errors. If you want optimistic UI, use Firestore's offline persistence and listen for write failures.

### 4. `deleteSpace()` orphans subcollections
**File:** `lib/services/firestore_service.dart:433`  
**Issue:** Deleting the space document leaves boards, tasks, comments, and activity subcollections as orphans. These are still readable/billable.  
**Fix:** Use a Cloud Function triggered on space deletion to recursively delete subcollections, or use the Firebase CLI `firestore:delete --recursive`.

### 5. `leaveSpace()` doesn't delete space when sole member leaves
**File:** `lib/services/firestore_service.dart:377-409`  
**Issue:** If the sole owner leaves, ownership is transferred — but if there are no other members, the space becomes an orphan with no members and no way to access/delete it.  
**Fix:** Add `if (otherMembers.isEmpty) { await deleteSpace(...); return; }` before the ownership transfer.

### 6. `deleteAccount()` may fail without re-authentication
**File:** `lib/providers/profile_provider.dart:261-272`  
**Issue:** `user.delete()` requires recent authentication. If the session is old, Firebase throws `requires-recent-login`. The code catches this as a generic error.  
**Fix:** Catch `FirebaseAuthException` with code `requires-recent-login` and prompt re-authentication before retrying.

---

## 🟠 High — Bugs & Correctness

### 7. Cloud Functions: Duplicate `sendFcmToSpaceMembers`
**Files:**
- `firebase/functions/src/activity.ts:83-185`
- `firebase/functions/src/notifications.ts:71-167`

**Issue:** Nearly identical 100-line function duplicated across files. Divergent bug fixes will happen.  
**Fix:** Extract to a shared `lib/fcm.ts` module and import from both.

### 8. Cloud Functions: `actorId` always uses `createdBy`
**File:** `firebase/functions/src/activity.ts:31`  
**Issue:** `const actorId = after.createdBy` — when someone other than the creator changes the status, the activity still attributes the action to the original creator.  
**Fix:** Use `after.updatedBy` if you add that field on client writes, or accept this as a known limitation and document it.

### 9. `getActivityForSpaces()` has quadratic subscription behavior
**File:** `lib/services/firestore_service.dart:525-543`  
**Issue:** Uses `asyncExpand` inside `fold`, creating cascading re-subscriptions. For N spaces, each event from space 1 triggers a full re-listen on spaces 2..N.  
**Note:** The `activity_provider.dart` already has a correct `StreamController`-based implementation. This `FirestoreService` method appears unused — confirm and remove, or replace with the correct pattern.

### 10. `activity_provider.dart` StreamController never closed
**File:** `lib/providers/activity_provider.dart:49-73`  
**Issue:** `_combineActivityStreams` creates a `StreamController` with `onCancel` to cancel subscriptions, but `controller.close()` is never called. Subscriptions are cleaned up on cancel, but the controller itself leaks.  
**Fix:** Call `controller.close()` inside `onCancel` after canceling subscriptions.

### 11. `ThemeModeNotifier` causes light-mode flash
**File:** `lib/providers/profile_provider.dart:12-13`  
**Issue:** Initializes with `ThemeMode.light`, then asynchronously loads from `SharedPreferences`. Dark-mode users see a brief flash of light theme on cold start.  
**Fix:** Either initialize with `ThemeMode.system` or load the preference synchronously before `runApp()`.

### 12. `splash_screen.dart` uses deprecated `withOpacity()`
**File:** `lib/screens/splash/splash_screen.dart:61`  
**Issue:** `Colors.white.withOpacity(0.85)` — the rest of the codebase uses `withValues(alpha:)`.  
**Fix:** Change to `Colors.white.withValues(alpha: 0.85)`.

### 13. `StorageService.maxFileSize` declared but never enforced
**File:** `lib/services/storage_service.dart:21`  
**Issue:** `static const int maxFileSize = 10 * 1024 * 1024` is defined but neither `uploadImage()` nor `uploadFile()` checks file size before uploading.  
**Fix:** Check `file.length()` / `file.size` before upload and throw a descriptive error.

### 14. Force-unwrap on `currentUser!` in ProfileActionNotifier
**File:** `lib/providers/profile_provider.dart` — lines 146, 163, 175, 195, 211, 226, 241, 264  
**Issue:** Every method uses `FirebaseAuth.instance.currentUser!`. If the user signs out concurrently (e.g., from another tab), this crashes.  
**Fix:** Guard with null check and early return, or use the `authServiceProvider` pattern.

---

## 🟡 Medium — Code Quality & Maintainability

### 15. Cross-cutting: `isDark ? AppColors.dark* : AppColors.*` pattern
Multiple files manually switch between light/dark color constants instead of using theming:

| File | Lines | Colors used |
|------|-------|-------------|
| `auth_screen.dart` | 239, 249, 274 | `darkDivider` / `divider` |
| `create_join_space_screen.dart` | 334 | `darkDivider` / `divider` |
| `invite_partner_screen.dart` | 150 | `darkDivider` / `divider` |
| `comments_section.dart` | 117, 271, 351, 424 | `darkDivider` / `divider` |
| `emoji_tag_picker.dart` | 39 | `darkDivider` / `divider` |
| `task_card.dart` | 40 | `darkCardShadow` / `cardShadow` |
| `compact_kanban_column.dart` | 88, 375 | `darkCardSurface`, `darkCardShadow` |
| `board_view_screen.dart` | 317-319, 496-498 | `darkGradientTop/Bottom` |
| `welcome_screen.dart` | 15 | `darkPrimaryContainer` / `background` |
| `splash_screen.dart` | 31 | `darkPrimaryContainer` / `background` |

**Fix:** Add a `ThemeExtension<AppColorsExtension>` to both light and dark `ThemeData` to expose `divider`, `cardShadow`, `gradientTop`, `gradientBottom`, `scaffold`, etc. Then access via `Theme.of(context).extension<AppColorsExtension>()!.divider`. This eliminates all `isDark` ternaries for colors.

### 16. `AppTextStyles` uses static fields without `const`
**File:** `lib/theme/app_text_styles.dart`  
**Issue:** All styles are `static TextStyle` (not `final` or `const`), and `GoogleFonts.*()` creates new instances on each access. These should be `static final` to avoid repeated allocation.  
**Fix:** Change `static TextStyle headingLarge = ...` to `static final TextStyle headingLarge = ...`.

### 17. `_ProfileCard` uses `dynamic` type
**File:** `lib/screens/profile/profile_settings_screen.dart:149`  
**Issue:** `final dynamic user;` — loses type safety. Should be `final UserModel? user;`.

### 18. `taskDetailProvider` bypasses service layer
**File:** `lib/screens/task/task_detail_screen.dart:27-37`  
**Issue:** Streams directly from `FirebaseFirestore.instance` instead of going through `FirestoreService`. Inconsistent with the rest of the codebase which uses the service layer.  
**Fix:** Add a `getTask(spaceId, taskId)` stream method to `FirestoreService` and use it here.

### 19. `NotificationService._saveToken()` has redundant web check
**File:** `lib/services/notification_service.dart:79-84`  
**Issue:** Both branches of `if (kIsWeb)` call `_messaging.getToken()` with identical code.  
**Fix:** Remove the `if/else` and just call `_messaging.getToken()` once.

### 20. `NotificationService.removeToken()` never called on sign-out
**Files:**
- `lib/providers/profile_provider.dart:255-258` — `signOut()` only calls `authService.signOut()`
- `lib/services/notification_service.dart:127-141` — `removeToken()` exists but unused

**Fix:** Call `notificationService.removeToken()` before `authService.signOut()`.

### 21. Board member names use userId as display name
**File:** `lib/screens/board/board_view_screen.dart:96-103`  
**Issue:** Comment says "In a real app, you'd fetch user docs." — member names map uses raw user IDs as names, so avatar initials show UID characters.  
**Fix:** Watch `userByIdProvider` for each member to get actual display names.

### 22. Large screen files need decomposition
- `lib/screens/task/task_detail_screen.dart` — **1450 lines**
- `lib/screens/profile/profile_settings_screen.dart` — **1191 lines**

**Fix:** Extract sub-widgets into separate files (e.g., `_SubtasksSection` → `widgets/subtasks_section.dart`).

### 23. Cloud Functions use `firebase-functions` v1 API (deprecated)
**File:** `firebase/functions/src/activity.ts:1`, `notifications.ts:1`  
**Issue:** `functions.firestore.document(...).onWrite(...)` is the v1 API. Firebase recommends migrating to v2 (`onDocumentWritten`).  
**Fix:** Migrate to `firebase-functions/v2/firestore` when ready.

### 24. Missing Firestore indexes for production queries
**File:** `firebase/firestore.indexes.json`  
**Issue:** Only 2 indexes defined. The `getSpacesForUser` query (`members.$userId.role whereIn ['owner', 'member']`) and `getCompletionWeeks` query (`status == 'done'` + `completedAt`) may need composite indexes in production.  
**Fix:** Deploy to emulator, run all queries, and capture the missing index URLs from error messages.

### 25. `getCompletedTaskCount()` and `getCompletionWeeks()` are sequential
**File:** `lib/services/firestore_service.dart:437-475`  
**Issue:** Iterates spaces sequentially with `for` loops and `await`. For 5 spaces, this makes 5 sequential network calls.  
**Fix:** Use `Future.wait()` to parallelize.

---

## 🔵 Low — Polish & Minor Issues

### 26. `Validators.validateEmail` regex is too loose
**File:** `lib/core/utils/validators.dart:8`  
**Issue:** `r'^[\w\-.+]+@[\w\-]+\.[\w\-]+$'` accepts emails like `a@b.c` and doesn't handle subdomains or long TLDs well.  
**Fix:** Use a more robust regex or the `email_validator` package.

### 27. `_CommentBubble` shows truncated userId for non-current users
**File:** `lib/widgets/comments_section.dart:249-252`  
**Issue:** `_shortName()` returns first 6 chars of a Firebase UID (e.g., "abc123") instead of the actual display name.  
**Fix:** Use `userByIdProvider` to resolve display names.

### 28. `StaggeredListItem` uses `AnimatedBuilder` correctly but `_slide` uses pixel offsets
**File:** `lib/widgets/stagger_animation.dart:55-61`  
**Issue:** `Offset(0, 20)` is in logical pixels used with `Transform.translate`, which is fine. No actual bug, but consider using `SlideTransition` with fractional offsets for density-independence.

### 29. Web VAPID key not configured
**File:** `lib/services/notification_service.dart:80-81`  
**Issue:** Comment says "Web requires a VAPID key — skip if not configured" but the code still calls `getToken()` without a VAPID key, which will fail on web.  
**Fix:** Pass the VAPID key via environment config or skip token registration on web until configured.

### 30. `createSpace()` generates invite codes without uniqueness check
**File:** `lib/services/firestore_service.dart:620-629`  
**Issue:** With 32^6 ≈ 1B possibilities collisions are rare but possible. No uniqueness check against existing codes.  
**Fix:** Accept the low probability or add a query-then-retry loop.

---

## Summary by Priority

| Severity | Count | Key themes |
|----------|-------|------------|
| 🔴 Critical | 6 | Security rules, silent write failures, data orphaning |
| 🟠 High | 8 | Duplicate code, incorrect attribution, memory leaks, crashes |
| 🟡 Medium | 11 | Theming inconsistency, missing DI, large files, deprecated APIs |
| 🔵 Low | 5 | Validation, display names, web support |

### Recommended Fix Order
1. **Security rules** (#1, #2) — deploy immediately
2. **Silent write failures** (#3) — await critical writes
3. **Orphan data** (#4, #5) — add Cloud Function for cleanup
4. **Theming refactor** (#15) — add `ThemeExtension` to eliminate `isDark` ternaries
5. **Cloud Functions dedup** (#7) — extract shared FCM module
6. **Everything else** — in priority order above
