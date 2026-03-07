import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lifeboard/models/chore_model.dart';
import 'package:lifeboard/theme/app_colors.dart';

/// A card displaying a chore item with tap-to-complete, swipe-to-skip,
/// and long-press context menu for edit/delete.
class ChoreCard extends StatefulWidget {
  const ChoreCard({
    super.key,
    required this.chore,
    required this.onComplete,
    required this.onSkip,
    required this.onEdit,
    this.onDelete,
    this.assigneeName,
  });

  final Chore chore;
  final VoidCallback onComplete;
  final VoidCallback onSkip;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;
  final String? assigneeName;

  @override
  State<ChoreCard> createState() => _ChoreCardState();
}

class _ChoreCardState extends State<ChoreCard>
    with SingleTickerProviderStateMixin {
  bool _completing = false;
  late final AnimationController _completeController;
  late final Animation<double> _checkScale;

  @override
  void initState() {
    super.initState();
    _completeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _checkScale = CurvedAnimation(
      parent: _completeController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _completeController.dispose();
    super.dispose();
  }

  void _handleComplete() {
    if (_completing) return;
    setState(() => _completing = true);
    HapticFeedback.mediumImpact();
    _completeController.forward();

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) widget.onComplete();
    });
  }

  Color _accentColor() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(
      widget.chore.nextDueDate.year,
      widget.chore.nextDueDate.month,
      widget.chore.nextDueDate.day,
    );

    final daysOverdue = today.difference(dueDay).inDays;
    if (daysOverdue > 1) return AppColors.error;
    if (daysOverdue == 1) return AppColors.accentWarm;
    return AppColors.primaryDark;
  }

  String _dueSignalText() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(
      widget.chore.nextDueDate.year,
      widget.chore.nextDueDate.month,
      widget.chore.nextDueDate.day,
    );

    final diff = today.difference(dueDay).inDays;
    if (diff > 1) return '$diff days overdue';
    if (diff == 1) return 'Yesterday';
    if (diff == 0) return 'Due today';

    final futureDiff = dueDay.difference(today).inDays;
    if (futureDiff == 1) return 'Tomorrow';
    if (futureDiff <= 7) return 'In $futureDiff days';
    return 'In ${futureDiff}d';
  }

  String _recurrenceLabel() {
    switch (widget.chore.recurrenceType) {
      case 'one_off':
        return 'Once';
      case 'daily':
        return 'Daily';
      case 'every_n_days':
        return 'Every ${widget.chore.recurrenceInterval}d';
      case 'weekly':
        return 'Weekly';
      case 'biweekly':
        return 'Biweekly';
      case 'monthly':
        return 'Monthly';
      default:
        return 'Weekly';
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dismissible(
      key: ValueKey('chore_${widget.chore.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.accentWarm,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('Skip', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            SizedBox(width: 8),
            Icon(Icons.skip_next, color: Colors.white, size: 20),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        HapticFeedback.lightImpact();
        widget.onSkip();
        return false;
      },
      child: GestureDetector(
      onLongPress: () => _showContextMenu(context),
      child: AnimatedOpacity(
        opacity: _completing ? 0.5 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkCardSurface
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
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
                  width: 4,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                ),

                // Emoji
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      widget.chore.emoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),

                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name
                        Text(
                          widget.chore.name,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                            decoration: _completing
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // Recurrence badge + due signal + assignee
                        Row(
                          children: [
                            // Recurrence pill
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _recurrenceLabel(),
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Due signal
                            Text(
                              _dueSignalText(),
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: accent,
                              ),
                            ),
                            if (widget.assigneeName != null ||
                                widget.chore.assigneeId == null) ...[
                              const SizedBox(width: 8),
                              Text(
                                widget.chore.assigneeId == null
                                    ? 'Anyone'
                                    : widget.assigneeName ?? '',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.4),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Complete button — 44x44 touch target
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Semantics(
                    label: 'Mark ${widget.chore.name} as done',
                    button: true,
                    child: GestureDetector(
                      onTap: _handleComplete,
                      child: AnimatedBuilder(
                        animation: _checkScale,
                        builder: (context, child) {
                          return Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _completing
                                  ? AppColors.statusDone
                                  : Colors.transparent,
                              border: Border.all(
                                color: _completing
                                    ? AppColors.statusDone
                                    : Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.2),
                                width: 2,
                              ),
                            ),
                            child: _completing
                                ? Transform.scale(
                                    scale: _checkScale.value,
                                    child: const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  )
                                : null,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(ctx)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(ctx);
                widget.onEdit();
              },
            ),
            if (widget.onDelete != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.error),
                title: const Text('Delete',
                    style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(ctx);
                  widget.onDelete!();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// A card displaying a completed chore (for the "Done Today" section).
class DoneChoreCard extends StatelessWidget {
  const DoneChoreCard({
    super.key,
    required this.emoji,
    required this.name,
    required this.completedByName,
    required this.completedAt,
    this.hatTipBy,
    this.currentUserId,
    this.completedByUserId,
    this.onHatTip,
  });

  final String emoji;
  final String name;
  final String completedByName;
  final DateTime completedAt;
  final String? hatTipBy;
  final String? currentUserId;
  final String? completedByUserId;
  final VoidCallback? onHatTip;

  String _timeAgo() {
    final diff = DateTime.now().difference(completedAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return 'Today';
  }

  @override
  Widget build(BuildContext context) {
    final isOwn = currentUserId == completedByUserId;
    final hasHatTip = hatTipBy != null;
    final canHatTip = !isOwn && !hasHatTip && onHatTip != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkCardSurface
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Green accent bar
            Container(
              width: 3,
              decoration: BoxDecoration(
                color: AppColors.statusDone,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            // Emoji
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            // Name + who/when
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$completedByName · ${_timeAgo()}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
            // Hat-tip button
            if (canHatTip)
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onHatTip!();
                },
                child: Semantics(
                  label: 'Acknowledge $completedByName\'s work',
                  button: true,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      Icons.thumb_up_alt_outlined,
                      size: 18,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
            if (hasHatTip)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(
                  Icons.thumb_up_alt,
                  size: 18,
                  color: AppColors.accentWarm,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
