import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lifeboard/core/utils/validators.dart';
import 'package:lifeboard/providers/auth_provider.dart';
import 'package:lifeboard/core/errors/app_exceptions.dart';
import 'package:lifeboard/theme/app_colors.dart';
import 'package:lifeboard/theme/app_text_styles.dart';

/// Unified auth screen supporting sign-up and login modes.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key, this.isSignUp = true});

  final bool isSignUp;

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  late bool _isSignUp = widget.isSignUp;
  bool _isLoading = false;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _submitEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final authService = ref.read(authServiceProvider);
      if (_isSignUp) {
        await authService.signUpWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          displayName: _displayNameController.text.trim(),
        );
      } else {
        await authService.signInWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }
      // GoRouter redirect handles navigation on auth state change.
    } on AuthCancelledException {
      // User cancelled — do nothing.
    } on FirebaseException catch (e) {
      _showError(e.message ?? 'Authentication failed');
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authServiceProvider).signInWithGoogle();
    } on AuthCancelledException {
      // User cancelled — do nothing.
    } on FirebaseException catch (e) {
      _showError(e.message ?? 'Google sign-in failed');
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithApple() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authServiceProvider).signInWithApple();
    } on AuthCancelledException {
      // User cancelled — do nothing.
    } on FirebaseException catch (e) {
      _showError(e.message ?? 'Apple sign-in failed');
    } catch (e) {
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
        backgroundColor: AppColors.error,
      ),
    );
  }

  bool get _showAppleSignIn {
    return defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        kIsWeb;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: BackButton(
          color: colors.primary,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),

              // Title
              Text(
                _isSignUp ? 'Create Account' : 'Welcome Back',
                style: AppTextStyles.headingLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _isSignUp
                    ? 'Start planning life together'
                    : 'Sign in to your account',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (_isSignUp) ...[
                      TextFormField(
                        controller: _displayNameController,
                        decoration: _inputDecoration('Display Name'),
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        validator: Validators.validateDisplayName,
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: _emailController,
                      decoration: _inputDecoration('Email'),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      validator: Validators.validateEmail,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: _inputDecoration('Password').copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: colors.primary,
                          ),
                          onPressed: () {
                            setState(
                                () => _obscurePassword = !_obscurePassword);
                          },
                        ),
                      ),
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      validator: Validators.validatePassword,
                      onFieldSubmitted: (_) => _submitEmail(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Submit button
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _isLoading ? null : _submitEmail,
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
                          _isSignUp ? 'Create Account' : 'Log In',
                          style: AppTextStyles.button.copyWith(fontSize: 16),
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // Divider
              Row(
                children: [
                  Expanded(child: Divider(color: isDark ? AppColors.darkDivider : AppColors.divider)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'or',
                      style: AppTextStyles.caption.copyWith(
                        color: colors.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: isDark ? AppColors.darkDivider : AppColors.divider)),
                ],
              ),
              const SizedBox(height: 24),

              // Google Sign-In
              SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _signInWithGoogle,
                  icon: Text(
                    'G',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colors.primary,
                    ),
                  ),
                  label: Text(
                    'Continue with Google',
                    style: AppTextStyles.button.copyWith(
                      color: colors.primary,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: isDark ? AppColors.darkDivider : AppColors.divider),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),

              // Apple Sign-In (iOS, macOS, Web only)
              if (_showAppleSignIn) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _isLoading ? null : _signInWithApple,
                    icon: const Icon(Icons.apple, size: 24),
                    label: Text(
                      'Continue with Apple',
                      style: AppTextStyles.button,
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // Toggle sign-up / login
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isSignUp
                        ? 'Already have an account?'
                        : "Don't have an account?",
                    style: AppTextStyles.bodyMedium,
                  ),
                  TextButton(
                    onPressed: () => setState(() => _isSignUp = !_isSignUp),
                    child: Text(
                      _isSignUp ? 'Log In' : 'Sign Up',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
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
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
