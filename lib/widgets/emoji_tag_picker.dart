import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:lifeboard/core/constants.dart';
import 'package:lifeboard/theme/app_colors.dart';
import 'package:lifeboard/theme/app_text_styles.dart';

/// Compact horizontal scrollable emoji tag picker.
///
/// Displays emoji tags as circular buttons in a single row.
/// The selected emoji gets a teal ring + tint. Label shown below only for selected.
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
    final colors = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppColorsExtension>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: AppConstants.emojiTags.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final emoji = AppConstants.emojiTags[i];
              final isSelected = emoji == selected;
              return Semantics(
                label: '${_labels[emoji] ?? ''} tag',
                selected: isSelected,
                button: true,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onSelected(isSelected ? null : emoji);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? colors.primary.withValues(alpha: 0.12)
                          : colors.surface,
                      border: Border.all(
                        color: isSelected ? colors.primary : ext.divider,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 22)),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (selected != null && _labels[selected] != null) ...[
          const SizedBox(height: 6),
          Text(
            _labels[selected]!,
            style: AppTextStyles.caption.copyWith(
              color: colors.onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}
