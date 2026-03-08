import 'dart:async';

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
import 'package:lifeboard/widgets/app_shell_bar.dart';
import 'package:lifeboard/widgets/celebration_overlay.dart';
import 'package:lifeboard/widgets/homepad_category_section.dart';
import 'package:lifeboard/widgets/homepad_item_card.dart';
import 'package:lifeboard/widgets/stagger_animation.dart';

/// Standalone buy list screen — one of the 3 main tabs.
class BuyListScreen extends ConsumerWidget {
  const BuyListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spaceId = ref.watch(selectedSpaceProvider);

    if (spaceId == null) {
      return const Scaffold(
        appBar: AppShellBar(currentTab: AppTab.buylist),
        body: Center(
          child: Text('Join or create a space to use Buy List'),
        ),
      );
    }

    return _BuyListContent(spaceId: spaceId);
  }
}

class _BuyListContent extends ConsumerStatefulWidget {
  const _BuyListContent({required this.spaceId});
  final String spaceId;

  @override
  ConsumerState<_BuyListContent> createState() => _BuyListContentState();
}

class _BuyListContentState extends ConsumerState<_BuyListContent> {
  final _searchController = TextEditingController();
  bool _recentlyBoughtExpanded = false;

  String get spaceId => widget.spaceId;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final current = ref.read(homePadSearchProvider);
      if (current != _searchController.text) {
        ref.read(homePadSearchProvider.notifier).state =
            _searchController.text;
      }
    });
  }

  @override
  void deactivate() {
    final searchNotifier = ref.read(homePadSearchProvider.notifier);
    final categoryNotifier = ref.read(homePadCategoryFilterProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      searchNotifier.state = '';
      categoryNotifier.state = null;
    });
    super.deactivate();
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
    final memberProfiles = ref.watch(spaceMemberProfilesProvider(spaceId));

    return Scaffold(
      appBar: const AppShellBar(currentTab: AppTab.buylist),
      body: mergedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (allItems) {
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
          if (categoryFilter != null) {
            filteredItems = filteredItems
                .where((i) => i.category == categoryFilter)
                .toList();
          }

          final toBuyItems =
              filteredItems.where((i) => i.status == 'to_buy').toList()
                ..sort((a, b) {
                  const freqOrder = {
                    'weekly': 0,
                    'biweekly': 1,
                    'monthly': 2,
                    'as_needed': 3,
                  };
                  final aFreq = freqOrder[a.frequency] ?? 3;
                  final bFreq = freqOrder[b.frequency] ?? 3;
                  if (aFreq != bFreq) return aFreq.compareTo(bFreq);
                  return a.name.compareTo(b.name);
                });
          final purchasedItems =
              filteredItems.where((i) => i.status == 'purchased').toList()
                ..sort((a, b) {
                  final aTime = a.purchasedAt ?? DateTime(2000);
                  final bTime = b.purchasedAt ?? DateTime(2000);
                  return bTime.compareTo(aTime);
                });
          final catalogItems =
              filteredItems.where((i) => i.status == 'available').toList();

          final Map<String, List<HomePadItem>> categorized = {};
          for (final item in catalogItems) {
            categorized.putIfAbsent(item.category, () => []).add(item);
          }

          return CustomScrollView(
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: _PinnedSearchBarDelegate(
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
              ),

              if (toBuyItems.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Container(
                    height: 48,
                    margin: const EdgeInsets.only(
                        left: 16, right: 16, top: 16, bottom: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '${toBuyItems.length} ${toBuyItems.length == 1 ? 'item' : 'items'} to buy',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const Spacer(),
                        Semantics(
                          label: 'Mark all items as bought',
                          button: true,
                          child: Builder(
                            builder: (context) {
                              final isDark = Theme.of(context).brightness ==
                                  Brightness.dark;
                              return Material(
                                color: isDark
                                    ? AppColors.statusDone
                                        .withValues(alpha: 0.15)
                                    : AppColors.statusDone,
                                borderRadius: BorderRadius.circular(18),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(18),
                                  onTap: () =>
                                      _markAllDone(context, ref, spaceId),
                                  child: Container(
                                    height: 36,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'All Done!',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? AppColors.statusDone
                                            : Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                ..._buildCategoryGroupedToBuy(
                    context, ref, toBuyItems, memberProfiles),
              ],

              if (toBuyItems.isEmpty &&
                  purchasedItems.isEmpty &&
                  searchQuery.isEmpty &&
                  categoryFilter == null)
                SliverToBoxAdapter(
                  child: _EmptyState(
                    onBrowse: () {
                      showModalBottomSheet<bool>(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (_) => AddItemSheet(spaceId: spaceId),
                      ).then((added) {
                        if (added == true) _clearSearchAndFilters();
                      });
                    },
                  ),
                ),

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
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try a different search or tap + to add a custom item',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

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
                    onClear: () => _clearPurchased(context, ref, spaceId),
                  ),
                ),
                if (_recentlyBoughtExpanded)
                  ..._buildDateGroupedPurchased(
                      context, ref, purchasedItems, memberProfiles),
              ],

              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.only(left: 16, top: 24, bottom: 8),
                  child: Text(
                    'Browse Items',
                    style: GoogleFonts.nunito(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final category = categorized.keys.toList()[index];
                    final items = categorized[category]!;
                    final emoji = homePadCategories[category] ?? '📦';
                    return HomePadCategorySection(
                      categoryName: category,
                      categoryEmoji: emoji,
                      items: items,
                      initiallyExpanded: isSearchActive,
                      onToggleItem: (item) {
                        if (item.status == 'available') {
                          ref
                              .read(homePadActionProvider.notifier)
                              .markToBuy(spaceId: spaceId, item: item);
                          FocusScope.of(context).unfocus();
                          if (isSearchActive) _clearSearchAndFilters();
                          unawaited(HapticFeedback.lightImpact());
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

              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          );
        },
      ),
      floatingActionButton: Builder(
        builder: (context) {
          final fab = FloatingActionButton(
            onPressed: () => _showAddItemSheet(context),
            tooltip: 'Add item',
            child: const Icon(Icons.add),
          );
          if (Theme.of(context).brightness == Brightness.dark) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.darkPrimary.withValues(alpha: 0.3),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: fab,
            );
          }
          return fab;
        },
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
      if (added == true) _clearSearchAndFilters();
    });
  }

  List<Widget> _buildCategoryGroupedToBuy(
    BuildContext context,
    WidgetRef ref,
    List<HomePadItem> toBuyItems,
    Map<String, String> memberProfiles,
  ) {
    final Map<String, List<HomePadItem>> grouped = {};
    for (final item in toBuyItems) {
      final cat = item.category.isEmpty ? 'Other' : item.category;
      grouped.putIfAbsent(cat, () => []).add(item);
    }

    final slivers = <Widget>[];
    var staggerIndex = 0;

    for (final entry in grouped.entries) {
      slivers.add(SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(left: 20, top: 12, bottom: 4),
          child: Text(
            entry.key.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.45),
              letterSpacing: 0.5,
            ),
          ),
        ),
      ));

      final categoryItems = entry.value;
      final startIndex = staggerIndex;
      slivers.add(SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = categoryItems[index];
            return StaggeredListItem(
              index: startIndex + index,
              child: HomePadItemCard(
                item: item,
                addedByName: item.addedBy != null
                    ? memberProfiles[item.addedBy]
                    : null,
                onTogglePurchased: () {
                  _markPurchasedWithUndo(context, ref, item);
                },
                onDismissed: () {
                  _markPurchasedWithUndo(context, ref, item);
                },
              ),
            );
          },
          childCount: categoryItems.length,
        ),
      ));
      staggerIndex += categoryItems.length;
    }

    return slivers;
  }

  static String _dateGroupLabel(DateTime? purchasedAt) {
    if (purchasedAt == null) return 'Earlier';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekAgo = today.subtract(const Duration(days: 7));
    final date =
        DateTime(purchasedAt.year, purchasedAt.month, purchasedAt.day);

    if (date == today || date.isAfter(today)) return 'Today';
    if (date == yesterday) return 'Yesterday';
    if (date.isAfter(weekAgo)) return 'This Week';
    return 'Earlier';
  }

  List<Widget> _buildDateGroupedPurchased(
    BuildContext context,
    WidgetRef ref,
    List<HomePadItem> purchasedItems,
    Map<String, String> memberProfiles,
  ) {
    final Map<String, List<HomePadItem>> grouped = {};
    for (final item in purchasedItems) {
      final label = _dateGroupLabel(item.purchasedAt);
      grouped.putIfAbsent(label, () => []).add(item);
    }

    final slivers = <Widget>[];

    for (final entry in grouped.entries) {
      slivers.add(SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(left: 20, top: 12, bottom: 4),
          child: Text(
            entry.key,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.45),
              letterSpacing: 0.5,
            ),
          ),
        ),
      ));

      slivers.add(SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = entry.value[index];
            return HomePadItemCard(
              item: item,
              purchasedByName: item.purchasedBy != null
                  ? memberProfiles[item.purchasedBy]
                  : null,
              dismissLabel: 'Remove',
              dismissColor: Colors.orange.shade700,
              dismissIcon: Icons.remove_circle_outline,
              onTogglePurchased: () {
                ref.read(homePadActionProvider.notifier).reAddToBuy(
                      spaceId: spaceId,
                      itemId: item.id,
                    );
              },
              onDismissed: () {
                ref.read(homePadActionProvider.notifier).markAvailable(
                      spaceId: spaceId,
                      itemId: item.id,
                      isCustom: item.isCustom,
                    );
              },
            );
          },
          childCount: entry.value.length,
        ),
      ));
    }

    return slivers;
  }

  void _markPurchasedWithUndo(
      BuildContext context, WidgetRef ref, HomePadItem item) {
    ref
        .read(homePadActionProvider.notifier)
        .markPurchased(spaceId: spaceId, itemId: item.id);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.emoji} ${item.name} marked as bought'),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            ref
                .read(homePadActionProvider.notifier)
                .reAddToBuy(spaceId: spaceId, itemId: item.id);
          },
        ),
      ),
    );
  }

  Future<void> _markAllDone(
      BuildContext context, WidgetRef ref, String spaceId) async {
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
        unawaited(HapticFeedback.heavyImpact());
        CelebrationOverlay.show(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Everything's done! Great teamwork! 🎉"),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _clearPurchased(
      BuildContext context, WidgetRef ref, String spaceId) async {
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
      child: Semantics(
        label: '$label category filter${isSelected ? ', selected' : ''}',
        button: true,
        child: GestureDetector(
          onTap: () {
            unawaited(HapticFeedback.selectionClick());
            onTap();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withValues(
                        alpha: Theme.of(context).brightness == Brightness.dark
                            ? 0.12
                            : 0.06,
                      ),
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
                    color: isSelected
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Empty State ──────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({this.onBrowse});

  final VoidCallback? onBrowse;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🎉', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text(
            'All done for now!',
            style: AppTextStyles.headingSmall.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Browse below to add what you need',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(
                    alpha: Theme.of(context).brightness == Brightness.dark
                        ? 0.7
                        : 0.6,
                  ),
            ),
            textAlign: TextAlign.center,
          ),
          if (onBrowse != null) ...[
            const SizedBox(height: 20),
            FilledButton.tonal(
              onPressed: onBrowse,
              child: const Text('Browse Items'),
            ),
          ],
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
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$count',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.4),
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: onClear,
              child: Text(
                'Clear',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
            AnimatedRotation(
              turns: isExpanded ? 0.5 : 0.0,
              duration: MediaQuery.of(context).disableAnimations
                  ? Duration.zero
                  : const Duration(milliseconds: 200),
              child: Icon(
                Icons.expand_more,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Pinned Search Bar Delegate ──────────────────────────────────────

class _PinnedSearchBarDelegate extends SliverPersistentHeaderDelegate {
  const _PinnedSearchBarDelegate({required this.child});

  final Widget child;

  @override
  double get minExtent => 124;

  @override
  double get maxExtent => 124;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: overlapsContent ? 2 : 0,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _PinnedSearchBarDelegate oldDelegate) =>
      child != oldDelegate.child;
}
