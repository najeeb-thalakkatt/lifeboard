Run project health checks and report results concisely.

1. Run `flutter analyze` — report any errors/warnings
2. Run `flutter test` — report pass/fail count
3. Run `flutter pub outdated --no-dev-dependencies` — flag any major version bumps available
4. Check if build_runner output is stale: compare timestamps of `lib/models/*.dart` vs `lib/models/*.freezed.dart`

Report a short summary table:
| Check | Status |
|-------|--------|
| Analyze | ✅ clean / ❌ N issues |
| Tests | ✅ N passed / ❌ N failed |
| Deps | ✅ current / ⚠️ N outdated |
| Codegen | ✅ fresh / ⚠️ stale |
