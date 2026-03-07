import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lifeboard/core/constants.dart';
import 'package:lifeboard/providers/chore_provider.dart';
import 'package:lifeboard/providers/space_provider.dart';
import 'package:lifeboard/theme/app_text_styles.dart';

/// Search-first unified sheet for adding chores.
///
/// Stage 1: Search field + popular/filtered suggestions.
/// Stage 2: Inline config (name, emoji, recurrence, assignment).
class SearchAddChoreSheet extends ConsumerStatefulWidget {
  const SearchAddChoreSheet({super.key, required this.spaceId});
  final String spaceId;

  @override
  ConsumerState<SearchAddChoreSheet> createState() =>
      _SearchAddChoreSheetState();
}

class _SearchAddChoreSheetState extends ConsumerState<SearchAddChoreSheet> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  // Stage 2 config state
  bool _configuring = false;
  final _nameController = TextEditingController();
  String _selectedEmoji = '🧹';
  String _recurrenceType = 'weekly';
  final Set<int> _daysOfWeek = {};
  String? _assigneeId;
  bool _isSaving = false;
  bool _emojiPickerOpen = false;

  static const _popularChores = [
    'Do the dishes',
    'Vacuum floors',
    'Walk dog',
    'Wash clothes',
    'Cook dinner',
    'Empty trash',
  ];

  @override
  void initState() {
    super.initState();
    // Auto-focus after sheet animates in
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filteredChores(List<Map<String, dynamic>> allChores) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      // Return popular chores
      return allChores
          .where((c) => _popularChores.contains(c['name']))
          .toList();
    }
    return allChores
        .where((c) => (c['name'] as String).toLowerCase().contains(query))
        .toList();
  }

  bool _hasExactMatch(List<Map<String, dynamic>> allChores) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return true;
    return allChores
        .any((c) => (c['name'] as String).toLowerCase() == query);
  }

  String _recurrenceLabel(String type) {
    return AppConstants.choreRecurrenceLabels[type] ?? type;
  }

  void _selectChore(Map<String, dynamic> chore) {
    setState(() {
      _configuring = true;
      _nameController.text = chore['name'] as String;
      _selectedEmoji = chore['emoji'] as String? ?? '🧹';
      _recurrenceType = chore['recurrenceType'] as String? ?? 'weekly';
      _daysOfWeek.clear();
      _assigneeId = null;
      _emojiPickerOpen = false;
    });
    _searchFocusNode.unfocus();
  }

  void _selectCustom() {
    setState(() {
      _configuring = true;
      _nameController.text = _searchController.text.trim();
      _selectedEmoji = '✅';
      _recurrenceType = 'weekly';
      _daysOfWeek.clear();
      _assigneeId = null;
      _emojiPickerOpen = false;
    });
    _searchFocusNode.unfocus();
  }

  void _backToSearch() {
    setState(() {
      _configuring = false;
      _emojiPickerOpen = false;
    });
    _searchFocusNode.requestFocus();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      await ref.read(choreActionProvider.notifier).addChore(
            spaceId: widget.spaceId,
            name: name,
            emoji: _selectedEmoji,
            recurrenceType: _recurrenceType,
            recurrenceDaysOfWeek: _daysOfWeek.toList(),
            assigneeId: _assigneeId,
          );

      if (mounted) {
        HapticFeedback.mediumImpact();
        Navigator.of(context).pop(true);
      }
    } catch (_) {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
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

            if (_configuring) _buildConfigStage() else _buildSearchStage(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchStage() {
    final catalogAsync = ref.watch(commonChoresCatalogProvider);
    final allChores = catalogAsync.valueOrNull ?? [];
    final catalogLoaded = catalogAsync.hasValue;
    final filtered = _filteredChores(allChores);
    final query = _searchController.text.trim();
    final showCustomRow = query.isNotEmpty && !_hasExactMatch(allChores);

    return Flexible(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(AppConstants.choreAddChore, style: AppTextStyles.headingSmall),
            ),
          ),
          const SizedBox(height: 12),

          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: AppConstants.choreSearchHint,
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Section label
          if (query.isEmpty && filtered.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 28, top: 4, bottom: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  AppConstants.chorePopular,
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
            ),

          // Suggestions list
          if (catalogLoaded)
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  ...filtered.map((chore) => _SuggestionRow(
                        emoji: chore['emoji'] as String? ?? '✅',
                        name: chore['name'] as String,
                        recurrenceLabel: _recurrenceLabel(
                            chore['recurrenceType'] as String? ?? 'weekly'),
                        onTap: () => _selectChore(chore),
                      )),
                  if (showCustomRow)
                    _SuggestionRow(
                      emoji: '✅',
                      name: "Add '$query' as custom chore",
                      recurrenceLabel: '',
                      isCustom: true,
                      onTap: _selectCustom,
                    ),
                ],
              ),
            ),

          if (!catalogLoaded)
            const Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildConfigStage() {
    final memberProfiles =
        ref.watch(spaceMemberProfilesProvider(widget.spaceId));

    return Flexible(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Back button + title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _backToSearch,
                    icon: const Icon(Icons.arrow_back),
                    tooltip: 'Back to search',
                  ),
                  Text(AppConstants.choreConfigureChore,
                      style: AppTextStyles.headingSmall),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Emoji (tappable)
            GestureDetector(
              onTap: () => setState(() => _emojiPickerOpen = !_emojiPickerOpen),
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

            // Inline emoji grid
            if (_emojiPickerOpen)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: _InlineEmojiGrid(
                  selectedEmoji: _selectedEmoji,
                  onSelect: (emoji) {
                    setState(() {
                      _selectedEmoji = emoji;
                      _emojiPickerOpen = false;
                    });
                  },
                ),
              ),

            const SizedBox(height: 12),

            // Name field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: AppConstants.choreWhatNeedsDoing,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Recurrence selector — segmented control
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppConstants.choreHowOften,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _RecurrenceSegmentedControl(
                    selected: _recurrenceType,
                    onChanged: (type) =>
                        setState(() => _recurrenceType = type),
                  ),
                ],
              ),
            ),

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
                        final day = i + 1;
                        const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
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
                      _AssignPill(
                        label: AppConstants.choreAnyone,
                        isSelected: _assigneeId == null,
                        onTap: () => setState(() => _assigneeId = null),
                      ),
                      ...memberProfiles.entries.map((entry) => _AssignPill(
                            label: entry.value,
                            isSelected: _assigneeId == entry.key,
                            onTap: () =>
                                setState(() => _assigneeId = entry.key),
                          )),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Add button
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
                      : Text(AppConstants.choreAddChore),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Suggestion Row ──────────────────────────────────────────────────

