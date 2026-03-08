import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lifeboard/core/errors/app_exceptions.dart';
import 'package:lifeboard/models/space_model.dart';
import 'package:lifeboard/providers/activity_provider.dart';
import 'package:lifeboard/providers/space_provider.dart';
import 'package:lifeboard/theme/app_text_styles.dart';

/// Which tab the shell bar is displayed on.
enum AppTab { board, chores, buylist }

/// Shared app bar used across all 3 main tabs.
///
/// - Left: Space name + chevron (tappable → space picker bottom sheet).
///         Single-space users see the name without chevron.
/// - Right: Weekly calendar (Board tab only) + Notification bell with badge + Settings gear.
class AppShellBar extends ConsumerWidget implements PreferredSizeWidget {
  const AppShellBar({
    super.key,
    required this.currentTab,
    this.additionalActions,
  });

  final AppTab currentTab;
  final List<Widget>? additionalActions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacesAsync = ref.watch(userSpacesProvider);
    final selectedId = ref.watch(selectedSpaceProvider);
    final unreadCount =
        ref.watch(unreadActivityCountProvider).valueOrNull ?? 0;

    final allSpaces = spacesAsync.valueOrNull ?? [];
    final currentSpace =
        allSpaces.where((s) => s.id == selectedId).firstOrNull;
    final spaceName = currentSpace?.name ?? 'Lifeboard';
    final hasMultipleSpaces = allSpaces.length > 1;

    return AppBar(
      leading: const SizedBox.shrink(),
      leadingWidth: 0,
      centerTitle: false,
      title: GestureDetector(
        onTap: hasMultipleSpaces
            ? () => _showSpacePicker(context, ref, allSpaces, selectedId)
            : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                spaceName,
                style: GoogleFonts.nunito(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (hasMultipleSpaces) ...[
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down_rounded, size: 22),
            ],
          ],
        ),
      ),
      actions: [
        if (additionalActions != null) ...additionalActions!,
        if (currentTab == AppTab.board)
          IconButton(
            onPressed: () => context.push('/weekly'),
            icon: const Icon(Icons.calendar_today_outlined, size: 22),
            tooltip: 'Weekly view',
          ),
        IconButton(
          onPressed: () => context.push('/activity'),
          icon: Badge(
            isLabelVisible: unreadCount > 0,
            label: Text(unreadCount > 99 ? '99+' : '$unreadCount'),
            child: const Icon(Icons.notifications_outlined, size: 22),
          ),
          tooltip: 'Activity',
        ),
        IconButton(
          onPressed: () => context.push('/settings'),
          icon: const Icon(Icons.settings_outlined, size: 22),
          tooltip: 'Settings',
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  void _showSpacePicker(
    BuildContext context,
    WidgetRef ref,
    List<SpaceModel> allSpaces,
    String? selectedId,
  ) {
    final colors = Theme.of(context).colorScheme;
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Switch Space',
                  style: AppTextStyles.headingSmall
                      .copyWith(color: colors.onSurface),
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final space in allSpaces)
                      ListTile(
                        title: Text(space.name),
                        leading: Icon(
                          Icons.workspaces_outlined,
                          color: space.id == selectedId
                              ? colors.primary
                              : colors.onSurface.withValues(alpha: 0.5),
                        ),
                        trailing: space.id == selectedId
                            ? Icon(Icons.check, color: colors.primary)
                            : null,
                        onTap: () {
                          Navigator.of(ctx).pop();
                          ref
                              .read(selectedSpaceProvider.notifier)
                              .select(space.id);
                        },
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.add_rounded, color: colors.primary),
                title: Text(
                  'Create new space...',
                  style: TextStyle(color: colors.primary),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _showCreateSpaceDialog(context, ref);
                },
              ),
              ListTile(
                leading:
                    Icon(Icons.group_add_rounded, color: colors.primary),
                title: Text(
                  'Join a space...',
                  style: TextStyle(color: colors.primary),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _showJoinSpaceDialog(context, ref);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showCreateSpaceDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    final colors = Theme.of(context).colorScheme;
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Create Space',
          style:
              AppTextStyles.headingSmall.copyWith(color: colors.onSurface),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'e.g. Our Home, Family, Vacation...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              Navigator.of(ctx).pop();
              try {
                final space = await ref
                    .read(spaceActionProvider.notifier)
                    .createSpace(name: name, userId: userId);
                unawaited(ref.read(selectedSpaceProvider.notifier).select(space.id));
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Failed to create space: $e')),
                  );
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showJoinSpaceDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    final colors = Theme.of(context).colorScheme;
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Join a Space',
          style:
              AppTextStyles.headingSmall.copyWith(color: colors.onSurface),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          textAlign: TextAlign.center,
          style: AppTextStyles.headingSmall.copyWith(letterSpacing: 4),
          decoration: const InputDecoration(
            hintText: 'Enter invite code',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final code = controller.text.trim();
              if (code.isEmpty) return;
              Navigator.of(ctx).pop();
              try {
                final space = await ref
                    .read(spaceActionProvider.notifier)
                    .joinSpace(inviteCode: code, userId: userId);
                unawaited(ref.read(selectedSpaceProvider.notifier).select(space.id));
              } on SpaceNotFoundException {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('No space found with that invite code'),
                    ),
                  );
                }
              } on AlreadyMemberException {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'You are already a member of this space'),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Failed to join space: $e')),
                  );
                }
              }
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }
}
