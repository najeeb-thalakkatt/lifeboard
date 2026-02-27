import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import 'package:lifeboard/models/space_model.dart';
import 'package:lifeboard/providers/auth_provider.dart';
import 'package:lifeboard/providers/profile_provider.dart';
import 'package:lifeboard/providers/space_provider.dart';
import 'package:lifeboard/theme/app_colors.dart';
import 'package:lifeboard/widgets/avatar_widget.dart';

/// Profile & Settings screen (Phase 10).
class ProfileSettingsScreen extends ConsumerWidget {
  const ProfileSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Error loading profile', style: GoogleFonts.inter()),
        ),
        data: (user) {
          if (user == null) {
            return Center(
              child: Text('Not signed in', style: GoogleFonts.inter()),
            );
          }
          return _ProfileBody(userId: user.id);
        },
      ),
    );
  }
}

// ── Main scrollable body ──────────────────────────────────────────

class _ProfileBody extends ConsumerWidget {
  const _ProfileBody({required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.valueOrNull;
    final spacesAsync = ref.watch(userSpacesProvider);
    final themeMode = ref.watch(themeModeProvider);
    final statsAsync = ref.watch(spaceStatsProvider);
    final topPadding = MediaQuery.of(context).padding.top;
    final colors = Theme.of(context).colorScheme;

    return RefreshIndicator(
      color: colors.primary,
      onRefresh: () async {
        ref.invalidate(currentUserProvider);
        ref.invalidate(userSpacesProvider);
        ref.invalidate(spaceStatsProvider);
        await Future<void>.delayed(const Duration(milliseconds: 500));
      },
      child: ListView(
        padding: EdgeInsets.fromLTRB(16, topPadding + 16, 16, 100),
        children: [
          // ── Header ──────────────────────────────────────────
          Text(
            'Profile',
            style: GoogleFonts.nunito(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 20),

          // ── Profile Card ────────────────────────────────────
          _ProfileCard(user: user),
          const SizedBox(height: 20),

          // ── Our Stats ───────────────────────────────────────
          const _SectionHeader(title: 'Our Stats'),
          const SizedBox(height: 8),
          _StatsCard(statsAsync: statsAsync),
          const SizedBox(height: 20),

          // ── Spaces Management ───────────────────────────────
          const _SectionHeader(title: 'Spaces'),
          const SizedBox(height: 8),
          spacesAsync.when(
            loading: () => const _LoadingCard(),
            error: (_, __) => const _ErrorCard(message: 'Could not load spaces'),
            data: (spaces) => _SpacesList(spaces: spaces, userId: userId),
          ),
          const SizedBox(height: 20),

          // ── Preferences ─────────────────────────────────────
          const _SectionHeader(title: 'Preferences'),
          const SizedBox(height: 8),
          _PreferencesCard(
            user: user,
            themeMode: themeMode,
          ),
          const SizedBox(height: 20),

          // ── Account Actions ─────────────────────────────────
          const _SectionHeader(title: 'Account'),
          const SizedBox(height: 8),
          _AccountActionsCard(user: user),
        ],
      ),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: GoogleFonts.nunito(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}

// ── Profile Card ──────────────────────────────────────────────────

class _ProfileCard extends ConsumerStatefulWidget {
  const _ProfileCard({required this.user});
  final dynamic user; // UserModel?

  @override
  ConsumerState<_ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends ConsumerState<_ProfileCard> {
  bool _isEditingName = false;
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.user?.displayName ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant _ProfileCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditingName) {
      _nameController.text = widget.user?.displayName ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (image == null) return;

    final userId = FirebaseAuth.instance.currentUser!.uid;
    final ref = FirebaseStorage.instance
        .ref('users/$userId/profile_photo.jpg');

    UploadTask uploadTask;
    if (kIsWeb) {
      final bytes = await image.readAsBytes();
      uploadTask = ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    } else {
      uploadTask = ref.putFile(File(image.path));
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Uploading photo...')),
    );

    final snapshot = await uploadTask;
    final url = await snapshot.ref.getDownloadURL();

    if (!mounted) return;
    await this.ref.read(profileActionProvider.notifier).updatePhotoUrl(url);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Photo updated!')),
    );
  }

  void _showMoodEmojiPicker() {
    const moods = ['😊', '😎', '🥰', '🤔', '😴', '🔥', '💪', '🎉', '☕', '🌈', '✨', '🧘'];
    final colors = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pick your mood',
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  // "None" option
                  _MoodChip(
                    emoji: '❌',
                    label: 'None',
                    isSelected: widget.user?.moodEmoji == null,
                    onTap: () {
                      ref.read(profileActionProvider.notifier).updateMoodEmoji(null);
                      Navigator.pop(ctx);
                    },
                  ),
                  ...moods.map((emoji) => _MoodChip(
                        emoji: emoji,
                        isSelected: widget.user?.moodEmoji == emoji,
                        onTap: () {
                          ref.read(profileActionProvider.notifier).updateMoodEmoji(emoji);
                          Navigator.pop(ctx);
                        },
                      )),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ── Avatar + Photo Upload ───────────────────────
            GestureDetector(
              onTap: _pickAndUploadPhoto,
              child: Stack(
                children: [
                  AvatarWidget(
                    imageUrl: user?.photoUrl,
                    name: user?.displayName,
                    radius: 44,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: colors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (user?.moodEmoji != null)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Text(
                        user!.moodEmoji!,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Display Name ────────────────────────────────
            if (_isEditingName) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Your name',
                        isDense: true,
                      ),
                      onSubmitted: (_) => _saveName(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.check, color: colors.primary),
                    onPressed: _saveName,
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: colors.onSurface.withValues(alpha: 0.5)),
                    onPressed: () => setState(() => _isEditingName = false),
                  ),
                ],
              ),
            ] else ...[
              GestureDetector(
                onTap: () => setState(() => _isEditingName = true),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      user?.displayName ?? 'Set your name',
                      style: GoogleFonts.nunito(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.edit,
                      size: 16,
                      color: colors.onSurface.withValues(alpha: 0.5),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 4),

            // ── Email ───────────────────────────────────────
            Text(
              user?.email ?? '',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: colors.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 12),

            // ── Mood Emoji Button ───────────────────────────
            OutlinedButton.icon(
              onPressed: _showMoodEmojiPicker,
              icon: Text(
                user?.moodEmoji ?? '😊',
                style: const TextStyle(fontSize: 18),
              ),
              label: Text(
                user?.moodEmoji != null ? 'Change mood' : 'Set mood emoji',
                style: GoogleFonts.inter(fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveName() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    setState(() => _isEditingName = false);
    await ref.read(profileActionProvider.notifier).updateDisplayName(name);
  }
}

// ── Mood Chip ─────────────────────────────────────────────────────

class _MoodChip extends StatelessWidget {
  const _MoodChip({
    required this.emoji,
    this.label,
    required this.isSelected,
    required this.onTap,
  });
  final String emoji;
  final String? label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? colors.primaryContainer : colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? colors.primary
                : (isDark ? AppColors.darkDivider : AppColors.divider),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label != null ? '$emoji $label' : emoji,
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}

// ── Stats Card ────────────────────────────────────────────────────

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.statsAsync});
  final AsyncValue<SpaceStats> statsAsync;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: statsAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (_, __) => Text(
            'Could not load stats',
            style: GoogleFonts.inter(color: colors.error),
          ),
          data: (stats) => Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      icon: '🎉',
                      value: '${stats.totalCompleted}',
                      label: 'Tasks done',
                    ),
                  ),
                  Expanded(
                    child: _StatTile(
                      icon: '🔥',
                      value: '${stats.currentStreak}',
                      label: 'Week streak',
                    ),
                  ),
                  Expanded(
                    child: _StatTile(
                      icon: '🏆',
                      value: '${stats.bestStreak}',
                      label: 'Best streak',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              // ── Fun Badges ────────────────────────────────
              _BadgesRow(totalCompleted: stats.totalCompleted, currentStreak: stats.currentStreak),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
  });
  final String icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.nunito(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: colors.onSurface,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: colors.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

// ── Badges Row ────────────────────────────────────────────────────

class _BadgesRow extends StatelessWidget {
  const _BadgesRow({required this.totalCompleted, required this.currentStreak});
  final int totalCompleted;
  final int currentStreak;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final badges = <_Badge>[
      _Badge(icon: '👶', name: 'First Steps', earned: totalCompleted >= 1),
      _Badge(icon: '🤝', name: 'Team Player', earned: totalCompleted >= 10),
      _Badge(icon: '🎯', name: 'On a Roll', earned: currentStreak >= 4),
      _Badge(icon: '🚀', name: 'Unstoppable', earned: currentStreak >= 12),
      _Badge(icon: '💯', name: 'Century', earned: totalCompleted >= 100),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Badges',
          style: GoogleFonts.nunito(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: badges.map((badge) {
            return Tooltip(
              message: badge.name,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: badge.earned
                      ? colors.primaryContainer
                      : (isDark ? AppColors.darkCardSurface : Colors.grey[100]),
                  borderRadius: BorderRadius.circular(12),
                  border: badge.earned
                      ? Border.all(color: AppColors.accentWarm, width: 2)
                      : null,
                ),
                child: Center(
                  child: Opacity(
                    opacity: badge.earned ? 1.0 : 0.3,
                    child: Text(
                      badge.icon,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _Badge {
  const _Badge({required this.icon, required this.name, required this.earned});
  final String icon;
  final String name;
  final bool earned;
}

// ── Spaces List ───────────────────────────────────────────────────

class _SpacesList extends ConsumerWidget {
  const _SpacesList({required this.spaces, required this.userId});
  final List<SpaceModel> spaces;
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    if (spaces.isEmpty) {
      return Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'No spaces yet.',
            style: GoogleFonts.inter(
              color: colors.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
      );
    }

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          for (int i = 0; i < spaces.length; i++) ...[
            _SpaceTile(
              space: spaces[i],
              userId: userId,
            ),
            if (i < spaces.length - 1) const Divider(height: 1, indent: 16, endIndent: 16),
          ],
        ],
      ),
    );
  }
}

class _SpaceTile extends ConsumerWidget {
  const _SpaceTile({required this.space, required this.userId});
  final SpaceModel space;
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final member = space.members[userId];
    final isOwner = member?.role == 'owner';
    final colors = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: colors.primaryContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.workspaces_outlined, color: colors.primary, size: 20),
      ),
      title: Text(
        space.name,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: colors.onSurface,
        ),
      ),
      subtitle: Text(
        '${space.members.length} member${space.members.length == 1 ? '' : 's'} · ${isOwner ? 'Owner' : 'Member'}',
        style: GoogleFonts.inter(
          fontSize: 12,
          color: colors.onSurface.withValues(alpha: 0.5),
        ),
      ),
      trailing: PopupMenuButton<String>(
        icon: Icon(Icons.more_vert, color: colors.onSurface.withValues(alpha: 0.5)),
        onSelected: (value) {
          if (value == 'invite') {
            _showInviteCode(context);
          } else if (value == 'leave') {
            _confirmLeave(context, ref);
          } else if (value == 'delete') {
            _confirmDelete(context, ref);
          }
        },
        itemBuilder: (ctx) => [
          const PopupMenuItem(value: 'invite', child: Text('Invite code')),
          const PopupMenuItem(value: 'leave', child: Text('Leave space')),
          if (isOwner)
            const PopupMenuItem(
              value: 'delete',
              child: Text('Delete space', style: TextStyle(color: AppColors.error)),
            ),
        ],
      ),
    );
  }

  void _showInviteCode(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.person_add_alt_1_rounded, color: colors.primary),
            const SizedBox(width: 8),
            Text(
              'Invite to "${space.name}"',
              style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Share this code with your partner so they can join your space.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: colors.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: space.inviteCode));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Invite code copied!',
                      style: GoogleFonts.inter(color: Colors.white),
                    ),
                    backgroundColor: colors.primary,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: colors.primaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      space.inviteCode,
                      style: GoogleFonts.nunito(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 6,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.copy_rounded,
                      color: colors.primary.withValues(alpha: 0.6),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap to copy',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: colors.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _confirmLeave(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave space?'),
        content: Text('Are you sure you want to leave "${space.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(profileActionProvider.notifier).leaveSpace(space.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Left "${space.name}"')),
              );
            },
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete space?'),
        content: Text(
          'This will permanently delete "${space.name}" and all its boards and tasks. This cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(profileActionProvider.notifier).deleteSpace(space.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Deleted "${space.name}"')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ── Preferences Card ──────────────────────────────────────────────

