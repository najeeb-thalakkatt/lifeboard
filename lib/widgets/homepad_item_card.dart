import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lifeboard/models/homepad_item_model.dart';
import 'package:lifeboard/theme/app_colors.dart';

/// A card representing a single HomePad item in the "To Buy" section.
///
/// Includes a checkbox, emoji, item name, frequency badge, and category tag.
/// Supports swipe-to-complete via wrapping in a [Dismissible].
class HomePadItemCard extends StatelessWidget {
  const HomePadItemCard({
    super.key,
    required this.item,
    required this.onTogglePurchased,
    required this.onDismissed,
    this.dismissLabel,
    this.dismissColor,
    this.dismissIcon,
  });

  final HomePadItem item;
  final VoidCallback onTogglePurchased;
  final VoidCallback onDismissed;
  final String? dismissLabel;
  final Color? dismissColor;
  final IconData? dismissIcon;

  String _frequencyLabel(String frequency) {
    switch (frequency) {
      case 'weekly':
        return 'Weekly';
      case 'biweekly':
        return 'Biweekly';
      case 'monthly':
        return 'Monthly';
      case 'as_needed':
      default:
        return 'As needed';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPurchased = item.status == 'purchased';

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        HapticFeedback.mediumImpact();
        onDismissed();
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: dismissColor ?? AppColors.statusDone,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              dismissLabel ?? 'Done',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 8),
            Icon(dismissIcon ?? Icons.check, color: Colors.white),
          ],
        ),
      ),
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Left accent bar
              Container(
                width: 3,
                decoration: BoxDecoration(
                  color: isPurchased
                      ? AppColors.statusDone
                      : AppColors.primaryDark,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    bottomLeft: Radius.circular(10),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Checkbox
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onTogglePurchased();
                },
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isPurchased
                            ? AppColors.statusDone
                            : Colors.transparent,
                        border: Border.all(
                          color: isPurchased
                              ? AppColors.statusDone
                              : AppColors.primaryDark.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: isPurchased
                          ? const Icon(Icons.check,
                              size: 14, color: Colors.white)
                          : null,
                    ),
                  ),
                ),
              ),

              // Emoji
              Text(item.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),

              // Item name
              Expanded(
                child: Text(
                  item.name,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isPurchased
                        ? AppColors.primaryDark.withValues(alpha: 0.4)
                        : AppColors.primaryDark,
                    decoration:
                        isPurchased ? TextDecoration.lineThrough : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),

              // Frequency badge
              if (!isPurchased && item.frequency != 'as_needed')
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accentWarm.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _frequencyLabel(item.frequency),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AppColors.accentWarm,
                    ),
                  ),
                ),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }
}
