import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'package:lifeboard/core/utils/validators.dart';
import 'package:lifeboard/providers/auth_provider.dart';
import 'package:lifeboard/core/errors/app_exceptions.dart';
import 'package:lifeboard/theme/app_colors.dart';

/// Unified auth screen supporting sign-up and login modes.
///
/// Uses a two-zone split layout: gradient brand zone on top,
/// white form panel anchored to bottom.
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
    } on PlatformException catch (e) {
      // Surface a friendly message for common Google Sign-In platform errors.
      if (e.code == 'network_error') {
        _showError('No internet connection. Please check your network and try again.');
      } else {
        _showError('Google sign-in failed. Please try again.');
      }
    } catch (e) {
      _showError('Google sign-in failed. Please try again.');
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
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return;
      _showError('Apple Sign-In is not available. Please try another method.');
    } on FirebaseException catch (e) {
      _showError(e.message ?? 'Apple sign-in failed');
    } catch (e) {
      _showError('Apple sign-in failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendPasswordReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showError('Enter your email address first');
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset email sent. Check your inbox.'),
          ),
        );
      }
    } on FirebaseException catch (e) {
      _showError(e.message ?? 'Could not send reset email');
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
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.background, AppColors.primaryDark],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final h = constraints.maxHeight;
            final isCompact = h < 700;
            final fieldGap = isCompact ? 8.0 : 12.0;
            final sectionGap = isCompact ? 12.0 : 16.0;
            final buttonHeight = isCompact ? 44.0 : 48.0;

            return Column(
              children: [
                // ── Brand Zone (top, flexible) ──────────────────
                Flexible(
                  flex: _isSignUp ? 3 : 4,
                  child: SafeArea(
                    bottom: false,
                    child: Center(
                      child: SingleChildScrollView(
                        child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 2,
                              ),
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/app_icon.png',
                                width: 76,
                                height: 76,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Lifeboard',
                            style: GoogleFonts.nunito(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                          ),
                          if (!isCompact) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Plan life together, simply.',
                              style: GoogleFonts.nunito(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: Colors.white.withValues(alpha: 0.85),
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    ),
                  ),
                ),

                // ── Form Panel (bottom, flexible + scrollable) ──
                Flexible(
                  flex: _isSignUp ? 7 : 6,
                  child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).extension<AppColorsExtension>()!.subtleShadow,
                        blurRadius: 16,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Heading
                          Text(
                            _isSignUp ? 'Create Account' : 'Welcome Back',
                            style: GoogleFonts.nunito(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isSignUp
                                ? 'Start planning life together'
                                : 'Sign in to your account',
                            style: GoogleFonts.nunito(
                              fontSize: 14,
                              color: AppColors.primaryDark.withValues(alpha: 0.5),
                            ),
                          ),
                          SizedBox(height: sectionGap),

                          // Form fields
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                if (_isSignUp) ...[
                                  TextFormField(
                                    controller: _displayNameController,
                                    decoration: _inputDecoration('Display Name'),
                                    textCapitalization:
                                        TextCapitalization.words,
                                    textInputAction: TextInputAction.next,
                                    validator: Validators.validateDisplayName,
                                  ),
                                  SizedBox(height: fieldGap),
                                ],
                                TextFormField(
                                  controller: _emailController,
                                  decoration: _inputDecoration('Email'),
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  autocorrect: false,
                                  validator: Validators.validateEmail,
                                ),
                                SizedBox(height: fieldGap),
                                TextFormField(
                                  controller: _passwordController,
                                  decoration:
                                      _inputDecoration('Password').copyWith(
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: AppColors.primaryDark,
                                      ),
                                      onPressed: () {
                                        setState(() => _obscurePassword =
                                            !_obscurePassword);
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

                          // Forgot password (login mode only)
                          if (!_isSignUp) ...[
                            const SizedBox(height: 4),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed:
                                    _isLoading ? null : _sendPasswordReset,
                                child: Text(
                                  'Forgot Password?',
                                  style: GoogleFonts.nunito(
                                    color: AppColors.primaryDark
                                        .withValues(alpha: 0.6),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          SizedBox(height: sectionGap),

                          // Submit button
                          SizedBox(
                            height: buttonHeight,
                            child: FilledButton(
                              onPressed: _isLoading ? null : _submitEmail,
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primaryDark,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      _isSignUp ? 'Create Account' : 'Log In',
                                      style: GoogleFonts.nunito(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                          SizedBox(height: sectionGap),

                          // "or" divider
                          Row(
                            children: [
                              const Expanded(
                                child: Divider(color: AppColors.primaryLight),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'or',
                                  style: GoogleFonts.nunito(
                                    color: AppColors.primaryDark
                                        .withValues(alpha: 0.4),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const Expanded(
                                child: Divider(color: AppColors.primaryLight),
                              ),
                            ],
                          ),
                          SizedBox(height: sectionGap),

                          // Google Sign-In
                          SizedBox(
                            height: buttonHeight,
                            child: OutlinedButton(
                              onPressed:
                                  _isLoading ? null : _signInWithGoogle,
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                    color: AppColors.primaryLight),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CustomPaint(
                                      painter: _GoogleLogoPainter(),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Continue with Google',
                                    style: GoogleFonts.nunito(
                                      color: AppColors.primaryDark,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Apple Sign-In (iOS, macOS, Web only)
                          if (_showAppleSignIn) ...[
                            SizedBox(height: fieldGap),
                            SizedBox(
                              height: buttonHeight,
                              child: FilledButton.icon(
                                onPressed:
                                    _isLoading ? null : _signInWithApple,
                                icon: const Icon(Icons.apple,
                                    size: 24, color: Colors.white),
                                label: Text(
                                  'Continue with Apple',
                                  style: GoogleFonts.nunito(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF1C1C1E),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                          ],
                          SizedBox(height: sectionGap),

                          // Toggle sign-up / login
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _isSignUp
                                    ? 'Already have an account?'
                                    : "Don't have an account?",
                                style: GoogleFonts.nunito(
                                  color: AppColors.primaryDark
                                      .withValues(alpha: 0.6),
                                  fontSize: 14,
                                ),
                              ),
                              TextButton(
                                onPressed: () =>
                                    setState(() => _isSignUp = !_isSignUp),
                                child: Text(
                                  _isSignUp ? 'Log In' : 'Sign Up',
                                  style: GoogleFonts.nunito(
                                    color: AppColors.primaryDark,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                )),
              ],
            );
          },
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.nunito(
        color: AppColors.primaryDark.withValues(alpha: 0.6),
        fontSize: 14,
      ),
      filled: true,
      fillColor: AppColors.inputFill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            const BorderSide(color: AppColors.primaryDark, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }
}

/// Paints a simplified Google "G" logo with the four brand colors.
class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = size.width * 0.22;

    // Google brand colors for each quadrant
    const colors = [
      Color(0xFFEA4335), // top-left (red)
      Color(0xFFFBBC05), // bottom-left (yellow)
      Color(0xFF34A853), // bottom-right (green)
      Color(0xFF4285F4), // top-right & bar (blue)
    ];

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    // Draw arcs for each color segment
    final rect =
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);
    const sweepAngle = 3.14159 / 2; // 90 degrees
    const startAngles = [
      -3.14159, // 180° (left)
      -3.14159 / 2, // 270° (bottom)
      0.0, // 0° (right)
      3.14159 / 2, // 90° (top)
    ];

    for (var i = 0; i < 4; i++) {
      paint.color = colors[i];
      canvas.drawArc(rect, startAngles[i], sweepAngle, false, paint);
    }

    // Blue horizontal bar (right side of G)
    final barPaint = Paint()
      ..color = colors[3]
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(
        center.dx - strokeWidth * 0.1,
        center.dy - strokeWidth / 2,
        radius,
        strokeWidth,
      ),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
