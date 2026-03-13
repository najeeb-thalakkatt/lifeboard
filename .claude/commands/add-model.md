Create a new freezed model. Ask the user for: **model name** and **fields**.

Follow the pattern in `.claude/patterns/model-pattern.dart`:

1. Create `lib/models/{name}_model.dart` with:
   - `part '{name}_model.freezed.dart';`
   - `part '{name}_model.g.dart';`
   - `@freezed` class with all fields
   - `fromJson` factory
   - `fromFirestore` factory (handle Timestamp → DateTime conversion)
   - `toFirestore()` method
2. Run `dart run build_runner build --delete-conflicting-outputs`
3. Verify generated files exist
4. Run `flutter analyze`
