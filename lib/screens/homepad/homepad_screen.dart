import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lifeboard/models/homepad_item_model.dart';
import 'package:lifeboard/providers/homepad_provider.dart';
import 'package:lifeboard/providers/space_provider.dart';
import 'package:lifeboard/screens/homepad/add_item_sheet.dart';
import 'package:lifeboard/theme/app_colors.dart';
import 'package:lifeboard/theme/app_text_styles.dart';
import 'package:lifeboard/widgets/celebration_overlay.dart';
import 'package:lifeboard/widgets/homepad_category_section.dart';
import 'package:lifeboard/widgets/homepad_item_card.dart';
import 'package:lifeboard/widgets/stagger_animation.dart';

/// The main HomePad shopping list screen.
///
/// Layout:
/// 1. Search bar + category filter chips
/// 2. "To Buy" section (active shopping list)
/// 3. "Recently Bought" section (collapsible)
/// 4. Browse catalog by category (collapsible sections)
class HomePadScreen extends ConsumerWidget {
  const HomePadScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacesAsync = ref.watch(userSpacesProvider);
    final spaceId = spacesAsync.valueOrNull?.firstOrNull?.id;

    if (spaceId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('HomePad')),
        body: const Center(
          child: Text('Join or create a space to use HomePad'),
        ),
      );
    }

    return _HomePadContent(spaceId: spaceId);
  }
}

class _HomePadContent extends ConsumerStatefulWidget {
  const _HomePadContent({required this.spaceId});
  final String spaceId;

  @override
  ConsumerState<_HomePadContent> createState() => _HomePadContentState();
}

class _HomePadContentState extends ConsumerState<_HomePadContent> {
  final _searchController = TextEditingController();
  bool _recentlyBoughtExpanded = false;

  String get spaceId => widget.spaceId;