class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow({
    required this.emoji,
    required this.name,
    required this.recurrenceLabel,
    required this.onTap,
    this.isCustom = false,
  });

  final String emoji;
  final String name;
  final String recurrenceLabel;
  final VoidCallback onTap;
  final bool isCustom;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isCustom
                    ? Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.1)
                    : Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: isCustom
                  ? Icon(Icons.add,
                      size: 20, color: Theme.of(context).colorScheme.primary)
                  : Text(emoji, style: const TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: isCustom ? FontWeight.w600 : FontWeight.w500,
                  color: isCustom
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            if (recurrenceLabel.isNotEmpty)
              Text(
                recurrenceLabel,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.4),
                ),
              ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Recurrence Segmented Control ────────────────────────────────────

class _RecurrenceSegmentedControl extends StatelessWidget {
  const _RecurrenceSegmentedControl({
    required this.selected,
    required this.onChanged,
  });

  final String selected;
  final ValueChanged<String> onChanged;

  static const _options = [
    ('one_off', 'One-off'),
    ('daily', 'Daily'),
    ('weekly', 'Weekly'),
    ('monthly', 'Monthly'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .onSurface
            .withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: _options.map((option) {
          final isSelected = selected == option.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onChanged(option.$1);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  option.$2,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Inline Emoji Grid ───────────────────────────────────────────────

class _InlineEmojiGrid extends StatelessWidget {
  const _InlineEmojiGrid({
    required this.selectedEmoji,
    required this.onSelect,
  });

  final String selectedEmoji;
  final ValueChanged<String> onSelect;

  static const _emojis = [
    '🧹', '🍽️', '🧺', '🗑️', '🧽', '🚿', '🪣', '🌱',
    '👕', '🛏️', '🧊', '🪟', '♻️', '📬', '🍳', '👔',
    '✨', '🌿', '🧴', '🐾', '💡', '🔧', '🧲', '✅',
    '🐕', '🐱', '🚗', '🏫', '🎒', '🥪', '🛒', '💊',
    '📦', '🌻', '💳', '📊', '📅', '🥗', '🔥', '🚽',
    '🛋️', '🪞', '📋',
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _emojis.map((e) {
        return GestureDetector(
          onTap: () => onSelect(e),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: selectedEmoji == e
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
            child: Text(e, style: const TextStyle(fontSize: 22)),
          ),
        );
      }).toList(),
    );
  }
}

// ── Assign Pill ─────────────────────────────────────────────────────

class _AssignPill extends StatelessWidget {
  const _AssignPill({
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
