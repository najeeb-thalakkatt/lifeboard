import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:lifeboard/models/comment_model.dart';
import 'package:lifeboard/providers/auth_provider.dart';
import 'package:lifeboard/providers/comment_provider.dart';
import 'package:lifeboard/providers/space_provider.dart';
import 'package:lifeboard/theme/app_colors.dart';
import 'package:lifeboard/theme/app_text_styles.dart';
import 'package:lifeboard/widgets/avatar_widget.dart';

/// Available quick-reaction emojis for comments.
const _reactionEmojis = ['\u{2764}\u{FE0F}', '\u{1F44D}', '\u{1F602}', '\u{1F605}'];

/// Comments section shown at the bottom of the task detail screen.
/// Displays a real-time comment list with reactions and an input field.
class CommentsSection extends ConsumerStatefulWidget {
  const CommentsSection({
    super.key,
    required this.spaceId,
    required this.taskId,
  });

  final String spaceId;
  final String taskId;

  @override
  ConsumerState<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends ConsumerState<CommentsSection> {
  final _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    _controller.clear();

    await ref.read(commentActionProvider.notifier).addComment(
          spaceId: widget.spaceId,
          taskId: widget.taskId,
          text: text,
        );

    if (mounted) setState(() => _sending = false);
  }

  void _toggleReaction(String commentId, String emoji) {
    ref.read(commentActionProvider.notifier).toggleReaction(
          spaceId: widget.spaceId,
          taskId: widget.taskId,
          commentId: commentId,
          emoji: emoji,
        );
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(
      taskCommentsProvider((spaceId: widget.spaceId, taskId: widget.taskId)),
    );
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final memberNames = ref.watch(spaceMemberProfilesProvider(widget.spaceId));
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Comments',
          style: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.w600,
            color: colors.onSurface.withValues(alpha: 0.6),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        commentsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Could not load comments',
              style: AppTextStyles.bodyMedium.copyWith(
                color: colors.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
          data: (comments) {
            final ext = Theme.of(context).extension<AppColorsExtension>()!;
            if (comments.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: ext.divider,
                  ),
                ),
                child: Center(
                  child: Text(
                    'No comments yet. Start the conversation!',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: colors.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              );
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: comments.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _CommentBubble(
                comment: comments[i],
                currentUserId:
                    FirebaseAuth.instance.currentUser?.uid ?? '',
                currentUserName: currentUser?.displayName,
                currentUserPhoto: currentUser?.photoUrl,
                memberNames: memberNames,
                onToggleReaction: (emoji) =>
                    _toggleReaction(comments[i].id, emoji),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _CommentInput(
          controller: _controller,
          sending: _sending,
          onSend: _sendComment,
        ),
      ],
    );
  }
}

/// A single comment bubble with author info, text, timestamp, and reactions.
class _CommentBubble extends StatelessWidget {
  const _CommentBubble({
    required this.comment,
    required this.currentUserId,
    this.currentUserName,
    this.currentUserPhoto,
    required this.memberNames,
    required this.onToggleReaction,
  });

  final CommentModel comment;
  final String currentUserId;
  final String? currentUserName;
  final String? currentUserPhoto;
  final Map<String, String> memberNames;
  final ValueChanged<String> onToggleReaction;

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final isMe = comment.authorId == currentUserId;
    final colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AvatarWidget(
          name: isMe ? (currentUserName ?? 'Me') : (memberNames[comment.authorId] ?? 'Member'),
          imageUrl: isMe ? currentUserPhoto : null,
          radius: 16,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    isMe ? 'You' : (memberNames[comment.authorId] ?? _shortName(comment.authorId)),
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _relativeTime(comment.createdAt),
                    style: AppTextStyles.caption.copyWith(
                      color: colors.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isMe
                      ? colors.primary.withValues(alpha: 0.08)
                      : colors.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  comment.text,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: colors.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              _ReactionBar(
                reactions: comment.reactions,
                currentUserId: currentUserId,
                onToggle: onToggleReaction,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _shortName(String userId) {
    if (userId.length > 6) return userId.substring(0, 6);
    return userId;
  }
}

/// Row of reaction pills + quick-add reaction buttons.
class _ReactionBar extends StatelessWidget {
  const _ReactionBar({
    required this.reactions,
    required this.currentUserId,
    required this.onToggle,
  });

  final Map<String, List<String>> reactions;
  final String currentUserId;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppColorsExtension>()!;

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        // Existing reactions as pills
        ...reactions.entries.map((entry) {
          final emoji = entry.key;
          final users = entry.value;
          final iReacted = users.contains(currentUserId);
          return GestureDetector(
            onTap: () => onToggle(emoji),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: iReacted
                    ? colors.primary.withValues(alpha: 0.12)
                    : colors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: iReacted
                      ? colors.primary.withValues(alpha: 0.4)
                      : ext.divider,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Text(
                    '${users.length}',
                    style: AppTextStyles.caption.copyWith(
                      fontWeight:
                          iReacted ? FontWeight.w600 : FontWeight.normal,
                      color: iReacted
                          ? colors.primary
                          : colors.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        // Quick-add button for emojis not yet on this comment
        _AddReactionButton(
          existingEmojis: reactions.keys.toSet(),
          onSelect: onToggle,
        ),
      ],
    );
  }
}

/// Small "+" button that shows a popup with available reaction emojis.
class _AddReactionButton extends StatelessWidget {
  const _AddReactionButton({
    required this.existingEmojis,
    required this.onSelect,
  });

  final Set<String> existingEmojis;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppColorsExtension>()!;
    return GestureDetector(
      onTap: () => _showReactionPicker(context),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: ext.divider,
          ),
        ),
        child: Icon(
          Icons.add,
          size: 16,
          color: colors.onSurface.withValues(alpha: 0.4),
        ),
      ),
    );
  }

  void _showReactionPicker(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _reactionEmojis
                .map(
                  (emoji) => GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      onSelect(emoji);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: existingEmojis.contains(emoji)
                            ? colors.primary.withValues(alpha: 0.1)
                            : colors.primaryContainer.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 24)),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

/// Text input field with send button for adding comments.
class _CommentInput extends StatelessWidget {
  const _CommentInput({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppColorsExtension>()!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ext.divider,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: AppTextStyles.bodyMedium.copyWith(
                color: colors.onSurface,
              ),
              decoration: InputDecoration(
                hintText: 'Write a comment...',
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.4),
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                fillColor: Colors.transparent,
                filled: true,
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              maxLines: null,
            ),
          ),
          sending
              ? const Padding(
                  padding: EdgeInsets.all(10),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.send_rounded),
                  color: colors.primary,
                  onPressed: onSend,
                  tooltip: 'Send comment',
                ),
        ],
      ),
    );
  }
}
