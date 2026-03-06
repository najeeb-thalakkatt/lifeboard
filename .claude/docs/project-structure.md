# Lifeboard — Project Structure

> Reference file for navigating the codebase. Loaded on demand from CLAUDE.md.

---

```
lifeboard/
├── lib/
│   ├── main.dart
│   ├── app.dart                      # MaterialApp, ProviderScope, GoRouter
│   ├── firebase_options.dart         # Generated Firebase config
│   ├── theme/
│   │   ├── app_colors.dart           # All color constants
│   │   ├── app_theme.dart            # ThemeData (light + dark)
│   │   └── app_text_styles.dart      # Text style definitions
│   ├── core/
│   │   ├── constants.dart            # App-wide constants, label maps
│   │   ├── extensions/               # Dart extensions (DateTime, String, etc.)
│   │   ├── utils/
│   │   │   └── validators.dart       # Form/input validators
│   │   └── errors/
│   │       └── app_exceptions.dart   # Custom exceptions (AuthCancelledException, etc.)
│   ├── models/                       # Data classes (freezed + generated .freezed.dart/.g.dart)
│   │   ├── user_model.dart
│   │   ├── space_model.dart
│   │   ├── board_model.dart
│   │   ├── task_model.dart
│   │   ├── comment_model.dart
│   │   └── activity_model.dart
│   ├── providers/                    # Riverpod providers
│   │   ├── auth_provider.dart
│   │   ├── space_provider.dart
│   │   ├── board_provider.dart
│   │   ├── task_provider.dart
│   │   ├── comment_provider.dart
│   │   ├── activity_provider.dart
│   │   ├── dashboard_provider.dart   # spaceTaskSummaryProvider (per-space task counts)
│   │   ├── profile_provider.dart
│   │   └── weekly_provider.dart
│   ├── services/                     # Firebase service wrappers
│   │   ├── auth_service.dart
│   │   ├── firestore_service.dart
│   │   ├── storage_service.dart
│   │   └── notification_service.dart
│   ├── screens/
│   │   ├── onboarding/
│   │   │   ├── auth_screen.dart          # Unified sign-up/login screen
│   │   │   ├── welcome_screen.dart
│   │   │   ├── create_join_space_screen.dart
│   │   │   └── invite_partner_screen.dart
│   │   ├── splash/
│   │   │   └── splash_screen.dart
│   │   ├── home/
│   │   │   └── home_dashboard_screen.dart  # Auto-redirects to last visited space
│   │   ├── board/
│   │   │   ├── board_view_screen.dart
│   │   │   ├── kanban_column.dart
│   │   │   └── compact_kanban_column.dart
│   │   ├── task/
│   │   │   └── task_detail_screen.dart
│   │   ├── weekly/
│   │   │   ├── weekly_view_screen.dart
│   │   │   └── plan_week_sheet.dart
│   │   ├── activity/
│   │   │   └── activity_feed_screen.dart
│   │   ├── debug/                        # Debug-only screens
│   │   └── profile/
│   │       └── profile_settings_screen.dart
│   └── widgets/                      # Shared/reusable widgets
│       ├── task_card.dart
│       ├── emoji_tag_picker.dart
│       ├── celebration_overlay.dart
│       ├── avatar_widget.dart
│       ├── bottom_nav_bar.dart
│       ├── shared_app_bar.dart
│       ├── comments_section.dart
│       ├── responsive_shell.dart
│       └── stagger_animation.dart    # Reusable StaggeredListItem widget
├── assets/
│   ├── images/                       # Logo, onboarding illustrations
│   ├── animations/                   # Lottie JSON files (confetti, etc.)
│   └── fonts/                        # Nunito, Inter font files
├── test/
│   ├── unit/
│   ├── widget/
│   └── integration/
├── firebase/
│   ├── firestore.rules
│   ├── firestore.indexes.json
│   ├── storage.rules
│   └── functions/                    # Cloud Functions (TypeScript)
│       ├── src/
│       │   ├── index.ts              # Function exports
│       │   ├── notifications.ts      # FCM triggers
│       │   ├── fcm.ts                # FCM helpers
│       │   └── activity.ts           # Activity feed writer
│       └── package.json
├── pubspec.yaml
├── analysis_options.yaml
├── CLAUDE.md
├── plan.md
└── features.md
```
