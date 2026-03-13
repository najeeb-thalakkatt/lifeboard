Scaffold a new screen. Ask the user for: **screen name** and **navigation type** (shell tab or full-screen push).

Follow the pattern in `.claude/patterns/navigation-pattern.dart`:

1. Create `lib/screens/{name}/{name}_screen.dart`:
   - `ConsumerWidget` (or `ConsumerStatefulWidget` if needs local state)
   - Use `SharedAppBar` or `AppShellBar` depending on context
   - Apply `AppColors`, `AppTextStyles` from theme
   - Include empty state with emoji
2. Register route in `lib/app.dart`:
   - **Shell route**: Add under `ShellRoute` children (gets bottom nav)
   - **Full-screen**: Add with `parentNavigatorKey: rootNavigatorKey` (no bottom nav)
3. Run `flutter analyze` to verify
