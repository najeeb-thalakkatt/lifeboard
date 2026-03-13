import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lifeboard/theme/app_colors.dart';

/// Feature tour shown to first-time users before authentication.
class FeatureTourScreen extends StatefulWidget {
  const FeatureTourScreen({super.key});

  static const prefKey = 'has_seen_tour';

  /// Returns true if the user has already seen the tour.
  static Future<bool> hasSeenTour() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(prefKey) ?? false;
  }

  /// Marks the tour as seen.
  static Future<void> markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefKey, true);
  }

  @override
  State<FeatureTourScreen> createState() => _FeatureTourScreenState();
}

class _FeatureTourScreenState extends State<FeatureTourScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  static const _pages = [
    _TourPage(
      icon: Icons.dashboard_rounded,
      emoji: '\u{1F4CB}',
      title: 'Plan Life Together',
      subtitle:
          'A shared kanban board for your family.\nDrag tasks, set priorities, stay in sync.',
      color: AppColors.primaryDark,
    ),
    _TourPage(
      icon: Icons.sync_rounded,
      emoji: '\u{1F504}',
      title: 'Stay In Sync',
      subtitle:
          'Real-time updates across all devices.\nPush notifications keep everyone in the loop.',
      color: AppColors.accentWarm,
    ),
    _TourPage(
      icon: Icons.checklist_rounded,
      emoji: '\u{2705}',
      title: 'Track Everything',
      subtitle:
          'Chores, shopping lists, weekly plans.\nOne calm place for all of life\'s tasks.',
      color: AppColors.statusDone,
    ),
    _TourPage(
      icon: Icons.lock_rounded,
      emoji: '\u{1F512}',
      title: 'Private & Secure',
      subtitle:
          'Face ID protection, offline access,\nand end-to-end family privacy.',
      color: AppColors.primaryDark,
    ),
  ];

  void _next() {
    HapticFeedback.selectionClick();
    if (_currentPage < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  void _finish() async {
    await FeatureTourScreen.markSeen();
    if (mounted) context.go('/welcome');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [Colors.black, const Color(0xFF1C1C1E)]
                : [const Color(0xFFFAFCFC), AppColors.primaryLight],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _finish,
                  child: Text(
                    'Skip',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isDark
                          ? Colors.white60
                          : AppColors.primaryDark.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),

              // Pages
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemBuilder: (context, index) => _pages[index],
                ),
              ),

              // Page indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages.length, (i) {
                  final isActive = i == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isActive
                          ? (isDark ? AppColors.darkPrimary : AppColors.primaryDark)
                          : (isDark ? Colors.white24 : AppColors.primaryDark)
                              .withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 32),

              // CTA button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: _next,
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          isDark ? AppColors.darkPrimary : AppColors.primaryDark,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      _currentPage == _pages.length - 1
                          ? 'Get Started'
                          : 'Next',
                      style: GoogleFonts.nunito(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

/// A single tour page.
class _TourPage extends StatelessWidget {
  const _TourPage({
    required this.icon,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon circle
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.2 : 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 56)),
            ),
          ),
          const SizedBox(height: 40),
          Text(
            title,
            style: GoogleFonts.nunito(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.primaryDark,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 16,
              height: 1.5,
              color: isDark
                  ? Colors.white70
                  : AppColors.primaryDark.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
