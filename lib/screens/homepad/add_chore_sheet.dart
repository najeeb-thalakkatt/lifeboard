import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lifeboard/core/constants.dart';
import 'package:lifeboard/models/chore_model.dart';
import 'package:lifeboard/providers/chore_provider.dart';
import 'package:lifeboard/providers/space_provider.dart';
import 'package:lifeboard/theme/app_text_styles.dart';

/// Bottom sheet for adding or editing a chore.
class AddChoreSheet extends ConsumerStatefulWidget {
  const AddChoreSheet({
    super.key,
    required this.spaceId,
    this.existingChore,
  });

  final String spaceId;
  final Chore? existingChore;

  @override
  ConsumerState<AddChoreSheet> createState() => _AddChoreSheetState();
}

class _AddChoreSheetState extends ConsumerState<AddChoreSheet> {
  final _nameController = TextEditingController();
  String _selectedEmoji = '🧹';
  String _recurrenceType = 'weekly';
  int _intervalDays = 3;
  final Set<int> _daysOfWeek = {};
  int _dayOfMonth = 1;
  String? _assigneeId;
  bool _isSaving = false;

  bool get _isEditing => widget.existingChore != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final c = widget.existingChore!;
      _nameController.text = c.name;
      _selectedEmoji = c.emoji;
      _recurrenceType = c.recurrenceType;
      _intervalDays = c.recurrenceInterval;
      _daysOfWeek.addAll(c.recurrenceDaysOfWeek);
      _dayOfMonth = c.recurrenceDayOfMonth;
      _assigneeId = c.assigneeId;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      if (_isEditing) {
        await ref.read(choreActionProvider.notifier).updateChore(
              spaceId: widget.spaceId,
              choreId: widget.existingChore!.id,
              fields: {
                'name': name,
                'emoji': _selectedEmoji,
                'recurrenceType': _recurrenceType,
                'recurrenceInterval': _intervalDays,
                'recurrenceDaysOfWeek': _daysOfWeek.toList(),
                'recurrenceDayOfMonth': _dayOfMonth,
                'assigneeId': _assigneeId,
              },
            );
      } else {
        await ref.read(choreActionProvider.notifier).addChore(
              spaceId: widget.spaceId,
              name: name,
              emoji: _selectedEmoji,
              recurrenceType: _recurrenceType,
              recurrenceInterval: _intervalDays,
              recurrenceDaysOfWeek: _daysOfWeek.toList(),
              recurrenceDayOfMonth: _dayOfMonth,
              assigneeId: _assigneeId,
            );
      }

      if (mounted) {
        unawaited(HapticFeedback.mediumImpact());
        Navigator.of(context).pop(true);
      }
    } catch (_) {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final memberProfiles =
        ref.watch(spaceMemberProfilesProvider(widget.spaceId));

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: SingleChildScrollView(
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
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _isEditing
                        ? AppConstants.choreEditChore
                        : AppConstants.choreAddChore,
                    style: AppTextStyles.headingSmall,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Emoji picker
              GestureDetector(
                onTap: () => _showEmojiPicker(context),
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _selectedEmoji,
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppConstants.choreTapToChange,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(height: 16),

              // Name field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: TextField(
                  controller: _nameController,
                  autofocus: !_isEditing,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: AppConstants.choreWhatNeedsDoing,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Recurrence selector
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    AppConstants.choreHowOften,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _RecurrencePill(
                      label: 'Daily',
                      isSelected: _recurrenceType == 'daily',
                      onTap: () =>
                          setState(() => _recurrenceType = 'daily'),
                    ),
                    _RecurrencePill(
                      label: 'Every N Days',
                      isSelected: _recurrenceType == 'every_n_days',
                      onTap: () =>
                          setState(() => _recurrenceType = 'every_n_days'),
                    ),
                    _RecurrencePill(
                      label: 'Weekly',
                      isSelected: _recurrenceType == 'weekly',
                      onTap: () =>
                          setState(() => _recurrenceType = 'weekly'),
                    ),
                    _RecurrencePill(
                      label: 'Biweekly',
                      isSelected: _recurrenceType == 'biweekly',
                      onTap: () =>
                          setState(() => _recurrenceType = 'biweekly'),
                    ),
                    _RecurrencePill(
                      label: 'Monthly',
                      isSelected: _recurrenceType == 'monthly',
                      onTap: () =>
                          setState(() => _recurrenceType = 'monthly'),
                    ),
                  ],
                ),
              ),

              // Every N Days stepper
              if (_recurrenceType == 'every_n_days') ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Text(
                        'Every',
                        style: GoogleFonts.inter(fontSize: 14),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: _intervalDays > 2
                            ? () =>
                                setState(() => _intervalDays--)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                        iconSize: 24,
                      ),
                      Container(
                        width: 40,
                        alignment: Alignment.center,
                        child: Text(
                          '$_intervalDays',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _intervalDays < 30
                            ? () =>
                                setState(() => _intervalDays++)
                            : null,
                        icon: const Icon(Icons.add_circle_outline),
                        iconSize: 24,
                      ),
                      Text(
                        'days',
                        style: GoogleFonts.inter(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],

              // Weekly day-of-week selector
              if (_recurrenceType == 'weekly') ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppConstants.choreOnWhichDays,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(7, (i) {
                          final day = i + 1; // 1=Mon..7=Sun
                          final labels = [
                            'M', 'T', 'W', 'T', 'F', 'S', 'S'
                          ];
                          final isSelected = _daysOfWeek.contains(day);
                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                if (isSelected) {
                                  _daysOfWeek.remove(day);
                                } else {
                                  _daysOfWeek.add(day);
                                }
                              });
                            },
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.08),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                labels[i],
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Assignment
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppConstants.choreAssignTo,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _RecurrencePill(
                          label: AppConstants.choreAnyone,
                          isSelected: _assigneeId == null,
                          onTap: () =>
                              setState(() => _assigneeId = null),
                        ),
                        ...memberProfiles.entries.map((entry) {
                          return _RecurrencePill(
                            label: entry.value,
                            isSelected: _assigneeId == entry.key,
                            onTap: () =>
                                setState(() => _assigneeId = entry.key),
                          );
                        }),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Save button
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: SizedBox(
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
                        : Text(_isEditing
                            ? AppConstants.choreSaveChanges
                            : AppConstants.choreAddChore),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEmojiPicker(BuildContext context) {
    final emojis = [
      '🧹', '🍽️', '🧺', '🗑️', '🧽', '🚿', '🪣', '🌱',
      '👕', '🛏️', '🧊', '🪟', '♻️', '📬', '🍳', '👔',
      '✨', '🌿', '🧴', '🐾', '💡', '🔧', '🧲', '✅',
    ];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppConstants.chorePickEmoji, style: AppTextStyles.headingSmall),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: emojis.map((e) {
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedEmoji = e);
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _selectedEmoji == e
                          ? Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.15)
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(e, style: const TextStyle(fontSize: 24)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _RecurrencePill extends StatelessWidget {
  const _RecurrencePill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected
                ? Colors.white
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