class _PreferencesCard extends ConsumerWidget {
  const _PreferencesCard({required this.user, required this.themeMode});
  final dynamic user;
  final ThemeMode themeMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pushEnabled = user?.notificationPrefs.pushEnabled ?? true;
    final emailEnabled = user?.notificationPrefs.emailEnabled ?? true;
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          // ── Theme Toggle ──────────────────────────────────
          SwitchListTile(
            secondary: Icon(Icons.dark_mode_outlined, color: colors.primary),
            title: Text(
              'Dark mode',
              style: GoogleFonts.inter(
                fontSize: 15,
                color: colors.onSurface,
              ),
            ),
            value: themeMode == ThemeMode.dark,
            activeThumbColor: colors.primary,
            onChanged: (val) {
              ref.read(themeModeProvider.notifier)
                  .setThemeMode(val ? ThemeMode.dark : ThemeMode.light);
            },
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),

          // ── Push Notifications ────────────────────────────
          SwitchListTile(
            secondary: Icon(Icons.notifications_outlined, color: colors.primary),
            title: Text(
              'Push notifications',
              style: GoogleFonts.inter(
                fontSize: 15,
                color: colors.onSurface,
              ),
            ),
            value: pushEnabled,
            activeThumbColor: colors.primary,
            onChanged: (val) {
              ref.read(profileActionProvider.notifier).updateNotificationPrefs(
                    pushEnabled: val,
                    emailEnabled: emailEnabled,
                  );
            },
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),