  @override
  void initState() {
    super.initState();
    // Sync controller with provider
    _searchController.addListener(() {
      final current = ref.read(homePadSearchProvider);
      if (current != _searchController.text) {
        ref.read(homePadSearchProvider.notifier).state = _searchController.text;
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearchAndFilters() {
    _searchController.clear();
    ref.read(homePadSearchProvider.notifier).state = '';
    ref.read(homePadCategoryFilterProvider.notifier).state = null;
  }

  @override
  Widget build(BuildContext context) {
    final mergedAsync = ref.watch(homePadMergedItemsProvider(spaceId));
    final searchQuery = ref.watch(homePadSearchProvider);
    final categoryFilter = ref.watch(homePadCategoryFilterProvider);
    final isSearchActive = searchQuery.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text('HomePad 🛒', style: AppTextStyles.headingSmall),
      ),
      body: mergedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (allItems) {
          // Apply search filter
          var filteredItems = allItems;
          if (searchQuery.isNotEmpty) {
            final query = searchQuery.toLowerCase();
            filteredItems = filteredItems
                .where((i) =>
                    i.name.toLowerCase().contains(query) ||
                    i.category.toLowerCase().contains(query) ||
                    i.subcategory.toLowerCase().contains(query))
                .toList();
          }
          // Apply category filter
          if (categoryFilter != null) {
            filteredItems = filteredItems
                .where((i) => i.category == categoryFilter)
                .toList();
          }

          final toBuyItems =
              filteredItems.where((i) => i.status == 'to_buy').toList();
          final purchasedItems =
              filteredItems.where((i) => i.status == 'purchased').toList()
                ..sort((a, b) {
                  final aTime = a.purchasedAt ?? DateTime(2000);
                  final bTime = b.purchasedAt ?? DateTime(2000);
                  return bTime.compareTo(aTime);
                });
          final catalogItems =
              filteredItems.where((i) => i.status == 'available').toList();

          // Group catalog items by category
          final Map<String, List<HomePadItem>> categorized = {};
          for (final item in catalogItems) {
            categorized.putIfAbsent(item.category, () => []).add(item);
          }

          return CustomScrollView(
            slivers: [
              // ── Search & Filter Bar ────────────────────────────
              SliverToBoxAdapter(
                child: _SearchAndFilterBar(
                  searchQuery: searchQuery,
                  searchController: _searchController,
                  categoryFilter: categoryFilter,
                  onSearchChanged: (val) =>
                      ref.read(homePadSearchProvider.notifier).state = val,
                  onCategoryChanged: (val) =>
                      ref.read(homePadCategoryFilterProvider.notifier).state =
                          val,
                ),
              ),

              // ── "To Buy" Section ───────────────────────────────
              if (toBuyItems.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.only(left: 16, top: 16, bottom: 4),
                    child: Row(
                      children: [
                        Text(
                          'To Buy',
                          style: GoogleFonts.nunito(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accentWarm,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${toBuyItems.length}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () =>
                              _markAllDone(context, spaceId),
                          icon: const Icon(Icons.check_circle_outline,
                              size: 18),
                          label: Text(
                            'Mark All Done',
                            style: GoogleFonts.inter(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = toBuyItems[index];
                      return StaggeredListItem(
                        index: index,
                        child: HomePadItemCard(
                          item: item,
                          onTogglePurchased: () {
                            ref
                                .read(homePadActionProvider.notifier)
                                .markPurchased(
                                  spaceId: spaceId,
                                  itemId: item.id,
                                );
                          },
                          onDismissed: () {
                            ref
                                .read(homePadActionProvider.notifier)
                                .markPurchased(
                                  spaceId: spaceId,
                                  itemId: item.id,
                                );
                          },
                        ),
                      );
                    },
                    childCount: toBuyItems.length,
                  ),
                ),
              ],

              // ── Empty State ────────────────────────────────────
              if (toBuyItems.isEmpty &&
                  purchasedItems.isEmpty &&
                  searchQuery.isEmpty &&
                  categoryFilter == null)
                const SliverToBoxAdapter(
                  child: _EmptyState(),
                ),

              // ── Search No Results State ─────────────────────────
              if (isSearchActive &&
                  toBuyItems.isEmpty &&
                  catalogItems.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 48),
                    child: Column(
                      children: [
                        const Text('🔍', style: TextStyle(fontSize: 40)),
                        const SizedBox(height: 12),
                        Text(
                          'No items found for "$searchQuery"',
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try a different search or tap + to add a custom item',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.primaryDark
                                .withValues(alpha: 0.6),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

              // ── "Recently Bought" Section ──────────────────────
              if (purchasedItems.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: _RecentlyBoughtHeader(
                    count: purchasedItems.length,
                    isExpanded: _recentlyBoughtExpanded,
                    onToggleExpanded: () {
                      setState(() {
                        _recentlyBoughtExpanded = !_recentlyBoughtExpanded;
                      });
                    },
                    onClear: () => _clearPurchased(context, spaceId),
                  ),
                ),
                if (_recentlyBoughtExpanded)
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = purchasedItems[index];
                        return HomePadItemCard(
                          item: item,
                          onTogglePurchased: () {
                            ref
                                .read(homePadActionProvider.notifier)
                                .reAddToBuy(
                                  spaceId: spaceId,
                                  itemId: item.id,
                                );
                          },
                          onDismissed: () {
                            ref
                                .read(homePadActionProvider.notifier)
                                .markAvailable(
                                  spaceId: spaceId,
                                  itemId: item.id,
                                  isCustom: item.isCustom,
                                );
                          },
                        );
                      },
                      childCount: purchasedItems.length,
                    ),
                  ),
              ],

              // ── Browse Catalog Section ─────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.only(left: 16, top: 24, bottom: 8),
                  child: Text(
                    'Browse Items',
                    style: GoogleFonts.nunito(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final category =
                        categorized.keys.toList()[index];
                    final items = categorized[category]!;
                    final emoji =
                        homePadCategories[category] ?? '📦';
                    return HomePadCategorySection(
                      categoryName: category,
                      categoryEmoji: emoji,
                      items: items,
                      initiallyExpanded: isSearchActive,
                      onToggleItem: (item) {
                        if (item.status == 'available') {
                          ref
                              .read(homePadActionProvider.notifier)
                              .markToBuy(
                                spaceId: spaceId,
                                item: item,
                              );
                          // Dismiss keyboard, clear search and return to main list
                          FocusScope.of(context).unfocus();
                          if (isSearchActive) {
                            _clearSearchAndFilters();
                          }
                          HapticFeedback.lightImpact();
                        } else if (item.status == 'to_buy') {
                          ref
                              .read(homePadActionProvider.notifier)
                              .markAvailable(
                                spaceId: spaceId,
                                itemId: item.id,
                                isCustom: item.isCustom,
                              );
                        }
                      },
                    );
                  },
                  childCount: categorized.length,
                ),
              ),

              // Bottom padding
              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddItemSheet(context),
        tooltip: 'Add item',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddItemSheet(BuildContext context) {
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AddItemSheet(spaceId: spaceId),
    ).then((added) {
      // Clear search so user sees the main list with newly added item
      if (added == true) {
        _clearSearchAndFilters();
      }
    });
  }

  Future<void> _markAllDone(
      BuildContext context, String spaceId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark All Done?'),
        content: const Text(
            'All items in your shopping list will be marked as purchased.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Done!'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final count = await ref
          .read(homePadActionProvider.notifier)
          .markAllDone(spaceId: spaceId);
      if (count > 0 && context.mounted) {
        HapticFeedback.heavyImpact();
        CelebrationOverlay.show(context);
      }
    }
  }

  Future<void> _clearPurchased(
      BuildContext context, String spaceId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Purchased?'),
        content: const Text(
            'All purchased items will be reset back to available.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(homePadActionProvider.notifier)
          .clearPurchased(spaceId: spaceId);
    }
  }
}

// ── Search & Filter Bar ──────────────────────────────────────────────

class _SearchAndFilterBar extends StatelessWidget {
  const _SearchAndFilterBar({
    required this.searchQuery,
    required this.searchController,
    required this.categoryFilter,
    required this.onSearchChanged,
    required this.onCategoryChanged,
  });

  final String searchQuery;
  final TextEditingController searchController;
  final String? categoryFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onCategoryChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Search items...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        searchController.clear();
                        onSearchChanged('');
                      },
                    )
                  : null,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),

          // Category chips
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _FilterChip(
                  label: 'All',
                  emoji: '🏠',
                  isSelected: categoryFilter == null,
                  onTap: () => onCategoryChanged(null),
                ),
                ...homePadCategories.entries.map((e) {
                  return _FilterChip(
                    label: e.key,
                    emoji: e.value,
                    isSelected: categoryFilter == e.key,
                    onTap: () => onCategoryChanged(
                        categoryFilter == e.key ? null : e.key),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Filter Chip ──────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.emoji,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String emoji;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryDark
                : AppColors.primaryDark.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(18),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.primaryDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Empty State ──────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🛒', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text(
            'Your shopping list is empty',
            style: AppTextStyles.headingSmall.copyWith(
              color: AppColors.primaryDark,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to search and add items, or browse the catalog below!',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.primaryDark.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Recently Bought Header ───────────────────────────────────────────

class _RecentlyBoughtHeader extends StatelessWidget {
  const _RecentlyBoughtHeader({
    required this.count,
    required this.isExpanded,
    required this.onToggleExpanded,
    required this.onClear,
  });

  final int count;
  final bool isExpanded;
  final VoidCallback onToggleExpanded;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggleExpanded,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(left: 16, top: 20, right: 8),
        child: Row(
          children: [
            Text(
              'Recently Bought',
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDark.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$count',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.primaryDark.withValues(alpha: 0.4),
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: onClear,
              child: Text(
                'Clear',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.primaryDark.withValues(alpha: 0.5),
                ),
              ),
            ),
            AnimatedRotation(
              turns: isExpanded ? 0.5 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.expand_more,
                color: AppColors.primaryDark.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
