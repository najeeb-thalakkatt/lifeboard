Scaffold a new feature. Ask the user for: **feature name** (e.g., "reminders").

Then create these files following project patterns (see `.claude/patterns/`):

1. **Model** (if needed): `lib/models/{name}_model.dart` — freezed + JSON + fromFirestore
2. **Provider**: `lib/providers/{name}_provider.dart` — StreamProvider + StateNotifier
3. **Screen**: `lib/screens/{name}/{name}_screen.dart` — ConsumerWidget with SharedAppBar
4. **Route**: Add GoRoute in `lib/app.dart` (decide: shell route or full-screen)
5. **Test**: `test/{name}_test.dart` — basic widget test scaffold

After scaffolding:
- Run `dart run build_runner build --delete-conflicting-outputs` if a model was created
- Run `flutter analyze` to verify no issues
- List all created files for the user
