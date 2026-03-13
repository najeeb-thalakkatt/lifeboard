import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lifeboard/services/biometric_service.dart';
import 'package:lifeboard/theme/app_colors.dart';

/// Full-screen lock overlay shown when biometric lock is enabled
/// and the app resumes from background.
class AppLockScreen extends StatefulWidget {
  const AppLockScreen({super.key, required this.onUnlocked});

  /// Called when the user successfully authenticates.
  final VoidCallback onUnlocked;

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  final _biometricService = BiometricService();
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    // Auto-trigger biometric prompt on show
    WidgetsBinding.instance.addPostFrameCallback((_) => _authenticate());
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;
    setState(() => _isAuthenticating = true);

    final success = await _biometricService.authenticate(
      reason: 'Unlock Lifeboard to access your family board',
    );

    if (success) {
      widget.onUnlocked();
    }

    if (mounted) {
      setState(() => _isAuthenticating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : AppColors.primaryLight,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline,
              size: 64,
              color: isDark ? AppColors.darkPrimary : AppColors.primaryDark,
            ),
            const SizedBox(height: 24),
            Text(
              'Lifeboard is Locked',
              style: GoogleFonts.nunito(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Authenticate to continue',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isDark
                    ? Colors.white70
                    : AppColors.primaryDark.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 40),
            FilledButton.icon(
              onPressed: _isAuthenticating ? null : _authenticate,
              icon: const Icon(Icons.fingerprint, size: 24),
              label: Text(
                _isAuthenticating ? 'Authenticating...' : 'Unlock',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor:
                    isDark ? AppColors.darkPrimary : AppColors.primaryDark,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
