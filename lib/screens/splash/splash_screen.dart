import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lifeboard/theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        final user = FirebaseAuth.instance.currentUser;
        context.go(user != null ? '/spaces' : '/welcome');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = AppColors.background;
    final textColor = isDark ? colors.onSurface : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/app_icon.png',
              width: 160,
              height: 160,
            ),
            const SizedBox(height: 32),
            Text(
              'Lifeboard',
              style: GoogleFonts.nunito(
                fontSize: 36,
                fontWeight: FontWeight.w700,
                color: textColor,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Plan life together, simply.',
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: textColor.withValues(alpha: 0.85),
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
