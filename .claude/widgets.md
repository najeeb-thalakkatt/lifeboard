# Lifeboard Widget Registry

Reusable widgets in `lib/widgets/`. Check here before building new UI — prefer reusing these.

## Cards

### TaskCard
**Path:** `lib/widgets/task_card.dart`
**Params:** `required TaskModel task`, `VoidCallback? onTap`, `VoidCallback? onToggleComplete`, `Map<String, String> memberNames`
**Description:** Task display card with status accent bar, emoji tag, assignee avatars, due date, and blocked indicator.

### ChoreCard
**Path:** `lib/widgets/chore_card.dart`
**Params:** `required Chore chore`, `required VoidCallback onComplete`, `required VoidCallback onSkip`, `required VoidCallback onEdit`, `VoidCallback? onDelete`, `String? assigneeName`, `bool isUpcoming`
**Description:** Chore card with tap-to-complete, swipe-to-skip, and long-press context menu.

### HomePadItemCard
**Path:** `lib/widgets/homepad_item_card.dart`
**Params:** `required HomePadItem item`, `required VoidCallback onTogglePurchased`, `required DismissDirectionCallback onDismissed`, `String? addedByName`, `String? purchasedByName`
**Description:** Shopping item card with checkbox, emoji, frequency badge, and swipe-to-complete.

## Layout

### ResponsiveShell
**Path:** `lib/widgets/responsive_shell.dart`
**Params:** `required String currentLocation`, `required Widget child`
**Description:** Navigation wrapper — bottom nav (<600px), rail (600-1024px), or side drawer (>1024px).

### AppShellBar
**Path:** `lib/widgets/app_shell_bar.dart`
**Params:** `required AppTab currentTab`, `List<Widget>? additionalActions`
**Description:** Shared top app bar with space picker, notification bell (with badge), weekly calendar, and settings gear.

### SharedAppBar
**Path:** `lib/widgets/shared_app_bar.dart`
**Params:** `required String title`, `Widget? titleWidget`, `List<Widget>? actions`, `Widget? leading`, `bool centerTitle`
**Description:** Simple reusable AppBar matching Lifeboard design. Use for full-screen (non-shell) pages.

### BottomNavBar
**Path:** `lib/widgets/bottom_nav_bar.dart`
**Params:** `required int currentIndex`, `required ValueChanged<int> onDestinationSelected`
**Description:** Mobile bottom navigation (Board, Chores, Buy List) with badge counts.

## Data Display

### AvatarWidget
**Path:** `lib/widgets/avatar_widget.dart`
**Params:** `String? imageUrl`, `String? name`, `double radius`
**Description:** Circular avatar showing photo URL or initials fallback. Default radius 20.

### CommentsSection
**Path:** `lib/widgets/comments_section.dart`
**Params:** `required String spaceId`, `required String taskId`
**Description:** Real-time comment list with emoji reactions and input field. Used in task detail.

### HomePadCategorySection
**Path:** `lib/widgets/homepad_category_section.dart`
**Params:** `required String categoryName`, `required String categoryEmoji`, `required List<HomePadItem> items`, `required Function(HomePadItem) onToggleItem`, `bool initiallyExpanded`
**Description:** Collapsible category section with animated chevron for homepad catalog.

## Input

### EmojiTagPicker
**Path:** `lib/widgets/emoji_tag_picker.dart`
**Params:** `required String? selected`, `required ValueChanged<String?> onSelected`
**Description:** Horizontal scrollable emoji tag picker (6 categories). Selected emoji gets teal ring.

## Feedback

### CelebrationOverlay
**Path:** `lib/widgets/celebration_overlay.dart`
**Params:** `required VoidCallback onComplete`
**Description:** Full-screen Lottie confetti animation on task completion. Use via `CelebrationOverlay.show(context)`.

### StaggeredListItem
**Path:** `lib/widgets/stagger_animation.dart`
**Params:** `required int index`, `required Widget child`, `Duration baseDelay`, `Duration duration`, `double verticalOffset`
**Description:** Slide-up + fade-in animation for list items. Each item's delay = index * baseDelay.
