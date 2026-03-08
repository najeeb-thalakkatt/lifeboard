import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lifeboard/providers/space_provider.dart';
import 'package:lifeboard/screens/homepad/chores_tab.dart';
import 'package:lifeboard/screens/homepad/search_add_chore_sheet.dart';
import 'package:lifeboard/theme/app_colors.dart';
import 'package:lifeboard/widgets/app_shell_bar.dart';

/// Standalone chores screen — one of the 3 main tabs.
class ChoresScreen extends ConsumerWidget {
  const ChoresScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spaceId = ref.watch(selectedSpaceProvider);

    if (spaceId == null) {
      return const Scaffold(
        appBar: AppShellBar(currentTab: AppTab.chores),
        body: Center(
          child: Text('Join or create a space to manage chores'),
        ),
      );
    }

    return Scaffold(
      appBar: const AppShellBar(currentTab: AppTab.chores),
      body: ChoresTab(spaceId: spaceId),
      floatingActionButton: Builder(
        builder: (context) {
          final fab = FloatingActionButton(
            onPressed: () => _showSearchAddChoreSheet(context, spaceId),
            tooltip: 'Add chore',
            child: const Icon(Icons.add),
          );
          if (Theme.of(context).brightness == Brightness.dark) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.darkPrimary.withValues(alpha: 0.3),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: fab,
            );
          }
          return fab;
        },
      ),
    );
  }

  void _showSearchAddChoreSheet(BuildContext context, String spaceId) {
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SearchAddChoreSheet(spaceId: spaceId),
    );
  }
}
