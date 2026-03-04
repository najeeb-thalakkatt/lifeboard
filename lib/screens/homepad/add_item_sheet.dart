import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lifeboard/models/homepad_item_model.dart';
import 'package:lifeboard/providers/homepad_provider.dart';
import 'package:lifeboard/theme/app_colors.dart';
import 'package:lifeboard/theme/app_text_styles.dart';

/// A unified "Add Item" bottom sheet with search-first flow.
///
/// Flow:
/// 1. User types in search field → live catalog results appear
/// 2. Tap a result → item added to "To Buy" → sheet closes
/// 3. No results → "Can't find it?" CTA → expands custom item form
class AddItemSheet extends ConsumerStatefulWidget {
  const AddItemSheet({super.key, required this.spaceId});

  final String spaceId;

  @override
  ConsumerState<AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends ConsumerState<AddItemSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  // Custom item form state
  bool _showCustomForm = false;
  String _selectedEmoji = '🛒';
  String _selectedCategory = 'Groceries';
  bool _isSaving = false;

  static const _emojiOptions = [
    '🛒', '🍎', '🥦', '🍞', '🥩', '🧀', '🍕', '🍪',
    '🧴', '🧹', '📝', '🏠', '🐾', '👶', '💊', '🔧',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _query = _searchController.text;
        // Reset custom form when search changes
        if (_showCustomForm && _query.isNotEmpty) {
          _showCustomForm = false;
        }
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<HomePadItem> _filterCatalog(List<HomePadItem> allItems) {
    if (_query.isEmpty) return [];
    final q = _query.toLowerCase();
    return allItems
        .where((i) =>
            i.status == 'available' &&
            (i.name.toLowerCase().contains(q) ||
                i.category.toLowerCase().contains(q) ||
                i.subcategory.toLowerCase().contains(q)))
        .toList();
  }

  Future<void> _addCatalogItem(HomePadItem item) async {
    HapticFeedback.lightImpact();
    await ref.read(homePadActionProvider.notifier).markToBuy(
          spaceId: widget.spaceId,
          item: item,
        );
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _saveCustomItem() async {
    final name = _searchController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSaving = true);

    await ref.read(homePadActionProvider.notifier).addCustomItem(
          spaceId: widget.spaceId,
          name: name,
          emoji: _selectedEmoji,
          category: _selectedCategory,
          addToList: true,
        );

    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final mergedAsync = ref.watch(homePadMergedItemsProvider(widget.spaceId));
    final allItems = mergedAsync.valueOrNull ?? [];
    final results = _filterCatalog(allItems);
    final hasQuery = _query.trim().isNotEmpty;
    final hasResults = results.isNotEmpty;

    // Group results by category
    final Map<String, List<HomePadItem>> grouped = {};
    for (final item in results) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Add Item', style: AppTextStyles.headingSmall),
              ),
            ),
            const SizedBox(height: 12),

            // Search field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'Search or type item name...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: hasQuery
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _showCustomForm = false);
                          },
                        )
                      : null,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Results / Custom form
            if (_showCustomForm)
              _buildCustomForm()
            else if (hasQuery && hasResults)
              _buildSearchResults(grouped)
            else if (hasQuery && !hasResults)
              _buildNoResults()
            else
              _buildHint(),
          ],
        ),
      ),
    );
  }

  /// Hint shown before user types anything
  Widget _buildHint() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Text(
        'Start typing to search the catalog...',
        style: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.primaryDark.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  /// Live search results grouped by category
  Widget _buildSearchResults(Map<String, List<HomePadItem>> grouped) {
    return Flexible(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          for (final entry in grouped.entries) ...[
            // Category header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
              child: Text(
                '${homePadCategories[entry.key] ?? "📦"} ${entry.key}',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark.withValues(alpha: 0.6),
                ),
              ),
            ),
            // Items
            ...entry.value.map(_buildResultRow),
          ],

          // "Can't find it?" at the bottom of results
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: _buildAddCustomCTA(),
          ),
        ],
      ),
    );
  }

  /// Single result row
  Widget _buildResultRow(HomePadItem item) {
    return GestureDetector(
      onTap: () => _addCatalogItem(item),
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            Text(item.emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.name,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
            Icon(
              Icons.add_circle_outline,
              color: AppColors.primaryDark.withValues(alpha: 0.4),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  /// No results state with CTA to add custom item
  Widget _buildNoResults() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔍', style: TextStyle(fontSize: 32)),
          const SizedBox(height: 8),
          Text(
            'No items found for "$_query"',
            style: GoogleFonts.nunito(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          _buildAddCustomCTA(),
        ],
      ),
    );
  }

  /// "Can't find it? Add custom item" button
  Widget _buildAddCustomCTA() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          HapticFeedback.selectionClick();
          setState(() => _showCustomForm = true);
        },
        icon: const Icon(Icons.add, size: 18),
        label: Text(
          'Add "${_query.trim()}" as custom item',
          style: GoogleFonts.inter(fontSize: 13),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  /// Custom item form (emoji + category + save)
  Widget _buildCustomForm() {
    return Flexible(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Info text
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryDark.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      size: 18, color: AppColors.primaryDark),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Adding "${_searchController.text.trim()}" as a custom item',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Emoji picker
            Text('Emoji',
                style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _emojiOptions.map((emoji) {
                final isSelected = emoji == _selectedEmoji;
                return GestureDetector(
                  onTap: () => setState(() => _selectedEmoji = emoji),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryDark.withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected
                          ? Border.all(color: AppColors.primaryDark, width: 2)
                          : Border.all(color: Colors.grey.shade300, width: 1),
                    ),
                    alignment: Alignment.center,
                    child: Text(emoji, style: const TextStyle(fontSize: 20)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Category dropdown
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(labelText: 'Category'),
              items: homePadCategories.entries.map((e) {
                return DropdownMenuItem(
                  value: e.key,
                  child: Text('${e.value} ${e.key}'),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedCategory = val);
              },
            ),
            const SizedBox(height: 20),

            // Save button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isSaving ? null : _saveCustomItem,
                icon: _isSaving ? null : const Icon(Icons.add, size: 18),
                label: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Add to Shopping List'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
