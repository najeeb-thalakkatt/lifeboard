import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lifeboard/models/homepad_item_model.dart';
import 'package:lifeboard/theme/app_colors.dart';

/// A collapsible category section for the HomePad catalog browser.
///
/// Shows a header with emoji + category name + item count + animated chevron.
/// When expanded, displays item rows with add/check toggle.
class HomePadCategorySection extends StatefulWidget {
  const HomePadCategorySection({
    super.key,
    required this.categoryName,
    required this.categoryEmoji,
    required this.items,
    required this.onToggleItem,
    this.initiallyExpanded = false,
  });

  final String categoryName;
  final String categoryEmoji;
  final List<HomePadItem> items;
  final void Function(HomePadItem item) onToggleItem;
  final bool initiallyExpanded;

  @override
  State<HomePadCategorySection> createState() => _HomePadCategorySectionState();
}

class _HomePadCategorySectionState extends State<HomePadCategorySection>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late final AnimationController _chevronController;
  late final Animation<double> _chevronRotation;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _chevronController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: _isExpanded ? 1.0 : 0.0,
    );
    _chevronRotation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _chevronController, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void didUpdateWidget(covariant HomePadCategorySection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto-expand/collapse when initiallyExpanded prop changes (e.g. search active)
    if (widget.initiallyExpanded != oldWidget.initiallyExpanded) {
      _isExpanded = widget.initiallyExpanded;
      if (_isExpanded) {
        _chevronController.forward();
      } else {
        _chevronController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _chevronController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _chevronController.forward();
      } else {
        _chevronController.reverse();
      }
    });
  }

  Widget _buildExpandedContent(
      BuildContext context, Map<String, List<HomePadItem>> subcategoryGroups) {
    final expandedChild = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in subcategoryGroups.entries) ...[
          if (entry.key.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 48, top: 8, bottom: 4),
              child: Text(
                entry.key.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.4),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ...entry.value.map((item) => _CatalogItemRow(
                item: item,
                onTap: () => widget.onToggleItem(item),
              )),
        ],
      ],
    );

    // Skip animation when Reduce Motion is enabled
    if (MediaQuery.of(context).disableAnimations) {
      return _isExpanded ? expandedChild : const SizedBox.shrink();
    }

    return AnimatedCrossFade(
      firstChild: const SizedBox.shrink(),
      secondChild: expandedChild,
      crossFadeState:
          _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Group items by subcategory
    final Map<String, List<HomePadItem>> subcategoryGroups = {};
    for (final item in widget.items) {
      final sub = item.subcategory.isEmpty ? '' : item.subcategory;
      subcategoryGroups.putIfAbsent(sub, () => []).add(item);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        GestureDetector(
          onTap: _toggle,
          behavior: HitTestBehavior.opaque,
          child: Semantics(
            label: '${widget.categoryName}, ${widget.items.length} items, '
                '${_isExpanded ? 'expanded' : 'collapsed'}',
            hint: 'Double tap to ${_isExpanded ? 'collapse' : 'expand'}',
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(widget.categoryEmoji,
                      style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.categoryName,
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Text(
                    '${widget.items.length}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(width: 8),
                  RotationTransition(
                    turns: _chevronRotation,
                    child: Icon(
                      Icons.expand_more,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Expanded content — respect Reduce Motion
        _buildExpandedContent(context, subcategoryGroups),
      ],
    );
  }
}

/// A single item row in the catalog browser.
class _CatalogItemRow extends StatelessWidget {
  const _CatalogItemRow({
    required this.item,
    required this.onTap,
  });

  final HomePadItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isToBuy = item.status == 'to_buy';
    final isPurchased = item.status == 'purchased';
    final opacity = isPurchased ? 0.5 : 1.0;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Opacity(
        opacity: opacity,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const SizedBox(width: 32),
              Text(item.emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.name,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: isToBuy ? FontWeight.w600 : FontWeight.normal,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              Icon(
                isToBuy
                    ? Icons.check_circle
                    : isPurchased
                        ? Icons.check_circle_outline
                        : Icons.add_circle_outline,
                color: isToBuy
                    ? AppColors.statusDone
                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: isPurchased ? 0.2 : 0.4),
                size: 22,
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}
