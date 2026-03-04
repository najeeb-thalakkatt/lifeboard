import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lifeboard/providers/homepad_provider.dart';
import 'package:lifeboard/theme/app_colors.dart';
import 'package:lifeboard/theme/app_text_styles.dart';

/// Bottom sheet for adding a custom HomePad item.
class AddCustomItemSheet extends ConsumerStatefulWidget {
  const AddCustomItemSheet({super.key, required this.spaceId});

  final String spaceId;

  @override
  ConsumerState<AddCustomItemSheet> createState() => _AddCustomItemSheetState();
}

class _AddCustomItemSheetState extends ConsumerState<AddCustomItemSheet> {
  final _nameController = TextEditingController();
  String _selectedEmoji = '🛒';
  String _selectedCategory = 'Groceries';
  bool _addToList = true;
  bool _isSaving = false;

  static const _emojiOptions = [
    '🛒', '🍎', '🥦', '🍞', '🥩', '🧀', '🍕', '🍪',
    '🧴', '🧹', '📝', '🏠', '🐾', '👶', '💊', '🔧',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSaving = true);

    await ref.read(homePadActionProvider.notifier).addCustomItem(
          spaceId: widget.spaceId,
          name: name,
          emoji: _selectedEmoji,
          category: _selectedCategory,
          addToList: _addToList,
        );

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text('Add Custom Item', style: AppTextStyles.headingSmall),
            const SizedBox(height: 16),

            // Name field
            TextField(
              controller: _nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Item Name',
                hintText: 'e.g. Almond Butter',
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
                          : Border.all(
                              color: Colors.grey.shade300, width: 1),
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
              initialValue: _selectedCategory,
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
            const SizedBox(height: 16),

            // Add to shopping list toggle
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text('Add to shopping list',
                  style: GoogleFonts.inter(fontSize: 14)),
              subtitle: Text('Mark as "To Buy" immediately',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: Colors.grey.shade600)),
              value: _addToList,
              onChanged: (val) => setState(() => _addToList = val),
              activeTrackColor: AppColors.primaryDark,
            ),
            const SizedBox(height: 16),

            // Save button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Add Item'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
