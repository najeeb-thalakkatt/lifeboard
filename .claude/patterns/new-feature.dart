// Pattern: Feature folder structure
// Source: lib/screens/board/ + lib/providers/task_provider.dart + lib/models/task_model.dart
// Usage: Reference when scaffolding a new feature end-to-end

// A complete feature in Lifeboard consists of:
//
// lib/
// ├── models/
// │   └── {feature}_model.dart          # Freezed model + fromFirestore
// │   └── {feature}_model.freezed.dart  # Generated (never edit)
// │   └── {feature}_model.g.dart        # Generated (never edit)
// ├── providers/
// │   └── {feature}_provider.dart       # StreamProvider (reads) + StateNotifier (writes)
// ├── services/
// │   └── firestore_service.dart        # Add CRUD methods to existing service
// ├── screens/
// │   └── {feature}/
// │       └── {feature}_screen.dart     # Main screen (ConsumerWidget)
// │       └── {feature}_detail.dart     # Detail/edit screen (if needed)
// │       └── {feature}_sheet.dart      # Bottom sheet (if needed)
// ├── widgets/
// │   └── {feature}_card.dart           # Card widget (if list-based)
// └── app.dart                          # Add GoRoute

// Checklist for new feature:
// [ ] 1. Create model with freezed + fromFirestore
// [ ] 2. Run build_runner to generate .freezed.dart + .g.dart
// [ ] 3. Add Firestore CRUD methods to FirestoreService
// [ ] 4. Create provider (StreamProvider.family + StateNotifier)
// [ ] 5. Create screen(s) in lib/screens/{feature}/
// [ ] 6. Create card widget if showing in a list
// [ ] 7. Register route in app.dart
// [ ] 8. Add to bottom nav if it's a main tab (update ResponsiveShell._paths)
// [ ] 9. Write tests (unit for provider, widget for screen)
// [ ] 10. Run flutter analyze
