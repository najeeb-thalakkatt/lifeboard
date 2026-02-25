import 'package:flutter/material.dart';

import 'package:lifeboard/core/constants.dart';
import 'package:lifeboard/theme/app_colors.dart';
import 'package:lifeboard/theme/app_text_styles.dart';

/// Grid picker for emoji tags on a task.
///
/// Displays a grid of predefined emoji options. The currently selected
/// emoji is highlighted. Tapping an already-selected emoji deselects it.
class EmojiTagPicker extends StatelessWidget {
  const EmojiTagPicker({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  /// Currently selected emoji (null if none).
  final String? selected;

  /// Called with the new emoji, or null to clear selection.
  final ValueChanged<String?> onSelected;

  /// Labels for each emoji tag category.
  static const _labels = {
    '\u{1F4B0}': 'Finances',
    '\u{1F3E1}': 'Home',
    '\u{2764}\u{FE0F}': 'Relationship',
    '\u{1F9E0}': 'Growth',
    '\u{1F4AA}': 'Health',
    '\u{2600}\u{FE0F}': 'Fun',
  };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: AppConstants.emojiTags.map((emoji) {
        final isSelected = emoji == selected;
        return GestureDetector(
          onTap: () => onSelected(isSelected ? null : emoji),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primaryDark.withValues(alpha: 0.12)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.primaryDark : AppColors.divider,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(height: 2),
                Text(
                  _labels[emoji] ?? '',
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 10,
                    color: isSelected
                        ? AppColors.primaryDark
                        : AppColors.primaryDark.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
