# HomePad — Feature Specification

> **Lifeboard Feature:** Prebuilt household shopping list with 365 items, emoji-tagged, swipe-to-complete, real-time sync, and smart notifications.
> **Version:** 1.0 | March 2026
> **Status:** Planning

---

## Table of Contents

1. [Problem Statement](#1-problem-statement)
2. [User Stories & Acceptance Criteria](#2-user-stories--acceptance-criteria)
3. [MoSCoW Prioritization](#3-moscow-prioritization)
4. [Kanban & Flow Design](#4-kanban--flow-design)
5. [UI/UX Research Summary](#5-uiux-research-summary)
6. [Screen-by-Screen Design Spec](#6-screen-by-screen-design-spec)
7. [Component Specifications](#7-component-specifications)
8. [Animation & Transition Specs](#8-animation--transition-specs)
9. [Prebuilt Item Catalog (365 Items)](#9-prebuilt-item-catalog-365-items)
10. [Data Model & Architecture](#10-data-model--architecture)
11. [Notification Strategy](#11-notification-strategy)
12. [Accessibility](#12-accessibility)
13. [Dark Mode](#13-dark-mode)
14. [Responsive Layout](#14-responsive-layout)
15. [Risks & Edge Cases](#15-risks--edge-cases)
16. [MVP / Thin Slice](#16-mvp--thin-slice)
17. [Implementation Plan](#17-implementation-plan)

---

## 1. Problem Statement

Every household has a recurring, invisible chore that nobody gets credit for: **knowing what needs to be bought.** One partner mentally tracks that the dish soap is almost out, that the kids need more lunch bags, that we're low on rice. This is textbook **invisible mental load** — and it's one of the most frequent sources of friction in shared living.

Today, couples and families use:
- Scattered notes apps (Apple Notes, Google Keep) that aren't structured
- Shared reminders that lack categorization or frequency awareness
- Verbal "can you pick up..." requests that get forgotten
- Paper lists on the fridge that nobody updates

**Why HomePad matters:** Lifeboard already solves the big-picture shared backlog — tasks, projects, goals. But the **most frequent shared workflow in any household is shopping.** HomePad transforms Lifeboard from a weekly planning tool into a **daily household companion.**

> "The best process is the one you'll actually use on a Tuesday night when you're tired."

---

## 2. User Stories & Acceptance Criteria

### US-1: Browse Prebuilt Items
**As a** household member setting up HomePad,
**I want to** browse a comprehensive, categorized list of common household items,
**so that** I can quickly enable items my household regularly needs without typing everything from scratch.

**Acceptance Criteria:**
- [ ] HomePad screen displays 365 prebuilt items organized by category and subcategory
- [ ] Categories are collapsible/expandable sections
- [ ] Each item shows: emoji, name, default frequency badge
- [ ] Items are searchable via a search bar at the top

### US-2: Mark Item as Needed
**As a** household member who notices we're running low on something,
**I want to** tap an item to mark it as "needs buying,"
**so that** anyone in the household knows to pick it up on their next store run.

**Acceptance Criteria:**
- [ ] Tapping an unchecked item moves it to the "To Buy" section
- [ ] Item appears with a visual "needed" state (highlighted, moved to top)
- [ ] The person who marked it is recorded (shown as small avatar)
- [ ] Real-time sync: partner sees the change within 2 seconds

### US-3: Mark Item as Purchased
**As a** household member who just bought an item,
**I want to** swipe or tap to mark it as purchased,
**so that** others see it's been taken care of and we avoid duplicate purchases.

**Acceptance Criteria:**
- [ ] Swipe-to-complete (endToStart, green checkmark) marks item as purchased
- [ ] Alternatively, tap the checkbox to mark purchased
- [ ] Purchased items move to a "Recently Bought" section (collapsed by default)
- [ ] Purchase timestamp and purchaser are recorded
- [ ] Celebration haptic on purchase

### US-4: See Shared List in Real Time
**As a** partner reviewing the shopping list,
**I want to** see items marked as needed/purchased by others in real time,
**so that** we have a single source of truth.

**Acceptance Criteria:**
- [ ] All item state changes sync in real time via Firestore streams
- [ ] Offline changes are queued and synced on reconnection
- [ ] "Syncing..." indicator shown when offline

### US-5: Receive Batched Notifications When Items Are Added
**As a** household member,
**I want to** receive a single batched notification when my partner adds items to the shopping list,
**so that** I'm informed without being overwhelmed.

**Acceptance Criteria:**
- [ ] Adding 1+ items within a 5-minute window triggers a single batched push notification
- [ ] Notification text: "[Name] added X items to HomePad: [first 3 item names]..."
- [ ] Notification respects user's push notification preferences
- [ ] No notification sent to the person who added items

### US-6: Receive "All Done" Notification
**As a** household member at home,
**I want to** receive a notification when all items have been marked as purchased,
**so that** I know my partner has finished the shopping run.

**Acceptance Criteria:**
- [ ] When the last "needed" item is marked purchased, all space members (except the purchaser) receive a push notification
- [ ] Notification text: "[Name] finished the shopping! All items checked off."
- [ ] Celebration animation when viewing HomePad after all items are done

### US-7: Mark All Done
**As a** household member finishing a shopping trip,
**I want to** tap "Mark All Done" to clear all remaining items at once,
**so that** I don't have to individually check off every item in a parking lot.

**Acceptance Criteria:**
- [ ] "Mark All Done" button is visible when there are 2+ items in "To Buy" state
- [ ] Tapping shows confirmation dialog: "Mark all X items as purchased?"
- [ ] On confirm, all items are batch-updated to purchased state
- [ ] Celebration overlay (confetti) plays
- [ ] Triggers "All Done" notification to space members

### US-8: Add Custom Items
**As a** household member with a unique need,
**I want to** add custom items that aren't in the prebuilt list,
**so that** I can track specialty or one-off purchases alongside standard items.

**Acceptance Criteria:**
- [ ] "Add custom item" input available via bottom sheet
- [ ] Custom items require: name (required), emoji (optional, defaults to 🛒), category (optional)
- [ ] Custom items persist across sessions at the space level
- [ ] Custom items can be deleted by any space member

### US-9: Items Organized by Frequency and Category
**As a** household member planning a shopping trip,
**I want to** see items organized by buy frequency (weekly first) and by category,
**so that** I can efficiently navigate the list.

**Acceptance Criteria:**
- [ ] Primary sort: items marked "To Buy" appear first
- [ ] Secondary sort within "To Buy": weekly frequency items first, then biweekly, monthly, as-needed
- [ ] Tertiary grouping: by category
- [ ] User can toggle between "by frequency" and "by category" view

### US-10: Emoji-Tagged Items
**As a** household member scanning a long list,
**I want to** see emoji icons next to each item,
**so that** I can visually identify categories at a glance.

**Acceptance Criteria:**
- [ ] Every prebuilt item has a default emoji
- [ ] Emojis are displayed as leading icon on item rows
- [ ] Custom items can have user-selected emoji

### US-11: Recurring Item Auto-Resurface (Sprint 3+)
**As a** household member,
**I want** weekly/biweekly/monthly items to automatically resurface as "needs buying,"
**so that** I never have to remember to re-add staple items.

### US-12: Per-Space Shopping List
**As a** member of multiple spaces,
**I want** each space to have its own independent HomePad list,
**so that** shopping needs for different households stay separate.

**Acceptance Criteria:**
- [ ] Each space has an independent HomePad collection in Firestore
- [ ] Firestore security rules restrict access to space members only

---

## 3. MoSCoW Prioritization

### Must Have (MVP)
| Feature | Rationale |
|---------|-----------|
| Prebuilt item catalog (365 items) | Core value prop — zero-setup shopping list |
| Category + subcategory organization | Nobody scrolls a flat 365-item list |
| Emoji tags on all items | Brand consistency, visual scanning |
| Mark as "To Buy" (tap) | Core interaction |
| Mark as Purchased (swipe/tap) | Core interaction |
| Real-time sync across space members | Lifeboard's core promise |
| "Mark All Done" button | Key convenience for end-of-trip |
| Per-space HomePad | Data isolation, multi-household |
| Search/filter items | Usability for 365-item list |
| Add custom items | Users will always have items not in the prebuilt list |

### Should Have (Sprint 2)
| Feature | Rationale |
|---------|-----------|
| Batched push notifications (items added) | Shared awareness without noise |
| "All Done" push notification | Satisfying closure + partner awareness |
| Sort by buy frequency (weekly first) | Prioritization aid |
| Recently purchased section | Visibility into what's already handled |
| Purchaser/requester attribution (avatar) | "Who added this?" context |

### Could Have (Sprint 3+)
| Feature | Rationale |
|---------|-----------|
| Recurring item auto-resurface | Automation — reduces re-adding effort |
| Frequency override per item | Personalization |
| Item quantity field | "Buy 3 of these" |
| Store/aisle grouping | Optimize shopping route |

### Won't Have (Not Now)
| Feature | Rationale |
|---------|-----------|
| Barcode scanning | Scope creep, camera complexity |
| Price comparison | Different product category |
| Meal planning integration | Separate feature entirely |
| AI-suggested items | Premature, needs usage data |
| Delivery service integration | Post-launch |

---

## 4. Kanban & Flow Design

### Classes of Service

| Class | Examples | Flow Policy |
|-------|----------|------------|
| **Urgent** | Diapers, medication, toilet paper, pet food | Red accent, appears at top of "To Buy" |
| **Standard** | Weekly groceries, cleaning supplies | Normal sort by frequency then category |
| **Recurring** | Milk, bread, eggs (auto-resurface items) | Auto-populate "To Buy" based on cadence |
| **Aspirational** | Specialty gadgets, upgrade items, home decor | "Wishlist" section, doesn't clutter active list |

### WIP & Flow Considerations

HomePad is a **separate swim lane** from the main kanban board — it does NOT count against board WIP limits:
1. **Different cadence:** Shopping items cycle in hours/days; board tasks in days/weeks
2. **Different nature:** Shopping is transactional; board tasks are creative/effortful
3. **Volume:** A shopping list might have 20+ "To Buy" items — would permanently exceed WIP limits

HomePad lives at `spaces/{spaceId}/homepad_items/{itemId}` — a new collection, connected to the space model but NOT using the existing tasks collection.

---

## 5. UI/UX Research Summary

### Competitive Audit

| App | Strengths | Weaknesses |
|-----|-----------|------------|
| **AnyList** | Clean checkbox + name; auto-category sorting; seamless real-time sync | Catalog discovery buried; cold visual design; no completion celebration |
| **OurGroceries** | Purpose-built for families; reliable sync; "Recently Used" suggestions | Dated UI; adding custom items is disruptive; no frequency concept |
| **Bring!** | Tile/chip cards with emoji illustrations; single-tap add; great "Recently Bought" | Tile grid wastes space at scale; clunky custom item flow; ads in free tier |
| **Apple Reminders** | Auto-categorization via ML; native iOS feel; collapsible spring animations | No prebuilt catalog; iCloud-only sharing; no frequency/suggestions |
| **Listonic** | Smart suggestions; price tracking; "shopping mode" with large targets | Aggressive upselling; inconsistent platform styling; lengthy onboarding |

### Key Design Insights

1. **Single-tap add/remove is non-negotiable** — Bring! and Apple Reminders prove lowest-friction wins
2. **Category auto-grouping during shopping is expected** — "To Buy" list should group by category
3. **"Recently Bought" is the power feature** — resurfacing recent purchases reduces repeat entry
4. **Celebration on completion matters for couples** — clear differentiation opportunity
5. **List view beats grid for 10+ items** — compact list with emoji + grouping is better information density
6. **Real-time sync must be invisible** — no manual refresh, no sync buttons
7. **Warm, not clinical** — "What do we need?" not "Shopping List"

---

## 6. Screen-by-Screen Design Spec

### A. HomePad Main Screen

#### Access Point
New **bottom navigation tab** (5th item) between "This Week" and "Activity":

| Index | Icon | Label |
|-------|------|-------|
| 0 | `Icons.grid_view_outlined` | Spaces |
| 1 | `Icons.calendar_today_outlined` | This Week |
| 2 | **`Icons.shopping_cart_outlined`** | **HomePad** |
| 3 | `Icons.notifications_outlined` | Activity |
| 4 | `Icons.person_outlined` | Profile |

**Badge:** Numeric badge when partner adds items (matches Activity badge pattern).

#### Layout Structure (top to bottom)

1. **App Bar** — "HomePad" in Nunito Bold 20sp, `primaryDark`. Right action: overflow menu (Clear Purchased, Settings)
2. **Search Bar** — Pinned `SliverPersistentHeader`, 56px. Rounded rectangle, 12px radius, `inputFill` (#F5F7F8). Filters both "To Buy" and catalog in real time.
3. **Summary Bar** — 48px. Left: "12 items to buy" (Inter SemiBold 14sp). Right: "Mark All Done" pill button. Only visible when items exist in "To Buy."
4. **"To Buy" Section** — Header: "What we need" (Nunito Bold 16sp). Items grouped by category with lightweight sub-headers (emoji + uppercase category name, Inter SemiBold 12sp).
5. **"Browse & Add" Section** — Header: "Add items" with trailing "Add Custom" button. Horizontal scrollable category chips. Catalog items below.
6. **"Recently Bought" Section** — Collapsed by default. See section G.

#### Item Card Design ("To Buy" state)

```
 [Checkbox]  [Emoji]  [Item Name]        [Freq Badge]  [Category Tag]
```

- Card: 52px min height, 16px horizontal margin, 4px vertical margin, 10px border radius
- Background: `surface` (white). Shadow: blur 4, offset (0,1)
- **Left accent bar:** 3px, `primaryDark` (#2F6264)
- **Checkbox:** 22px circle, 44px tap target. Unchecked: `primaryDark` 30% outline. Checked: `statusDone` (#4CAF50) fill + white checkmark
- **Emoji:** 20sp, 8px gap after checkbox
- **Item Name:** Inter Medium 14sp, `primaryDark`, single line with ellipsis
- **Frequency Badge:** 16px pill, `accentWarm` 12% bg, "Weekly"/"Monthly" in Inter Medium 10sp
- **Category Tag:** 16px pill, `primaryLight` bg, category name in Inter Regular 10sp

#### Empty State
- Large emoji: "🛒" at 48sp
- Heading: "All done for now!" (Nunito Bold 20sp)
- Subheading: "Browse below to add what you need" (Inter Regular 14sp, 60% opacity)
- CTA: "Browse Items" filled button

### B. Category Browser

7 top-level categories, each with subcategories:

| Category | Emoji | Subcategories |
|----------|-------|---------------|
| Groceries | 🥦 | Fresh Produce, Dairy & Eggs, Meat & Seafood, Pantry Staples, Beverages, Frozen, Bakery, Snacks, Condiments, Spices, Baby Food |
| Cleaning | 🧹 | Kitchen, Bathroom, Laundry, Floor, General |
| Stationery | 📝 | (flat list) |
| Home Essentials | 🏠 | Kitchen, Bathroom, Bedroom & Living, Storage, Tools |
| Personal Care | 🧴 | Hair Care, Skin Care, Oral Care, Body Care |
| Pet Supplies | 🐾 | (flat list) |
| Baby & Kids | 👶 | (flat list) |

**Section Header:** 44px height. Left: emoji + category name (Nunito Bold 16sp). Right: item count + animated chevron.

**Item Row:** 44px height. Left: emoji (18sp) + item name (Inter Regular 14sp). Right: add button (outlined circle → filled check when added). Tap row to toggle.

**Visual State Distinction:**

| State | Text | Icon | Opacity |
|-------|------|------|---------|
| Available | Inter Regular 14sp | `add_circle_outline` 40% | 100% |
| To Buy | Inter SemiBold 14sp | `check_circle` green | 100% |
| Purchased | Inter Regular 14sp 40% | `check_circle_outline` 20% | 50% |

### C. Item States

| State | Where It Appears | Visual Treatment | Transitions To |
|-------|-----------------|-----------------|----------------|
| **Available** | Category browser only | Standard weight, outlined add icon | To Buy (single tap) |
| **To Buy** | "To Buy" section + browser (with check) | Semi-bold, teal accent bar, filled checkbox | Purchased (checkbox/swipe/mark all) |
| **Purchased** | "Recently Bought" + browser (dimmed) | Strikethrough, 40% opacity, dim check | To Buy (re-add tap) or Available (auto after 7 days) |

### D. Swipe-to-Complete

Consistent with existing `Dismissible` in `CompactKanbanColumn`:
- **Direction:** End-to-start (swipe left)
- **Background:** `statusDone` (#4CAF50), `Icons.check` white, "Done" text
- **Threshold:** 40% of card width
- **On swipe:** Haptic (`mediumImpact`), card slides out left (200ms), gap closes (200ms)
- **Undo:** SnackBar with "Undo" action, 4 seconds

### E. "Mark All Done" Flow

**Button:** Pill shape, 36px height, `statusDone` bg, "All Done!" text + `Icons.check_all`

**Confirmation Dialog:**
- Title: "Mark everything as bought?" (Nunito Bold 18sp)
- Content: "This will move all 12 items to Recently Bought." (Inter Regular 14sp)
- Actions: "Cancel" (TextButton) + "Yes, all done!" (FilledButton, green)

**Celebration:**
1. Dialog dismisses
2. Cards cascade fade-out (300ms, staggered 30ms each)
3. Confetti overlay via `CelebrationOverlay.show(context)` — 2 seconds
4. `HapticFeedback.heavyImpact()`
5. Empty state fades in
6. SnackBar: "Everything's done! Great teamwork!"
7. Push notification to partner

### F. Add Custom Item (Bottom Sheet)

**Fields:**
1. **Item Name** — TextField, "What do you need?" placeholder, auto-focus
2. **Emoji Picker** — Horizontal scrollable row of common emojis: 🛒 🍎 🥛 🧀 🍞 🥩 🧃 🧹 🧴 💊 🐾 👶 📦 💡 🔋
3. **Category Selection** — Horizontal category chips (same as main screen)
4. **Add to list toggle** — CupertinoSwitch, default ON

**CTA:** Full-width "Add Item" button, `primaryDark` bg

### G. Recently Bought Section

**Collapsed:** Header: "Recently Bought" (Nunito Bold 16sp, 60% opacity) + count badge + chevron

**Expanded:**
- Items sorted by `purchasedAt`, grouped by date ("Today", "Yesterday", "This Week", "Earlier")
- Item appearance: emoji (30% opacity) + name (40% opacity, strikethrough)
- Actions: "Re-add" button + "X" remove button
- "Clear All" text button in `error` color with confirmation dialog
- Auto-clear after 7 days

### H. Notification Display

- Tapping notification deep-links to HomePad tab (`/homepad` route)
- Numeric badge on HomePad tab icon (count of partner-added items since last view)
- Badge clears on tab visit

---

## 7. Component Specifications

### Spacing Grid (8pt)
| Size | Usage |
|------|-------|
| 4px | Micro spacing (badge elements, icon-text tight) |
| 8px | Item internal spacing (emoji to name, chip gap) |
| 12px | Card internal padding, section indent |
| 16px | Section margins, page padding |
| 24px | Large vertical gaps between major sections |
| 32px | Empty state padding |

### Key Component Specs

| Component | Flutter Widget | Height | Colors |
|-----------|---------------|--------|--------|
| Item Card | `Container` + `IntrinsicHeight` + `Row` | 52px min | `surface` bg, `primaryDark` accent |
| Checkbox | Custom `GestureDetector` + `AnimatedContainer` | 22px (44px tap) | `primaryDark` 30% → `statusDone` |
| Category Chip | `ChoiceChip` or custom | 36px | `primaryLight` / `primaryDark` |
| Section Header | `GestureDetector` + `AnimatedRotation` | 44px | `primaryDark` text |
| Summary Bar | `Container` + `Row` | 48px | transparent bg |
| Search Bar | `TextField` in `SliverPersistentHeader` | 48px (56px sliver) | `inputFill` #F5F7F8 |

---

## 8. Animation & Transition Specs

### Item Add (Available → To Buy)
- **Duration:** 300ms, `Curves.easeOutCubic`
- **Catalog:** Icon morphs `add_circle_outline` → `check_circle`, scale pulse 1.0→1.15→1.0
- **"To Buy":** Card slides in from right (translateX 20→0), fades in
- **Haptic:** `lightImpact()`

### Purchase Swipe
- **Duration:** 400ms total
- Phase 1 (0-200ms): Card slides left, green bg revealed
- Phase 2 (200-400ms): Gap closes, cards below slide up
- **Haptic:** `mediumImpact()` at threshold

### Mark All Done Celebration
- **Duration:** ~2500ms total
- Phase 1: Cards cascade fade-out (300ms + 30ms×N stagger)
- Phase 2: Confetti (2s Lottie)
- Phase 3: Empty state fades in
- **Haptic:** `heavyImpact()`

### Section Expand/Collapse
- **Duration:** 250ms, `Curves.easeInOutCubic`
- Chevron rotates 180°, content `SizeTransition`
- Items stagger in: 30ms delay each

### List Stagger on Load
- Uses existing `StaggeredListItem`: 50ms baseDelay, 350ms duration, 20px verticalOffset

### Reduce Motion
- All slide/fade replaced with instant show/hide
- Confetti shows as static frame
- Haptics still fire

---

## 9. Prebuilt Item Catalog (365 Items)

### Groceries (178 items)

#### Fresh Produce (38 items)
| # | Item | Emoji | Frequency |
|---|------|-------|-----------|
| 1 | Bananas | 🍌 | Weekly |
| 2 | Apples | 🍎 | Weekly |
| 3 | Oranges | 🍊 | Weekly |
| 4 | Lemons | 🍋 | Biweekly |
| 5 | Limes | 🟢 | Biweekly |
| 6 | Grapes | 🍇 | Weekly |
| 7 | Strawberries | 🍓 | Weekly |
| 8 | Blueberries | 🫐 | Weekly |
| 9 | Avocados | 🥑 | Weekly |
| 10 | Tomatoes | 🍅 | Weekly |
| 11 | Onions | 🧅 | Weekly |
| 12 | Garlic | 🧄 | Biweekly |
| 13 | Potatoes | 🥔 | Weekly |
| 14 | Sweet Potatoes | 🍠 | Biweekly |
| 15 | Carrots | 🥕 | Weekly |
| 16 | Broccoli | 🥦 | Weekly |
| 17 | Spinach | 🥬 | Weekly |
| 18 | Lettuce | 🥗 | Weekly |
| 19 | Cucumber | 🥒 | Weekly |
| 20 | Bell Peppers | 🫑 | Weekly |
| 21 | Mushrooms | 🍄 | Weekly |
| 22 | Corn | 🌽 | Biweekly |
| 23 | Green Beans | 🌱 | Biweekly |
| 24 | Zucchini | 🥒 | Biweekly |
| 25 | Celery | 🌿 | Biweekly |
| 26 | Ginger | 🟤 | Biweekly |
| 27 | Fresh Herbs (Cilantro) | 🌿 | Weekly |
| 28 | Fresh Herbs (Basil) | 🌿 | Weekly |
| 29 | Fresh Herbs (Parsley) | 🌿 | Weekly |
| 30 | Mangoes | 🥭 | Biweekly |
| 31 | Pineapple | 🍍 | Biweekly |
| 32 | Watermelon | 🍉 | As-needed |
| 33 | Peaches | 🍑 | As-needed |
| 34 | Kiwi | 🥝 | Biweekly |
| 35 | Cabbage | 🥬 | Biweekly |
| 36 | Cauliflower | 🥦 | Biweekly |
| 37 | Asparagus | 🌱 | Biweekly |
| 38 | Eggplant | 🍆 | Biweekly |

#### Dairy & Eggs (14 items)
| # | Item | Emoji | Frequency |
|---|------|-------|-----------|
| 39 | Milk | 🥛 | Weekly |
| 40 | Eggs | 🥚 | Weekly |
| 41 | Butter | 🧈 | Biweekly |
| 42 | Cheddar Cheese | 🧀 | Biweekly |
| 43 | Mozzarella Cheese | 🧀 | Biweekly |
| 44 | Cream Cheese | 🧀 | Biweekly |
| 45 | Yogurt | 🥤 | Weekly |
| 46 | Greek Yogurt | 🥤 | Weekly |
| 47 | Sour Cream | 🥣 | Biweekly |
| 48 | Heavy Cream | 🥛 | Biweekly |
| 49 | Cottage Cheese | 🧀 | Biweekly |
| 50 | Parmesan Cheese | 🧀 | Monthly |
| 51 | Almond Milk | 🥛 | Weekly |
| 52 | Oat Milk | 🥛 | Weekly |

#### Meat & Seafood (14 items)
| # | Item | Emoji | Frequency |
|---|------|-------|-----------|
| 53 | Chicken Breast | 🍗 | Weekly |
| 54 | Chicken Thighs | 🍗 | Weekly |
| 55 | Ground Beef | 🥩 | Weekly |
| 56 | Ground Turkey | 🦃 | Biweekly |
| 57 | Steak | 🥩 | Biweekly |
| 58 | Pork Chops | 🥩 | Biweekly |
| 59 | Bacon | 🥓 | Weekly |
| 60 | Sausages | 🌭 | Biweekly |
| 61 | Salmon | 🐟 | Weekly |
| 62 | Shrimp | 🦐 | Biweekly |
| 63 | Tuna (fresh) | 🐟 | Biweekly |
| 64 | Lamb | 🥩 | As-needed |
| 65 | Deli Turkey | 🦃 | Weekly |
| 66 | Deli Ham | 🥩 | Weekly |

#### Bakery (9 items)
| # | Item | Emoji | Frequency |
|---|------|-------|-----------|
| 67 | Bread (Sliced) | 🍞 | Weekly |
| 68 | Tortillas | 🫓 | Biweekly |
| 69 | Bagels | 🥯 | Weekly |
| 70 | English Muffins | 🍞 | Biweekly |
| 71 | Pita Bread | 🫓 | Biweekly |
| 72 | Hamburger Buns | 🍔 | As-needed |
| 73 | Hot Dog Buns | 🌭 | As-needed |
| 74 | Croissants | 🥐 | As-needed |
| 75 | Dinner Rolls | 🍞 | As-needed |

#### Pantry Staples (39 items)
| # | Item | Emoji | Frequency |
|---|------|-------|-----------|
| 76 | Rice (White) | 🍚 | Monthly |
| 77 | Rice (Brown) | 🍚 | Monthly |
| 78 | Pasta (Spaghetti) | 🍝 | Biweekly |
| 79 | Pasta (Penne) | 🍝 | Biweekly |
| 80 | Pasta Sauce | 🥫 | Biweekly |
| 81 | Canned Tomatoes | 🥫 | Biweekly |
| 82 | Canned Beans (Black) | 🥫 | Biweekly |
| 83 | Canned Beans (Kidney) | 🥫 | Monthly |
| 84 | Canned Chickpeas | 🥫 | Monthly |
| 85 | Canned Tuna | 🥫 | Biweekly |
| 86 | Canned Corn | 🥫 | Monthly |
| 87 | Canned Soup | 🥫 | Monthly |
| 88 | Chicken Broth | 🥣 | Biweekly |
| 89 | Vegetable Broth | 🥣 | Monthly |
| 90 | Flour (All-Purpose) | 🍞 | Monthly |
| 91 | Sugar (White) | 🍬 | Monthly |
| 92 | Brown Sugar | 🍬 | Monthly |
| 93 | Baking Soda | 🧪 | As-needed |
| 94 | Baking Powder | 🧪 | As-needed |
| 95 | Cooking Oil (Vegetable) | 💧 | Monthly |
| 96 | Olive Oil | 🫒 | Monthly |
| 97 | Coconut Oil | 🥥 | As-needed |
| 98 | Vinegar (White) | 💧 | As-needed |
| 99 | Apple Cider Vinegar | 🍏 | As-needed |
| 100 | Peanut Butter | 🥜 | Biweekly |
| 101 | Jelly/Jam | 🍓 | Monthly |
| 102 | Honey | 🍯 | Monthly |
| 103 | Maple Syrup | 🥞 | Monthly |
| 104 | Oats (Rolled) | 🥣 | Biweekly |
| 105 | Cereal | 🥣 | Weekly |
| 106 | Granola | 🥣 | Biweekly |
| 107 | Cornstarch | 🧪 | As-needed |
| 108 | Breadcrumbs | 🍞 | As-needed |
| 109 | Nuts (Almonds) | 🌰 | Biweekly |
| 110 | Nuts (Walnuts) | 🌰 | Biweekly |
| 111 | Dried Fruit (Raisins) | 🍇 | Monthly |
| 112 | Lentils | 🌱 | Monthly |
| 113 | Quinoa | 🍚 | Monthly |
| 114 | Couscous | 🍚 | As-needed |

#### Snacks & Beverages (19 items)
| # | Item | Emoji | Frequency |
|---|------|-------|-----------|
| 115 | Coffee (Ground/Beans) | ☕ | Weekly |
| 116 | Tea Bags | 🍵 | Monthly |
| 117 | Orange Juice | 🧃 | Weekly |
| 118 | Apple Juice | 🧃 | Weekly |
| 119 | Sparkling Water | 🧋 | Weekly |
| 120 | Soda/Soft Drinks | 🥤 | Weekly |
| 121 | Bottled Water | 💧 | Weekly |
| 122 | Sports Drinks | 🥤 | As-needed |
| 123 | Chips/Crisps | 🍟 | Weekly |
| 124 | Crackers | 🍪 | Biweekly |
| 125 | Popcorn | 🍿 | Biweekly |
| 126 | Cookies | 🍪 | Biweekly |
| 127 | Chocolate | 🍫 | Biweekly |
| 128 | Granola Bars | 🍫 | Weekly |
| 129 | Trail Mix | 🌰 | Biweekly |
| 130 | Pretzels | 🥨 | Biweekly |
| 131 | Dried Seaweed | 🌱 | As-needed |
| 132 | Fruit Snacks | 🍓 | Weekly |
| 133 | Ice Cream | 🍦 | Biweekly |

#### Frozen (11 items)
| # | Item | Emoji | Frequency |
|---|------|-------|-----------|
| 134 | Frozen Vegetables (Mixed) | 🥦 | Biweekly |
| 135 | Frozen Berries | 🫐 | Biweekly |
| 136 | Frozen Pizza | 🍕 | Biweekly |
| 137 | Frozen Chicken Nuggets | 🍗 | Biweekly |
| 138 | Frozen Fish Fillets | 🐟 | Biweekly |
| 139 | Frozen Fries | 🍟 | Biweekly |
| 140 | Frozen Waffles | 🧇 | Biweekly |
| 141 | Frozen Burritos | 🌯 | As-needed |
| 142 | Frozen Peas | 🌱 | Monthly |
| 143 | Frozen Corn | 🌽 | Monthly |
| 144 | Frozen Fruit Bars | 🍦 | Biweekly |

#### Condiments & Sauces (14 items)
| # | Item | Emoji | Frequency |
|---|------|-------|-----------|
| 145 | Ketchup | 🍅 | Monthly |
| 146 | Mustard | 🟡 | Monthly |
| 147 | Mayonnaise | 🥚 | Monthly |
| 148 | Soy Sauce | 🍶 | Monthly |
| 149 | Hot Sauce | 🌶️ | Monthly |
| 150 | BBQ Sauce | 🥩 | As-needed |
| 151 | Salad Dressing | 🥗 | Biweekly |
| 152 | Salsa | 🌶️ | Biweekly |
| 153 | Hummus | 🧆 | Weekly |
| 154 | Worcestershire Sauce | 💧 | As-needed |
| 155 | Fish Sauce | 🐟 | As-needed |
| 156 | Teriyaki Sauce | 🍶 | As-needed |
| 157 | Ranch Dressing | 🥗 | Biweekly |
| 158 | Sriracha | 🌶️ | Monthly |

#### Spices & Seasonings (14 items)
| # | Item | Emoji | Frequency |
|---|------|-------|-----------|
| 159 | Salt | 🧂 | As-needed |
| 160 | Black Pepper | 🟤 | As-needed |
| 161 | Garlic Powder | 🧄 | As-needed |
| 162 | Onion Powder | 🧅 | As-needed |
| 163 | Paprika | 🔴 | As-needed |
| 164 | Cumin | 🟤 | As-needed |
| 165 | Chili Powder | 🌶️ | As-needed |
| 166 | Italian Seasoning | 🌿 | As-needed |
| 167 | Cinnamon | 🟤 | As-needed |
| 168 | Oregano | 🌿 | As-needed |
| 169 | Turmeric | 🟡 | As-needed |
| 170 | Bay Leaves | 🍃 | As-needed |
| 171 | Red Pepper Flakes | 🌶️ | As-needed |
| 172 | Vanilla Extract | 💧 | As-needed |

#### Baby Food (6 items)
| # | Item | Emoji | Frequency |
|---|------|-------|-----------|
| 173 | Baby Formula | 🍼 | Weekly |
| 174 | Baby Cereal | 👶 | Biweekly |
| 175 | Baby Puree Pouches | 👶 | Weekly |
| 176 | Teething Biscuits | 🍪 | Biweekly |
| 177 | Baby Snacks (Puffs) | 👶 | Biweekly |
| 178 | Baby Water | 🍼 | Weekly |

### Cleaning Supplies (40 items)

#### Kitchen Cleaning (9 items)
| # | Item | Emoji | Frequency |
|---|------|-------|-----------|
| 179 | Dish Soap | 🧴 | Biweekly |
| 180 | Dishwasher Detergent | 🧴 | Monthly |
| 181 | Dishwasher Rinse Aid | 💧 | As-needed |
| 182 | Sponges | 🟨 | Biweekly |
| 183 | Steel Wool Pads | 🪥 | Monthly |
| 184 | Kitchen Spray Cleaner | ✨ | Monthly |
| 185 | Oven Cleaner | ✨ | As-needed |
| 186 | Dish Drying Mat | 🟦 | As-needed |
| 187 | Garbage Bags (Kitchen) | 🗑️ | Biweekly |

#### Bathroom Cleaning (6 items)
| # | Item | Emoji | Frequency |
|---|------|-------|-----------|
| 188 | Toilet Bowl Cleaner | 🚽 | Monthly |
| 189 | Bathroom Spray Cleaner | ✨ | Monthly |
| 190 | Toilet Brush (replacement) | 🚽 | As-needed |
| 191 | Shower Cleaner | 🚿 | Monthly |
| 192 | Drain Cleaner | 💧 | As-needed |
| 193 | Mildew Remover | ✨ | As-needed |

#### Laundry (7 items)
| # | Item | Emoji | Frequency |
|---|------|-------|-----------|
| 194 | Laundry Detergent | 👕 | Monthly |
| 195 | Fabric Softener | 👕 | Monthly |
| 196 | Dryer Sheets | 👕 | Monthly |
| 197 | Stain Remover | ✨ | As-needed |
| 198 | Bleach | 💧 | As-needed |
| 199 | Laundry Bags (Delicates) | 👕 | As-needed |
| 200 | Lint Roller | 👕 | As-needed |

#### Floor Cleaning (5 items)
| # | Item | Emoji | Frequency |
|---|------|-------|-----------|
| 201 | Floor Cleaner (All-Purpose) | 🧹 | Monthly |
| 202 | Mop Refill Pads | 🧹 | Monthly |
| 203 | Vacuum Bags/Filters | 🌀 | As-needed |
| 204 | Carpet Cleaner | 🧹 | As-needed |
| 205 | Broom (replacement) | 🧹 | As-needed |

#### General Cleaning (13 items)
| # | Item | Emoji | Frequency |
|---|------|-------|-----------|
| 206 | All-Purpose Cleaner | ✨ | Monthly |
| 207 | Glass/Window Cleaner | 🪟 | Monthly |
| 208 | Disinfecting Wipes | ✨ | Biweekly |
| 209 | Paper Towels | 🧻 | Weekly |
| 210 | Trash Bags (Large) | 🗑️ | Biweekly |
| 211 | Trash Bags (Small) | 🗑️ | Monthly |
| 212 | Rubber Gloves | 🧤 | As-needed |
| 213 | Microfiber Cloths | 🟦 | As-needed |
| 214 | Dusting Spray | ✨ | Monthly |
| 215 | Air Freshener | 👃 | Monthly |
| 216 | Candles (Scented) | 🕯️ | As-needed |
| 217 | Hand Sanitizer | 🖐️ | Monthly |
| 218 | Rubbing Alcohol | 🧪 | As-needed |

### Stationery & Office (21 items)

| # | Item | Emoji | Frequency |
|---|------|-------|-----------|
| 219 | Pens (Ballpoint) | 🖊️ | As-needed |
| 220 | Pencils | ✏️ | As-needed |
| 221 | Markers/Highlighters | 🖍️ | As-needed |
| 222 | Notebooks | 📓 | As-needed |
| 223 | Sticky Notes (Post-its) | 📝 | Monthly |
| 224 | Printer Paper | 📄 | Monthly |
| 225 | Printer Ink/Toner | 🖨️ | As-needed |
| 226 | Envelopes | ✉️ | As-needed |
| 227 | Stamps | 📮 | As-needed |
| 228 | Tape (Scotch/Clear) | 📏 | As-needed |
| 229 | Glue Stick | 📏 | As-needed |
| 230 | Scissors | ✂️ | As-needed |
| 231 | Stapler + Staples | 📎 | As-needed |
| 232 | Paper Clips | 📎 | As-needed |
| 233 | Rubber Bands | ⭕ | As-needed |
| 234 | Folders/Binders | 📁 | As-needed |
| 235 | Labels (Address/Sticker) | 🏷️ | As-needed |
| 236 | Correction Tape | 📏 | As-needed |
| 237 | Batteries (AA) | 🔋 | As-needed |
| 238 | Batteries (AAA) | 🔋 | As-needed |
| 239 | Batteries (9V/C/D) | 🔋 | As-needed |

### Home Essentials (51 items)

#### Kitchen Essentials (15 items)
| # | Item | Emoji | Frequency |
|---|------|-------|-----------|
| 240 | Aluminum Foil | 🧻 | Monthly |
| 241 | Plastic Wrap / Cling Film | 🧻 | Monthly |
| 242 | Parchment Paper | 📜 | Monthly |
| 243 | Ziplock Bags (Sandwich) | 📦 | Monthly |
| 244 | Ziplock Bags (Gallon) | 📦 | Monthly |
| 245 | Food Storage Containers | 🍱 | As-needed |
| 246 | Paper Plates | 🍽️ | As-needed |
| 247 | Paper Cups | 🥤 | As-needed |
| 248 | Plastic Utensils | 🍴 | As-needed |
| 249 | Napkins | 📜 | Biweekly |
| 250 | Coffee Filters | ☕ | Monthly |
| 251 | Water Filter (Replacement) | 💧 | As-needed |
| 252 | Kitchen Towels (Cloth) | 🟦 | As-needed |
| 253 | Oven Mitts | 🧤 | As-needed |
| 254 | Can Opener (replacement) | 🥫 | As-needed |

#### Bathroom Essentials (9 items)
| # | Item | Emoji | Frequency |
|---|------|-------|-----------|
| 255 | Toilet Paper | 🧻 | Weekly |
| 256 | Tissues (Facial) | 🤧 | Biweekly |
| 257 | Cotton Balls | ☁️ | Monthly |
| 258 | Cotton Swabs (Q-tips) | 👂 | Monthly |
| 259 | Bandages (Band-Aids) | 🩹 | As-needed |
| 260 | First Aid Kit Refills | 🏥 | As-needed |
| 261 | Shower Curtain Liner | 🚿 | As-needed |
| 262 | Bath Mat | 🛁 | As-needed |
| 263 | Soap Dispenser | 🧴 | As-needed |

#### Bedroom & Living (11 items)
| # | Item | Emoji | Frequency |
|---|------|-------|-----------|
| 264 | Light Bulbs (LED) | 💡 | As-needed |
| 265 | Candles | 🕯️ | As-needed |
| 266 | Hangers | 👕 | As-needed |
| 267 | Shoe Rack | 👟 | As-needed |
| 268 | Pillows | 😴 | As-needed |
| 269 | Bed Sheets | 🛏️ | As-needed |
| 270 | Blanket/Throw | 🛏️ | As-needed |
| 271 | Curtains | 🪟 | As-needed |
| 272 | Extension Cord | 🔌 | As-needed |
| 273 | Power Strip | 🔌 | As-needed |
| 274 | Smoke Detector Batteries | 🚒 | As-needed |

#### Storage & Organization (6 items)
| # | Item | Emoji | Frequency |
|---|------|-------|-----------|
| 275 | Storage Bins | 📦 | As-needed |
| 276 | Shelf Liner | 📏 | As-needed |
| 277 | Hooks (Adhesive) | 🪝 | As-needed |
| 278 | Label Maker Tape | 🏷️ | As-needed |
| 279 | Vacuum Storage Bags | 📦 | As-needed |
| 280 | Drawer Organizers | 📦 | As-needed |

#### Tools & Hardware (10 items)
| # | Item | Emoji | Frequency |
|---|------|-------|-----------|
| 281 | Duct Tape | 📏 | As-needed |
| 282 | Super Glue | 💧 | As-needed |
| 283 | WD-40 | 🔧 | As-needed |
| 284 | Nails/Screws Assortment | 🔩 | As-needed |
| 285 | Picture Hanging Kit | 🖼️ | As-needed |
| 286 | Flashlight | 🔦 | As-needed |
| 287 | Measuring Tape | 📏 | As-needed |
| 288 | Zip Ties | 🔗 | As-needed |
| 289 | Electrical Tape | 📏 | As-needed |
| 290 | Plunger | 🚽 | As-needed |

### Personal Care (35 items)

#### Hair Care (8 items)
| # | Item | Emoji | Frequency |
|---|------|-------|-----------|
| 291 | Shampoo | 🚿 | Monthly |
| 292 | Conditioner | 🚿 | Monthly |
| 293 | Hair Gel/Mousse | 💇 | Monthly |
| 294 | Hair Spray | 💇 | Monthly |
| 295 | Hair Ties/Bobby Pins | 💇 | As-needed |
| 296 | Hair Brush/Comb | 💇 | As-needed |
| 297 | Dry Shampoo | 🚿 | Monthly |
| 298 | Hair Oil/Serum | 💧 | As-needed |

#### Skin Care (9 items)
| # | Item | Emoji | Frequency |
|---|------|-------|-----------|
| 299 | Face Wash/Cleanser | ✨ | Monthly |
| 300 | Moisturizer (Face) | 💧 | Monthly |
| 301 | Sunscreen | ☀️ | Monthly |
| 302 | Body Lotion | 🧴 | Monthly |
| 303 | Lip Balm | 👄 | As-needed |
| 304 | Face Masks | 🎭 | As-needed |
| 305 | Makeup Remover | ✨ | Monthly |
| 306 | Toner | 💧 | Monthly |
| 307 | Eye Cream | 👁️ | As-needed |

#### Oral Care (6 items)
| # | Item | Emoji | Frequency |
|---|------|-------|-----------|
| 308 | Toothpaste | 🦷 | Monthly |
| 309 | Toothbrush (replacement) | 🦷 | As-needed |
| 310 | Dental Floss | 🦷 | Monthly |
| 311 | Mouthwash | 🦷 | Monthly |
| 312 | Whitening Strips | ✨ | As-needed |
| 313 | Tongue Scraper | 👅 | As-needed |

#### Body Care (12 items)
| # | Item | Emoji | Frequency |
|---|------|-------|-----------|
| 314 | Bar Soap | 🧼 | Monthly |
| 315 | Body Wash | 🚿 | Monthly |
| 316 | Deodorant | 👃 | Monthly |
| 317 | Razors/Replacement Blades | 🪒 | Monthly |
| 318 | Shaving Cream/Gel | 🪒 | Monthly |
| 319 | Feminine Hygiene Products | 👩 | Monthly |
| 320 | Contact Lens Solution | 👓 | Monthly |
| 321 | Hand Soap (Refill) | 🤲 | Biweekly |
| 322 | Hand Cream | 🖐️ | As-needed |
| 323 | Nail Clippers | 💅 | As-needed |
| 324 | Tweezers | 📏 | As-needed |
| 325 | Sunscreen (Body) | ☀️ | As-needed |

### Pet Supplies (15 items)

| # | Item | Emoji | Frequency |
|---|------|-------|-----------|
| 326 | Dog Food (Dry) | 🐕 | Biweekly |
| 327 | Dog Food (Wet/Canned) | 🐕 | Weekly |
| 328 | Cat Food (Dry) | 🐈 | Biweekly |
| 329 | Cat Food (Wet/Canned) | 🐈 | Weekly |
| 330 | Cat Litter | 🐈 | Biweekly |
| 331 | Dog Treats | 🦴 | Biweekly |
| 332 | Cat Treats | 🐈 | Biweekly |
| 333 | Poop Bags | 🐕 | Biweekly |
| 334 | Pet Shampoo | 🚿 | As-needed |
| 335 | Flea/Tick Treatment | 🐛 | Monthly |
| 336 | Pet Toys | 🧸 | As-needed |
| 337 | Pet Bed | 🛏️ | As-needed |
| 338 | Fish Food | 🐠 | Monthly |
| 339 | Pet Vitamins/Supplements | 💊 | Monthly |
| 340 | Litter Box Liners | 🐈 | Monthly |

### Baby & Kids (25 items)

| # | Item | Emoji | Frequency |
|---|------|-------|-----------|
| 341 | Diapers | 👶 | Weekly |
| 342 | Baby Wipes | 👶 | Weekly |
| 343 | Diaper Cream/Rash Ointment | 👶 | Monthly |
| 344 | Baby Shampoo/Body Wash | 👶 | Monthly |
| 345 | Baby Lotion | 👶 | Monthly |
| 346 | Baby Laundry Detergent | 👶 | Monthly |
| 347 | Sippy Cups | 🍼 | As-needed |
| 348 | Pacifiers | 👶 | As-needed |
| 349 | Bibs | 👶 | As-needed |
| 350 | Baby Sunscreen | 👶 | As-needed |
| 351 | Kids Toothpaste | 🦷 | Monthly |
| 352 | Kids Toothbrush | 🦷 | As-needed |
| 353 | Pull-Ups/Training Pants | 👶 | Weekly |
| 354 | Kids Vitamins | 💊 | Monthly |
| 355 | School Lunch Bags | 🎒 | As-needed |
| 356 | Juice Boxes | 🧃 | Weekly |
| 357 | Kids Snack Packs | 🍪 | Weekly |
| 358 | Crayons/Colored Pencils | 🖍️ | As-needed |
| 359 | Art Supplies (Paint, Paper) | 🎨 | As-needed |
| 360 | Stickers | ⭐ | As-needed |
| 361 | Play-Doh | 🎨 | As-needed |
| 362 | Craft Supplies (Glue, Glitter) | ✨ | As-needed |
| 363 | Hand Sanitizer (Kids) | 🖐️ | Monthly |
| 364 | Sunscreen (Kids) | ☀️ | As-needed |
| 365 | Swim Diapers | 👶 | As-needed |

---

## 10. Data Model & Architecture

### Firestore Collection

```
spaces/{spaceId}/homepad_items/{itemId}
  name: string                              # "Milk"
  emoji: string                             # "🥛"
  category: string                          # "Groceries"
  subcategory: string                       # "Dairy & Eggs"
  status: 'available' | 'to_buy' | 'purchased'
  frequency: 'weekly' | 'biweekly' | 'monthly' | 'as_needed'
  isCustom: bool                            # false for prebuilt, true for user-added
  isHidden: bool                            # user can hide unwanted prebuilt items
  addedBy: userId?                          # who marked it "to_buy"
  addedAt: timestamp?                       # when marked "to_buy"
  purchasedBy: userId?                      # who bought it
  purchasedAt: timestamp?                   # when purchased
  quantity: int                             # default 1
  note: string?                             # optional user note
  purchaseCount: int                        # for frequency tracking
  order: int                                # sort within category
  createdAt: timestamp
```

### Prebuilt Catalog Strategy

The 365 items are stored as a **static JSON asset** in the app bundle (`assets/data/homepad_catalog.json`), NOT in Firestore. Only user modifications (status changes, custom items) go to Firestore. This prevents:
- 365 Firestore reads on first load
- Large initial payload
- Excessive bandwidth

**On first access per space:** Client checks if `spaces/{spaceId}/homepad_initialized` exists. If not, the catalog is loaded from the JSON asset and the flag is set. User interactions create Firestore documents only for items that transition away from "available."

### Firestore Security Rules

```
match /spaces/{spaceId}/homepad_items/{itemId} {
  allow read, write: if request.auth.uid in get(/databases/$(database)/documents/spaces/$(spaceId)).data.members;
}
```

### Riverpod Providers

```dart
// Core stream from Firestore (only modified items)
final homePadItemsProvider = StreamProvider.family<List<HomePadItem>, String>(
  (ref, spaceId) => firestoreService.getHomePadItems(spaceId)
);

// Derived: items currently needing purchase
final toBuyItemsProvider = Provider.family<List<HomePadItem>, String>(
  (ref, spaceId) => ref.watch(homePadItemsProvider(spaceId))
      .valueOrNull?.where((i) => i.status == 'to_buy').toList() ?? []
);

// Derived: recently purchased items
final purchasedItemsProvider = Provider.family<List<HomePadItem>, String>(
  (ref, spaceId) => ref.watch(homePadItemsProvider(spaceId))
      .valueOrNull?.where((i) => i.status == 'purchased').toList() ?? []
);

// UI state
final homePadSearchProvider = StateProvider<String>((ref) => '');
final homePadCategoryFilterProvider = StateProvider<String?>((ref) => null);

// Badge count for tab
final homePadBadgeCountProvider = StreamProvider.family<int, String>(
  (ref, spaceId) => /* count of partner-added items since last view */
);
```

### New Files Required

| File | Purpose |
|------|---------|
| `lib/models/homepad_item_model.dart` | Freezed data class |
| `lib/providers/homepad_provider.dart` | Riverpod providers |
| `lib/screens/homepad/homepad_screen.dart` | Main screen |
| `lib/screens/homepad/add_custom_item_sheet.dart` | Bottom sheet |
| `lib/widgets/homepad_item_card.dart` | Item card widget |
| `lib/widgets/homepad_category_section.dart` | Collapsible category |
| `assets/data/homepad_catalog.json` | Prebuilt 365-item catalog |
| `firebase/functions/src/homepad_notifications.ts` | Cloud Function |

### Firestore Service Additions (to `firestore_service.dart`)

- `getHomePadItems(spaceId)` — Stream
- `addHomePadItem(spaceId, item)` — Create
- `updateHomePadItemStatus(spaceId, itemId, status, userId)` — Update
- `batchMarkAllDone(spaceId, userId)` — Batch write
- `deleteHomePadItem(spaceId, itemId)` — Delete custom items

---

## 11. Notification Strategy

### Batched "Items Added" Notifications

**Mechanism:**
1. Client writes to Firestore immediately (real-time sync)
2. Cloud Function `onWrite` trigger detects new "to_buy" items
3. **5-minute debounce** via a `pendingNotification` Firestore doc:
   - First item: create doc with `firstItemAt`, `items: [item1]`, `addedBy`
   - Subsequent items within 5 min by same user: append to `items`
   - Scheduled Cloud Function (every 5 min) sends batch notification, deletes doc
4. **Notification content:**
   - 1 item: "[Name] added Milk to HomePad"
   - 2-3 items: "[Name] added Milk, Eggs, and Bread to HomePad"
   - 4+ items: "[Name] added 7 items to HomePad: Milk, Eggs, Bread..."

### "All Done" Notification

**Trigger:** When last "to_buy" item is marked purchased
**Content:** "[Name] finished the shopping! All items checked off."

### Anti-Fatigue Measures

| Strategy | Implementation |
|----------|---------------|
| Batching | 5-minute window groups rapid additions |
| Respect preferences | Follows existing `notificationPrefs.pushEnabled` |
| Quiet hours | No notifications during configured quiet hours |
| Same-user suppression | Never notify the actor |
| Frequency cap | Max 3 HomePad notifications per day per user |
| No nagging | No "you haven't shopped yet" reminders |
| Actionable | Tap opens HomePad directly |

### Notification Preferences Addition

Sub-toggles under existing push notification master switch:
- **Shopping list updates:** on/off (default: on)
- **Shopping complete:** on/off (default: on)

---

## 12. Accessibility

### Dynamic Type
- All text uses `AppTextStyles` with `GoogleFonts.nunito()` / `GoogleFonts.inter()`
- Card heights use `IntrinsicHeight` (not fixed)
- Category chips grow with larger text; horizontal scroll accommodates

### VoiceOver Labels

| Element | Label | Hint |
|---------|-------|------|
| Item card (to_buy) | "[Item], [category], to buy" | "Swipe left to mark as bought" |
| Checkbox | "Mark [item] as bought" | "Double tap to toggle" |
| Category chip | "[Category] filter, [selected/not]" | "Double tap to filter" |
| Section header | "[Category], [count] items, [state]" | "Double tap to expand/collapse" |
| "Mark All Done" | "Mark all items as bought" | "Double tap for confirmation" |
| Search field | "Search items" | "Type to filter" |

### Color Contrast

| Combination | Ratio | Status |
|-------------|-------|--------|
| Primary text on surface | 7.2:1 | AAA |
| Primary text on gradient | 4.8:1 | AA |
| "All Done" button (adjusted to #3D8B40) | 4.6:1 | AA |
| Secondary text (60% opacity) on surface | 4.6:1 | AA |

**Required fixes:**
- "Mark All Done" button: use #3D8B40 (darker green) for AA contrast
- Category tags: increase from 10sp to 11sp minimum
- Purchased item text: increase from 40% to 50% opacity for AA

### Reduce Motion
- All slide/fade → instant show/hide
- Confetti → static frame
- Haptics still fire
- Chevron rotation still occurs (functional)

---

## 13. Dark Mode

| Element | Light | Dark |
|---------|-------|------|
| Background gradient | #FAFCFC → #E2EAEB | #0A0A0A → #1C1C1E |
| Card background | #FFFFFF | #2C2C2E |
| Primary text | #2F6264 | #E5E5E7 |
| Secondary text | primaryDark @60% | #8E8E93 |
| Left accent bar | #2F6264 | #77B5B3 |
| Category chip (selected) | #2F6264 | #77B5B3 |
| Category chip (unselected) | #E2EAEB | #2C2C2E |
| Dividers | #E0E0E0 | #38383A |
| Search bar fill | #F5F7F8 | #1C1C1E |
| "All Done" button | #4CAF50 | #4CAF50 (unchanged) |
| Error/clear | #D94F4F | #D94F4F (unchanged) |

Uses existing `AppColorsExtension` pattern.

---

## 14. Responsive Layout

### Phone (< 600px) — Primary
- Single column, full-width. Bottom navigation bar with 5 tabs.
- All touch targets 44px+. Bottom sheet for "Add Custom" (~60% screen height).

### Tablet (600-1024px)
- `NavigationRail` on left. Split view: "To Buy" list (40%) + Category browser (60%).
- "Add Custom" as centered modal dialog (400px wide).

### Desktop (> 1024px)
- Side drawer (240px). Three panels: drawer | "To Buy" list | catalog.
- Drag-and-drop from catalog to "To Buy." Inline "Add Custom" form.
- Keyboard shortcuts: `/` search, `Cmd+N` add custom, `Cmd+Shift+D` mark all done.

---

## 15. Risks & Edge Cases

### Technical Risks

| Risk | Mitigation |
|------|------------|
| 365 items = large payload | Static JSON in app bundle, only modifications in Firestore |
| Real-time sync bandwidth | Only stream items in "to_buy"/"purchased" state |
| Notification batching complexity | Dedicated Firestore doc for batching state, 5-min window |
| Data model confusion with tasks | Separate collection (`homepad_items`) with distinct model |

### Product Risks

| Risk | Mitigation |
|------|------------|
| Scope creep into meal planning | Hard boundary: HomePad is shopping only. Icebox meal features. |
| "My items aren't here" frustration | Custom item support in MVP |
| Cultural food differences | Broad cross-cultural list. Regional packs later. |
| Overlap with existing boards | Clear positioning: boards = projects, HomePad = consumables |

### Edge Cases

| Case | Handling |
|------|---------|
| Two people buy same item simultaneously | Last-write-wins. Both see it purchased. |
| "Mark All Done" with 0 items | Button hidden when no "to_buy" items |
| Partner adds items offline, both sync later | Firestore offline queue handles this |
| Space with 1 member | HomePad works solo. No notifications sent. |
| User removes prebuilt item, wants it back | "Hidden items" in settings. Tap to unhide. |
| 50+ custom items | No hard limit; UI virtualizes. Warn at 100+. |

---

## 16. MVP / Thin Slice

### In Slice (Sprint 1-2)

| Feature | Notes |
|---------|-------|
| Prebuilt catalog (365 items, static JSON) | Core value prop |
| Category/subcategory browsing | Collapsible sections |
| Search/filter | Local filtering, instant |
| Tap to mark "To Buy" | Single-tap add |
| Swipe/tap to mark "Purchased" | Consistent with existing Dismissible |
| "Mark All Done" + confirmation + confetti | Key delight moment |
| Add custom items (name + emoji + category) | Bottom sheet |
| Real-time sync | Firestore streams |
| Per-space HomePad | Firestore collection per space |
| "Recently Bought" collapsed section | With re-add and clear |
| Basic push notification on item added | Simple (not batched) |

### Out of Slice (Iterate Later)

| Feature | Sprint |
|---------|--------|
| Batched notifications | Sprint 2 |
| "All Done" notification | Sprint 2 |
| Frequency sorting | Sprint 2 |
| Purchaser/requester attribution | Sprint 2 |
| Recurring auto-resurface | Sprint 3+ |
| Quantity field | Sprint 3+ |
| Frequency override per item | Sprint 3+ |

### MVP User Flow

1. User opens space → taps "HomePad" tab
2. First time: prebuilt catalog loaded from app bundle
3. Browse categories, tap items → items move to "To Buy" at top
4. Partner gets notification: "[Name] added 3 items to HomePad"
5. Partner opens HomePad, sees "To Buy" items
6. Swipes items to mark purchased
7. Taps "Mark All Done" → confetti celebration
8. Both see list reset to empty state

---

## 17. Implementation Plan

### Sprint 1: Core HomePad (MVP)

#### Step 1: Data Layer
- [ ] Create `homepad_item_model.dart` (Freezed)
- [ ] Create `assets/data/homepad_catalog.json` (365 items)
- [ ] Add Firestore methods to `firestore_service.dart`
- [ ] Create `homepad_provider.dart` (Riverpod)
- [ ] Add Firestore security rules for `homepad_items`

#### Step 2: UI — Main Screen
- [ ] Create `homepad_screen.dart` (CustomScrollView layout)
- [ ] Create `homepad_item_card.dart` (with checkbox, emoji, accent bar)
- [ ] Create `homepad_category_section.dart` (collapsible)
- [ ] Implement search bar with real-time filtering
- [ ] Implement category filter chips (horizontal scroll)

#### Step 3: Interactions
- [ ] Tap to mark "To Buy" (with animation + haptic)
- [ ] Swipe-to-complete with Dismissible (matching existing pattern)
- [ ] "Mark All Done" button with confirmation dialog
- [ ] Celebration overlay (reuse existing CelebrationOverlay)
- [ ] Add Custom Item bottom sheet

#### Step 4: Navigation & Polish
- [ ] Add HomePad tab to bottom nav bar
- [ ] Add GoRouter route (`/homepad`)
- [ ] "Recently Bought" section (collapsed, with re-add)
- [ ] Empty states with warm copy
- [ ] Stagger animations (reuse StaggeredListItem)
- [ ] Dark mode support

### Sprint 2: Notifications & Attribution

- [ ] Cloud Function: batched "items added" notification
- [ ] Cloud Function: "all done" notification
- [ ] Notification preferences sub-toggles
- [ ] Badge on HomePad tab
- [ ] Deep-link from notification to HomePad
- [ ] Purchaser/requester avatar on item cards
- [ ] Frequency sorting (weekly first)

### Sprint 3: Advanced Features

- [ ] Recurring item auto-resurface (scheduled Cloud Function)
- [ ] Frequency override per item
- [ ] Quantity field (stepper on item card)
- [ ] Shopping history / analytics

---

> "Ship the smallest thing that helps. We can iterate."
> — PO Bot

> "The board is a mirror, not a manager." HomePad follows the same principle: it reflects what your household needs, without nagging, scoring, or shaming.
