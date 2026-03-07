import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lifeboard/providers/activity_provider.dart';
import 'package:lifeboard/providers/chore_provider.dart';
import 'package:lifeboard/providers/homepad_provider.dart';

/// Bottom navigation destinations for the app shell.
///
/// Uses Material 3 [NavigationBar] which picks up the theme from
/// [AppTheme.light.navigationBarTheme].
class BottomNavBar extends ConsumerWidget {
  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadActivityCountProvider).valueOrNull ?? 0;
    final homePadBadge = ref.watch(homePadBadgeCountProvider);
    final choreBadge = ref.watch(choreBadgeCountProvider);
    final combinedBadge = homePadBadge + choreBadge;

    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onDestinationSelected,
      destinations: [
        const NavigationDestination(
          icon: Icon(Icons.grid_view_outlined),
          selectedIcon: Icon(Icons.grid_view),
          label: 'Spaces',
        ),
        const NavigationDestination(
          icon: Icon(Icons.calendar_today_outlined),
          selectedIcon: Icon(Icons.calendar_today),
          label: 'This Week',
        ),
        NavigationDestination(
          icon: Badge(
            isLabelVisible: combinedBadge > 0,
            label: Text(combinedBadge > 99 ? '99+' : '$combinedBadge'),
            child: const Icon(Icons.shopping_cart_outlined),
          ),
          selectedIcon: Badge(
            isLabelVisible: combinedBadge > 0,
            label: Text(combinedBadge > 99 ? '99+' : '$combinedBadge'),
            child: const Icon(Icons.shopping_cart),
          ),
          label: 'HomePad',
        ),
        NavigationDestination(
          icon: Badge(
            isLabelVisible: unreadCount > 0,
            label: Text(unreadCount > 99 ? '99+' : '$unreadCount'),
            child: const Icon(Icons.notifications_outlined),
          ),
          selectedIcon: Badge(
            isLabelVisible: unreadCount > 0,
            label: Text(unreadCount > 99 ? '99+' : '$unreadCount'),
            child: const Icon(Icons.notifications),
          ),
          label: 'Activity',
        ),
        const NavigationDestination(
          icon: Icon(Icons.person_outlined),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}
