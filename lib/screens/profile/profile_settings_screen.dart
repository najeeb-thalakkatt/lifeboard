import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lifeboard/core/constants.dart';
import 'package:lifeboard/core/errors/app_exceptions.dart';
import 'package:lifeboard/models/space_model.dart';
import 'package:lifeboard/models/user_model.dart';
import 'package:lifeboard/providers/auth_provider.dart';
import 'package:lifeboard/providers/profile_provider.dart';
import 'package:lifeboard/providers/space_provider.dart';
import 'package:lifeboard/services/storage_service.dart';
import 'package:lifeboard/theme/app_colors.dart';
import 'package:lifeboard/theme/app_text_styles.dart';
import 'package:lifeboard/widgets/avatar_widget.dart';

/// Settings screen — full-screen push from gear icon in app bar.
class ProfileSettingsScreen extends ConsumerWidget {
  const ProfileSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.nunito(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
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
    final colors = Theme.of(context).colorScheme;

    return RefreshIndicator(
      color: colors.primary,
      onRefresh: () async {
        ref.invalidate(currentUserProvider);
        ref.invalidate(userSpacesProvider);
        await Future<void>.delayed(const Duration(milliseconds: 500));
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          // ── Profile Card ────────────────────────────────────
          _ProfileCard(user: user),
          const SizedBox(height: 20),

          // ── Preferences ─────────────────────────────────────
          const _SectionHeader(title: 'Preferences'),
          const SizedBox(height: 8),
          _PreferencesCard(
            user: user,
            themeMode: themeMode,
          ),
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
  final UserModel? user;

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
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final storageService = ref.read(storageServiceProvider);
    final image = await storageService.pickImageFromGallery();
    if (image == null) return;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Uploading photo...')),
    );

    final storageRef = FirebaseStorage.instance
        .ref('users/$userId/profile_photo.jpg');

    UploadTask uploadTask;
    if (kIsWeb) {
      final bytes = await image.readAsBytes();
      uploadTask = storageRef.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    } else {
      uploadTask = storageRef.putFile(File(image.path));
    }

    final snapshot = await uploadTask;
    final url = await snapshot.ref.getDownloadURL();

    if (!mounted) return;
    await ref.read(profileActionProvider.notifier).updatePhotoUrl(url);

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
                      (user != null && user.displayName.isNotEmpty)
                          ? user.displayName
                          : 'Set your name',
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
    final ext = Theme.of(context).extension<AppColorsExtension>()!;
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
                : ext.divider,
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
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.add_rounded, color: colors.primary, size: 20),
            ),
            title: Text(
              'Create new space',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: colors.primary,
              ),
            ),
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (_) => _CreateSpaceSheet(userId: userId),
              );
            },
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.group_add_outlined, color: colors.primary, size: 20),
            ),
            title: Text(
              'Join a space',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: colors.primary,
              ),
            ),
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (_) => _JoinSpaceSheet(userId: userId),
              );
            },
          ),
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
      onTap: () => _showMembersSheet(context, ref),
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
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Leave space?'),
        content: Text('Are you sure you want to leave "${space.name}"?'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
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

  void _showMembersSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _SpaceMembersSheet(space: space, currentUserId: userId),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Delete space?'),
        content: Text(
          'This will permanently delete "${space.name}" and all its boards and tasks. This cannot be undone.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
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
  final UserModel? user;
  final ThemeMode themeMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pushEnabled = user?.notificationPrefs.pushEnabled ?? true;
    final emailEnabled = user?.notificationPrefs.emailEnabled ?? true;
    final homePadUpdates = user?.notificationPrefs.homePadUpdates ?? true;
    final homePadComplete = user?.notificationPrefs.homePadComplete ?? true;

    void savePrefs({
      bool? push,
      bool? email,
      bool? hpUpdates,
      bool? hpComplete,
    }) {
      ref.read(profileActionProvider.notifier).updateNotificationPrefs(
            pushEnabled: push ?? pushEnabled,
            emailEnabled: email ?? emailEnabled,
            homePadUpdates: hpUpdates ?? homePadUpdates,
            homePadComplete: hpComplete ?? homePadComplete,
          );
    }

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          // ── Theme Toggle ──────────────────────────────────
          _CupertinoSwitchRow(
            icon: Icons.dark_mode_outlined,
            label: 'Dark mode',
            value: Theme.of(context).brightness == Brightness.dark,
            onChanged: (val) {
              ref.read(themeModeProvider.notifier)
                  .setThemeMode(val ? ThemeMode.dark : ThemeMode.light);
            },
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),

          // ── Push Notifications ────────────────────────────
          _CupertinoSwitchRow(
            icon: Icons.notifications_outlined,
            label: 'Push notifications',
            value: pushEnabled,
            onChanged: (val) => savePrefs(push: val),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),

          // ── Email Notifications ───────────────────────────
          _CupertinoSwitchRow(
            icon: Icons.email_outlined,
            label: 'Email notifications',
            value: emailEnabled,
            onChanged: (val) => savePrefs(email: val),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),

          // ── HomePad: Shopping List Updates ─────────────────
          _CupertinoSwitchRow(
            icon: Icons.shopping_cart_outlined,
            label: 'Shopping list updates',
            value: homePadUpdates && pushEnabled,
            onChanged: pushEnabled
                ? (val) => savePrefs(hpUpdates: val)
                : null,
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),

          // ── HomePad: Shopping Complete ─────────────────────
          _CupertinoSwitchRow(
            icon: Icons.check_circle_outline,
            label: 'Shopping complete',
            value: homePadComplete && pushEnabled,
            onChanged: pushEnabled
                ? (val) => savePrefs(hpComplete: val)
                : null,
          ),
        ],
      ),
    );
  }
}

