Run the Dart build_runner to regenerate freezed models and JSON serialization code.

```bash
dart run build_runner build --delete-conflicting-outputs
```

After completion:
- Report which files were generated/updated
- If there are errors, check that model source files have correct `part` directives
- Remind: never edit `*.freezed.dart` or `*.g.dart` files directly
