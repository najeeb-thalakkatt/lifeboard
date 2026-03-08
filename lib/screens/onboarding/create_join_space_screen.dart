import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lifeboard/core/constants.dart';
import 'package:lifeboard/providers/space_provider.dart';
import 'package:lifeboard/core/errors/app_exceptions.dart';
import 'package:lifeboard/theme/app_colors.dart';
import 'package:lifeboard/theme/app_text_styles.dart';

/// Screen where users choose to create a new space or join an existing one.
class CreateJoinSpaceScreen extends ConsumerStatefulWidget {
  const CreateJoinSpaceScreen({super.key});

  @override
  ConsumerState<CreateJoinSpaceScreen> createState() =>
      _CreateJoinSpaceScreenState();
}

class _CreateJoinSpaceScreenState extends ConsumerState<CreateJoinSpaceScreen> {
  bool _showCreateForm = false;
  bool _showJoinForm = false;
  bool _isLoading = false;

  final _spaceNameController =
      TextEditingController(text: AppConstants.defaultSpaceName);
  final _inviteCodeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _spaceNameController.dispose();
    _inviteCodeController.dispose();
    super.dispose();
  }

  Future<void> _createSpace() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      final space = await ref.read(spaceActionProvider.notifier).createSpace(
            name: _spaceNameController.text.trim(),
            userId: user.uid,
          );
      if (mounted) {
        context.go('/invite', extra: space);
      }
    } on Exception catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _joinSpace() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(spaceActionProvider.notifier).joinSpace(
            inviteCode: _inviteCodeController.text.trim(),
            userId: user.uid,
          );
      if (mounted) {
        context.go('/board');
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
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          'Get Started',
          style: AppTextStyles.headingSmall,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),

                // Greeting
                Text(
                  'Set up your space',
                  style: AppTextStyles.headingMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'A space is where you and your partner plan life together.',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: colors.onSurface.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Create Space option
                _OptionCard(
                  icon: Icons.add_circle_outline,
                  title: 'Start a new space',
                  subtitle: 'Create a shared space and invite your partner',
                  isExpanded: _showCreateForm,
                  onTap: () {
                    setState(() {
                      _showCreateForm = !_showCreateForm;
                      _showJoinForm = false;
                    });
                  },
                ),

                if (_showCreateForm) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _spaceNameController,
                    decoration: _inputDecoration('Space name'),
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
                  const SizedBox(height: 16),
                  SizedBox(
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
                              style:
                                  AppTextStyles.button.copyWith(fontSize: 16),
                            ),
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Join Space option
                _OptionCard(
                  icon: Icons.group_add_outlined,
                  title: 'Join a space',
                  subtitle: 'Enter an invite code from your partner',
                  isExpanded: _showJoinForm,
                  onTap: () {
                    setState(() {
                      _showJoinForm = !_showJoinForm;
                      _showCreateForm = false;
                    });
                  },
                ),

                if (_showJoinForm) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _inviteCodeController,
                    decoration: _inputDecoration('Invite code'),
                    textCapitalization: TextCapitalization.characters,
                    textInputAction: TextInputAction.done,
                    style: AppTextStyles.headingSmall.copyWith(
                      letterSpacing: 4,
                    ),
                    textAlign: TextAlign.center,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter an invite code';
                      }
                      if (value.trim().length !=
                          AppConstants.inviteCodeLength) {
                        return 'Invite code must be ${AppConstants.inviteCodeLength} characters';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => _joinSpace(),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
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
                              style:
                                  AppTextStyles.button.copyWith(fontSize: 16),
                            ),
                    ),
                  ),
                ],

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    final colors = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
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
    );
  }
}

/// Tappable card for create/join options.
class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isExpanded,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isExpanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppColorsExtension>()!;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isExpanded
              ? colors.primaryContainer.withValues(alpha: 0.4)
              : colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isExpanded ? colors.primary : ext.divider,
            width: isExpanded ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: ext.cardShadow,
              blurRadius: isExpanded ? 8 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: colors.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  )),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption.copyWith(
                      color: colors.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isExpanded
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
              color: colors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
