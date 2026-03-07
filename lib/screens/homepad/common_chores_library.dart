import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lifeboard/providers/chore_provider.dart';
import 'package:lifeboard/theme/app_text_styles.dart';

/// Bottom sheet for picking common chores from a pre-built catalog.
/// Supports multi-select and bulk-add.
class CommonChoresLibrary extends ConsumerStatefulWidget {
  const CommonChoresLibrary({super.key, required this.spaceId});
  final String spaceId;

  @override
  ConsumerState<CommonChoresLibrary> createState() =>
      _CommonChoresLibraryState();
}

class _CommonChoresLibraryState extends ConsumerState<CommonChoresLibrary> {
  final Set<String> _selected = {};
  bool _saving = false;

  String _choreKey(Map<String, dynamic> chore) =>
      '${chore['emoji']}_${chore['name']}';

  Future<void> _addSelected(List<Map<String, dynamic>> categories) async {
    if (_selected.isEmpty) return;
    setState(() => _saving = true);

    final choreDefs = <Map<String, dynamic>>[];
    for (final cat in categories) {
      for (final chore in (cat['chores'] as List<dynamic>)) {
        final c = chore as Map<String, dynamic>;
        if (_selected.contains(_choreKey(c))) {
          choreDefs.add(c);
        }
      }
    }

    await ref.read(choreActionProvider.notifier).bulkAddChores(
          spaceId: widget.spaceId,
          choreDefs: choreDefs,
        );

    if (mounted) {
      HapticFeedback.mediumImpact();
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final categoriesAsync = ref.watch(commonChoresCategoriesProvider);
    final categories = categoriesAsync.valueOrNull ?? [];
    final isLoading = categoriesAsync.isLoading;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
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
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Text('Common Chores', style: AppTextStyles.headingSmall),
                  const Spacer(),
                  if (_selected.isNotEmpty)
                    Text(
                      '${_selected.length} selected',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Tap to select, then add them all at once',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Content
            if (isLoading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: categories.length,
                  itemBuilder: (context, catIndex) {
                    final cat = categories[catIndex];
                    final chores = cat['chores'] as List<dynamic>;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 12, 24, 6),
                          child: Row(
                            children: [
                              Text(cat['emoji'] as String,
                                  style: const TextStyle(fontSize: 16)),
                              const SizedBox(width: 8),
                              Text(
                                cat['category'] as String,
                                style: GoogleFonts.nunito(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: chores.map((chore) {
                              final c = chore as Map<String, dynamic>;
                              final key = _choreKey(c);
                              final isSelected = _selected.contains(key);
                              return GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    if (isSelected) {
                                      _selected.remove(key);
                                    } else {
                                      _selected.add(key);
                                    }
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withValues(alpha: 0.15)
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.06),
                                    borderRadius: BorderRadius.circular(10),
                                    border: isSelected
                                        ? Border.all(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                            width: 1.5,
                                          )
                                        : null,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(c['emoji'] as String,
                                          style:
                                              const TextStyle(fontSize: 14)),
                                      const SizedBox(width: 6),
                                      Text(
                                        c['name'] as String,
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                        ),
                                      ),
                                      if (isSelected) ...[
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.check_circle,
                                          size: 14,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

            // Add button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving || _selected.isEmpty
                      ? null
                      : () => _addSelected(categories),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _selected.isEmpty
                              ? 'Select chores to add'
                              : 'Add ${_selected.length} chore${_selected.length == 1 ? '' : 's'}',
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
