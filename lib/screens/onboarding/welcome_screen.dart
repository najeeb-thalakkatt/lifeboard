import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:lifeboard/core/constants.dart';
import 'package:lifeboard/theme/app_colors.dart';
import 'package:lifeboard/theme/app_text_styles.dart';

/// Onboarding welcome screen with logo, tagline, and auth entry points.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppColorsExtension>()!;
    final bgColor = ext.scaffold;
    // On the branded splash, text/icons sit on the teal/dark background
    const onBgColor = Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // Logo
              Image.asset(
                'assets/images/app_icon.png',
                width: 160,
                height: 160,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.kayaking,
                  size: 120,
                  color: onBgColor.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 24),

              // App name
              Text(
                AppConstants.appName,
                style: AppTextStyles.headingLarge.copyWith(
                  color: onBgColor,
                  fontSize: 32,
                ),
              ),
              const SizedBox(height: 8),

              // Tagline
              Text(
                AppConstants.tagline,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: onBgColor.withValues(alpha: 0.85),
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(flex: 3),

              // Get Started button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: () => context.go('/auth?mode=signup'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: onBgColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Get Started',
                    style: AppTextStyles.button.copyWith(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Log In button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: TextButton(
                  onPressed: () => context.go('/auth?mode=login'),
                  style: TextButton.styleFrom(
                    foregroundColor: onBgColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Log In',
                    style: AppTextStyles.button.copyWith(
                      color: onBgColor,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