// ── Account Actions Card ──────────────────────────────────────────

class _AccountActionsCard extends ConsumerWidget {
  const _AccountActionsCard({required this.user});
  final UserModel? user;

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
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You can always sign back in later.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
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
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This will permanently delete your account and remove you from all spaces. This cannot be undone.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
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

// ── Space Members Sheet ──────────────────────────────────────

class _SpaceMembersSheet extends ConsumerWidget {
  const _SpaceMembersSheet({required this.space, required this.currentUserId});
  final SpaceModel space;
  final String currentUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final memberIds = space.members.keys.toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────
          Text(
            space.name,
            style: GoogleFonts.nunito(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${memberIds.length} member${memberIds.length == 1 ? '' : 's'}',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: colors.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 16),

          // ── Members list ───────────────────────────────
          ...memberIds.map((memberId) {
            final memberData = space.members[memberId]!;
            final isOwner = memberData.role == 'owner';
            final isCurrentUser = memberId == currentUserId;
            final userAsync = ref.watch(userByIdProvider(memberId));

            return userAsync.when(
              loading: () => _memberRow(
                context: context,
                avatar: SizedBox(
                  width: 40,
                  height: 40,
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.primary,
                      ),
                    ),
                  ),
                ),
                name: 'Loading...',
                subtitle: isOwner ? 'Owner' : 'Member',
                isCurrentUser: isCurrentUser,
                moodEmoji: null,
              ),
              error: (_, __) => _memberRow(
                context: context,
                avatar: const AvatarWidget(name: 'Team member', radius: 20),
                name: 'Team member',
                subtitle: isOwner ? 'Owner' : 'Member',
                isCurrentUser: isCurrentUser,
                moodEmoji: null,
              ),
              data: (user) {
                final name =
                    (user != null && user.displayName.isNotEmpty)
                        ? user.displayName
                        : (user != null && user.email.isNotEmpty)
                            ? user.email.split('@').first
                            : 'Team member';
                return _memberRow(
                  context: context,
                  avatar: AvatarWidget(
                    name: name,
                    imageUrl: user?.photoUrl,
                    radius: 20,
                  ),
                  name: name,
                  subtitle: isOwner ? 'Owner' : 'Member',
                  isCurrentUser: isCurrentUser,
                  moodEmoji: user?.moodEmoji,
                );
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _memberRow({
    required BuildContext context,
    required Widget avatar,
    required String name,
    required String subtitle,
    required bool isCurrentUser,
    required String? moodEmoji,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          avatar,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: colors.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isCurrentUser)
                      Text(
                        ' (you)',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: colors.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    if (moodEmoji != null) ...[
                      const SizedBox(width: 6),
                      Text(moodEmoji, style: const TextStyle(fontSize: 16)),
                    ],
                  ],
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: colors.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
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

// ── Cupertino Switch Row ─────────────────────────────────────────

class _CupertinoSwitchRow extends StatelessWidget {
  const _CupertinoSwitchRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: colors.primary, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: colors.onSurface,
              ),
            ),
          ),
          CupertinoSwitch(
            value: value,
            activeTrackColor: colors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

// ── Join Space Bottom Sheet ─────────────────────────────────────────
class _CreateSpaceSheet extends ConsumerStatefulWidget {
  const _CreateSpaceSheet({required this.userId});
  final String userId;

  @override
  ConsumerState<_CreateSpaceSheet> createState() => _CreateSpaceSheetState();
}

class _CreateSpaceSheetState extends ConsumerState<_CreateSpaceSheet> {
  final _nameController =
      TextEditingController(text: AppConstants.defaultSpaceName);
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createSpace() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(spaceActionProvider.notifier).createSpace(
            name: _nameController.text.trim(),
            userId: widget.userId,
          );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Space created!')),
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create space: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Create a new space',
              style: AppTextStyles.headingSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'A space is where you plan life together',
              style: AppTextStyles.bodyMedium.copyWith(
                color: colors.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Space name',
                labelStyle: AppTextStyles.bodyMedium.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.6),
                ),
                filled: true,
                fillColor: colors.primaryContainer.withValues(alpha: 0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.primary, width: 1.5),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.error),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.error, width: 1.5),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a space name';
                }
                return null;
              },
              onFieldSubmitted: (_) => _createSpace(),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _isLoading ? null : _createSpace,
                style: FilledButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isLoading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.onPrimary,
                        ),
                      )
                    : Text(
                        'Create Space',
                        style: AppTextStyles.button.copyWith(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JoinSpaceSheet extends ConsumerStatefulWidget {
  const _JoinSpaceSheet({required this.userId});
  final String userId;

  @override
  ConsumerState<_JoinSpaceSheet> createState() => _JoinSpaceSheetState();
}

class _JoinSpaceSheetState extends ConsumerState<_JoinSpaceSheet> {
  final _inviteCodeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _inviteCodeController.dispose();
    super.dispose();
  }

  Future<void> _joinSpace() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(spaceActionProvider.notifier).joinSpace(
            inviteCode: _inviteCodeController.text.trim(),
            userId: widget.userId,
          );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully joined the space!')),
        );
      }
    } on SpaceNotFoundException {
      _showError('No space found with that invite code');
    } on AlreadyMemberException {
      _showError('You are already a member of this space');
    } on Exception catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Join a space',
              style: AppTextStyles.headingSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Enter the invite code from your partner',
              style: AppTextStyles.bodyMedium.copyWith(
                color: colors.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _inviteCodeController,
              decoration: InputDecoration(
                labelText: 'Invite code',
                labelStyle: AppTextStyles.bodyMedium.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.6),
                ),
                filled: true,
                fillColor: colors.primaryContainer.withValues(alpha: 0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.primary, width: 1.5),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.error),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.error, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.done,
              style: AppTextStyles.headingSmall.copyWith(letterSpacing: 4),
              textAlign: TextAlign.center,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter an invite code';
                }
                if (value.trim().length != AppConstants.inviteCodeLength) {
                  return 'Invite code must be ${AppConstants.inviteCodeLength} characters';
                }
                return null;
              },
              onFieldSubmitted: (_) => _joinSpace(),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _isLoading ? null : _joinSpace,
                style: FilledButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isLoading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.onPrimary,
                        ),
                      )
                    : Text(
                        'Join Space',
                        style: AppTextStyles.button.copyWith(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
