Build a release for the specified platform. Ask user for: **platform** (ios, android, web).

Steps by platform:

**iOS:**
```bash
flutter build ios --release
```
- Requires Xcode 15+, valid signing config
- Bundle ID: `com.codehive.lifeboard`
- Min deployment: iOS 15.0

**Android:**
```bash
flutter build apk --release
# Or for Play Store:
flutter build appbundle --release
```
- Requires release keystore (check `android/key.properties`)
- Currently using debug signing — warn user if no release config

**Web:**
```bash
flutter build web --release
```
- Output in `build/web/`
- Can deploy to Firebase Hosting: `firebase deploy --only hosting`

After build: report output path and file size.
