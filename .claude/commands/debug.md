Run through the debug checklist to diagnose build/runtime issues.

Execute these steps in order, stopping at the first failure:

1. **`flutter pub get`** — resolve dependencies
2. **`flutter analyze`** — check for static errors
3. **`dart run build_runner build --delete-conflicting-outputs`** — regenerate code
4. **`flutter clean && flutter pub get`** — clean build cache
5. **Platform checks:**
   - iOS: `cd ios && pod install --repo-update && cd ..`
   - Android: Check `android/gradle.properties` JVM args
   - Web: Check `web/index.html` for script issues
6. **`flutter doctor -v`** — environment health

Report findings and suggest fixes for any issues found.
