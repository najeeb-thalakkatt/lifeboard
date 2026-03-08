import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lifeboard/theme/app_colors.dart';
import 'package:lifeboard/providers/chore_provider.dart';
import 'package:lifeboard/providers/homepad_provider.dart';

/// Bottom navigation destinations for the app shell.
///
/// 3 tabs: Board, Chores, Buy List.
/// Activity and Profile are now accessed via app bar icons.
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
    final homePadBadge = ref.watch(homePadBadgeCountProvider);
    final choreBadge = ref.watch(choreBadgeCountProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isDark)
          const Divider(
            height: 0.5,
            thickness: 0.5,
            color: AppColors.darkDivider,
          ),
        NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: onDestinationSelected,
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Board',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: choreBadge > 0,
                label: Text(choreBadge > 99 ? '99+' : '$choreBadge'),
                child: const Icon(Icons.task_alt_outlined),
              ),
              selectedIcon: Badge(
                isLabelVisible: choreBadge > 0,
                label: Text(choreBadge > 99 ? '99+' : '$choreBadge'),
                child: const Icon(Icons.task_alt),
              ),
              label: 'Chores',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: homePadBadge > 0,
                label: Text(homePadBadge > 99 ? '99+' : '$homePadBadge'),
                child: const Icon(Icons.shopping_bag_outlined),
              ),
              selectedIcon: Badge(
                isLabelVisible: homePadBadge > 0,
                label: Text(homePadBadge > 99 ? '99+' : '$homePadBadge'),
                child: const Icon(Icons.shopping_bag),
              ),
              label: 'Buy List',
            ),
          ],
        ),
      ],
    );
  }
}
