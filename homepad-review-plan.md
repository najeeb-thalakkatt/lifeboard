# HomePad Review — Implementation Tracker

> Tracks the expert review fixes. Based on iOS UI/UX Expert + Kanban PO feedback.
> **Overall Verdict: Ship it** — with targeted fixes.

---

## P0 — Must Fix Before Ship

### 1. Accessibility: VoiceOver labels ✅ DONE
- **Files:** `lib/widgets/homepad_item_card.dart`, `lib/screens/homepad/homepad_screen.dart`
- Added `Semantics` to item cards (label: name/category/status, hint: swipe action)
- Added `Semantics` to checkbox button, filter chips (with selected state), and "All Done!" button

### 2. Accessibility: Reduce Motion support ✅ DONE
- **Files:** `lib/widgets/stagger_animation.dart`, `lib/screens/homepad/homepad_screen.dart`, `lib/widgets/homepad_category_section.dart`
- `StaggeredListItem` skips animation when `MediaQuery.disableAnimations` is true
- `HomePadCategorySection` uses instant show/hide instead of `AnimatedCrossFade`
- Recently Bought chevron uses `Duration.zero` for reduced motion

### 3. Notification preferences not enforced ✅ ALREADY DONE
- **File:** `firebase/functions/src/fcm.ts` (lines 50-51)
- `sendFcmToSpaceMembers` already checks `homePadUpdates` and `homePadComplete` user prefs
- No fix needed — was incorrectly flagged in review

---

## P1 — Should Fix (Meaningful UX Improvements)

### 4. Search bar pinned ✅ DONE
- **File:** `lib/screens/homepad/homepad_screen.dart`
- Replaced `SliverToBoxAdapter` with `SliverPersistentHeader(pinned: true)`
- Added `_PinnedSearchBarDelegate` (112px height, elevation on overlap)

### 5. To Buy items grouped by category ✅ DONE
- **File:** `lib/screens/homepad/homepad_screen.dart`
- Added `_buildCategoryGroupedToBuy()` helper
- Items grouped by category with uppercase sub-headers

### 6. Recently Bought grouped by date ✅ DONE
- **File:** `lib/screens/homepad/homepad_screen.dart`
- Added `_buildDateGroupedPurchased()` and `_dateGroupLabel()` helpers
- Groups: "Today", "Yesterday", "This Week", "Earlier"

### 7. Summary Bar ✅ DONE
- **File:** `lib/screens/homepad/homepad_screen.dart`
- 48px bar with "X items to buy" (left) + green "All Done!" pill button (right)
- Replaced old header with count badge + TextButton

### 8. Empty state copy and CTA ✅ DONE
- **File:** `lib/screens/homepad/homepad_screen.dart`
- Changed to: "All done for now!" + "Browse below to add what you need" + "Browse Items" CTA button
- CTA opens the Add Item sheet

### 9. Badge semantics mismatch ❌ TODO
- Badge shows count of partner items in list, not "new since last view"
- Never clears after viewing
- **Needs:** `lastViewedAt` timestamp infrastructure — separate task

### 10. Category tag pill on item cards ✅ DONE
- **File:** `lib/widgets/homepad_item_card.dart`
- Added category pill (primary color, 10px font, 8px rounded) next to frequency badge
- Only shown for non-purchased items with non-empty category

### 11. "Clear" button uses error color ✅ DONE
- **File:** `lib/screens/homepad/homepad_screen.dart`
- Changed from `onSurface.withValues(alpha: 0.5)` to `Theme.of(context).colorScheme.error`

### 12. Recently Bought emoji at 30% opacity ✅ DONE
- **File:** `lib/widgets/homepad_item_card.dart`
- Wrapped emoji `Text` in `Opacity(opacity: isPurchased ? 0.3 : 1.0)`

---

## P2 — Nice to Have (Polish)

| # | Issue | Status |
|---|-------|--------|
| 13 | Icon morph animation (scale pulse 1.0→1.15→1.0) when adding from catalog | ❌ TODO |
| 14 | Cascade fade-out for Mark All Done (cards disappear sequentially) | ❌ TODO |
| 15 | Section expand: SizeTransition with per-item stagger instead of CrossFade | ❌ TODO |
| 16 | Mark All Done button styling (pill, 36px, green bg, "All Done!" text) | ✅ DONE (part of #7) |
| 17 | Confirmation dialog copy ("Mark All Done?" not "Mark everything as bought?") | ✅ ALREADY CORRECT |
| 18 | SnackBar after celebration ("Everything's done! Great teamwork!") | ✅ DONE |
| 19 | Add Item sheet: horizontal chips for category instead of dropdown | ❌ TODO |
| 20 | Duplicate `add_custom_item_sheet.dart` — dead code cleanup | ❌ TODO |
| 21 | Filter chip touch targets may not fill full 44px height | ❌ TODO |
| 22 | Offline "Syncing..." indicator | ❌ TODO |
| 23 | Hidden items UI (field exists but no settings screen) | ❌ TODO |
| 24 | Auto-clear purchased after 7 days | ❌ TODO |
| 25 | Notification quiet hours or frequency cap | ❌ TODO |

---

## Summary

| Priority | Total | Done | Remaining |
|----------|-------|------|-----------|
| P0       | 3     | 3    | 0         |
| P1       | 9     | 8    | 1 (#9)    |
| P2       | 13    | 3    | 10        |
| **Total**| **25**| **14**| **11**   |

### Remaining Work (ordered by priority)

1. **P1 #9** — Badge semantics: implement `lastViewedAt` timestamp to show "new since last view" count
2. **P2 #13** — Icon morph animation on catalog add
3. **P2 #14** — Cascade fade-out for Mark All Done
4. **P2 #15** — SizeTransition with stagger for section expand
5. **P2 #19** — Horizontal chips for category in Add Item sheet
6. **P2 #20** — Delete duplicate `add_custom_item_sheet.dart`
7. **P2 #21** — Ensure filter chip touch targets are 44px
8. **P2 #22** — Offline "Syncing..." indicator
9. **P2 #23** — Hidden items settings UI
10. **P2 #24** — Auto-clear purchased items after 7 days (Cloud Function)
11. **P2 #25** — Notification quiet hours / frequency cap
