import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lifeboard/theme/app_colors.dart';
import 'package:lifeboard/widgets/bottom_nav_bar.dart';

/// Responsive navigation shell that adapts to screen width:
/// - Mobile (< 600px): bottom navigation bar
/// - Tablet (600–1024px): navigation rail
/// - Desktop (> 1024px): permanent side drawer
class ResponsiveShell extends StatelessWidget {
  const ResponsiveShell({super.key, required this.child});
  final Widget child;

  static const _paths = ['/spaces', '/weekly', '/activity', '/profile'];

  static const _destinations = [
    _NavItem(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      label: 'Spaces',
    ),
    _NavItem(
      icon: Icons.calendar_today_outlined,
      selectedIcon: Icons.calendar_today,
      label: 'This Week',
    ),
    _NavItem(
      icon: Icons.notifications_outlined,
      selectedIcon: Icons.notifications,
      label: 'Activity',
    ),
    _NavItem(
      icon: Icons.person_outlined,
      selectedIcon: Icons.person,
      label: 'Profile',
    ),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final index = _paths.indexWhere(location.startsWith);
    return index < 0 ? 0 : index;
  }

  void _onNavigate(BuildContext context, int index) {
    context.go(_paths[index]);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        // ── Desktop (> 1024px): side drawer ───────────────
        if (width > 1024) {
          return _DesktopLayout(
            currentIndex: _currentIndex(context),
            onNavigate: (i) => _onNavigate(context, i),
            child: child,
          );
        }

        // ── Tablet (600–1024px): navigation rail ──────────
        if (width >= 600) {
          return _TabletLayout(
            currentIndex: _currentIndex(context),
            onNavigate: (i) => _onNavigate(context, i),
            child: child,
          );
        }

        // ── Mobile (< 600px): bottom nav bar ─────────────
        return _MobileLayout(
          currentIndex: _currentIndex(context),
          onNavigate: (i) => _onNavigate(context, i),
          child: child,
        );
      },
    );
  }
}

// ── Nav Item Data ─────────────────────────────────────────────────

class _NavItem {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

// ── Mobile Layout (Bottom Nav) ────────────────────────────────────

class _MobileLayout extends StatelessWidget {
  const _MobileLayout({
    required this.currentIndex,
    required this.onNavigate,
    required this.child,
  });
  final int currentIndex;
  final ValueChanged<int> onNavigate;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavBar(
        currentIndex: currentIndex,
        onDestinationSelected: onNavigate,
      ),
    );
  }
}

// ── Tablet Layout (Navigation Rail) ───────────────────────────────

class _TabletLayout extends StatelessWidget {
  const _TabletLayout({
    required this.currentIndex,
    required this.onNavigate,
    required this.child,
  });
  final int currentIndex;
  final ValueChanged<int> onNavigate;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: currentIndex,
            onDestinationSelected: onNavigate,
            backgroundColor: AppColors.surface,
            indicatorColor: AppColors.primaryLight,
            labelType: NavigationRailLabelType.all,
            leading: const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Icon(
                Icons.kayaking,
                color: AppColors.primaryDark,
                size: 32,
                semanticLabel: 'Lifeboard',
              ),
            ),
            destinations: ResponsiveShell._destinations.map((d) {
              return NavigationRailDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.selectedIcon),
                label: Text(d.label),
              );
            }).toList(),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}

// ── Desktop Layout (Side Drawer) ──────────────────────────────────

class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout({
    required this.currentIndex,
    required this.onNavigate,
    required this.child,
  });
  final int currentIndex;
  final ValueChanged<int> onNavigate;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          SizedBox(
            width: 240,
            child: Material(
              color: AppColors.surface,
              elevation: 2,
              child: Column(
                children: [
                  // ── Drawer Header ───────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.kayaking,
                          color: AppColors.primaryDark,
                          size: 28,
                          semanticLabel: 'Lifeboard',
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Lifeboard',
                          style: GoogleFonts.nunito(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // ── Nav Items ───────────────────────────────
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: ResponsiveShell._destinations.length,
                      itemBuilder: (context, index) {
                        final dest = ResponsiveShell._destinations[index];
                        final isSelected = index == currentIndex;

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 2,
                          ),
                          child: ListTile(
                            leading: Icon(
                              isSelected ? dest.selectedIcon : dest.icon,
                              color: isSelected
                                  ? AppColors.primaryDark
                                  : Colors.grey,
                            ),
                            title: Text(
                              dest.label,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isSelected
                                    ? AppColors.primaryDark
                                    : AppColors.textPrimary,
                              ),
                            ),
                            selected: isSelected,
                            selectedTileColor: AppColors.primaryLight,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            onTap: () => onNavigate(index),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}
