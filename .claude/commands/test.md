Run tests. Accepts optional argument: feature name or file path.

If argument provided:
```bash
flutter test test/{argument}_test.dart --reporter expanded
```

If no argument:
```bash
flutter test --reporter expanded
```

For coverage:
```bash
flutter test --coverage
```

After running:
- Report pass/fail count
- For failures: show the failing test name, expected vs actual, and the relevant source file
- Suggest fixes for common issues (missing mocks, widget test setup, provider overrides)