          // ── Email Notifications ───────────────────────────
          SwitchListTile(
            secondary: Icon(Icons.email_outlined, color: colors.primary),
            title: Text(
              'Email notifications',
              style: GoogleFonts.inter(
                fontSize: 15,
                color: colors.onSurface,
              ),
            ),
            value: emailEnabled,
            activeThumbColor: colors.primary,
            onChanged: (val) {
              ref.read(profileActionProvider.notifier).updateNotificationPrefs(
                    pushEnabled: pushEnabled,
                    emailEnabled: val,
                  );
            },
          ),
        ],
      ),
    );
  }
}

// ── Account Actions Card ──────────────────────────────────────────

class _AccountActionsCard extends ConsumerWidget {
  const _AccountActionsCard({required this.user});
  final dynamic user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEmailAuth = FirebaseAuth.instance.currentUser?.providerData
            .any((p) => p.providerId == 'password') ??
        false;
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          // ── Change Password ───────────────────────────────
          if (isEmailAuth) ...[
            ListTile(
              leading: Icon(Icons.lock_outline, color: colors.primary),
              title: Text(
                'Change password',
                style: GoogleFonts.inter(fontSize: 15, color: colors.onSurface),
              ),
              trailing: Icon(Icons.chevron_right, color: colors.onSurface.withValues(alpha: 0.3)),
              onTap: () => _showChangePasswordDialog(context, ref),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
          ],

          // ── Sign Out ──────────────────────────────────────
          ListTile(
            leading: Icon(Icons.logout, color: colors.primary),
            title: Text(
              'Sign out',
              style: GoogleFonts.inter(fontSize: 15, color: colors.onSurface),
            ),
            trailing: Icon(Icons.chevron_right, color: colors.onSurface.withValues(alpha: 0.3)),
            onTap: () => _confirmSignOut(context, ref),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),

          // ── Delete Account ────────────────────────────────
          ListTile(
            leading: const Icon(Icons.delete_forever, color: AppColors.error),
            title: Text(
              'Delete account',
              style: GoogleFonts.inter(fontSize: 15, color: AppColors.error),
            ),
            trailing: Icon(Icons.chevron_right, color: colors.onSurface.withValues(alpha: 0.3)),
            onTap: () => _confirmDeleteAccount(context, ref),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, WidgetRef ref) {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change password'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: currentController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current password',
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: newController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New password',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (v.length < 8) return 'At least 8 characters';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(ctx);
              try {
                await ref.read(profileActionProvider.notifier).changePassword(
                      currentPassword: currentController.text,
                      newPassword: newController.text,
                    );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password updated!')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed: ${e.toString()}')),
                  );
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You can always sign back in later.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(profileActionProvider.notifier).signOut();
            },
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This will permanently delete your account and remove you from all spaces. This cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(profileActionProvider.notifier).deleteAccount();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Failed to delete account. You may need to sign in again first.',
                      ),
                    ),
                  );
                }
              }
            },
            child: const Text('Delete my account'),
          ),
        ],
      ),
    );
  }
}

// ── Helper Cards ──────────────────────────────────────────────────

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(message, style: GoogleFonts.inter(color: Theme.of(context).colorScheme.error)),
      ),
    );
  }
}
