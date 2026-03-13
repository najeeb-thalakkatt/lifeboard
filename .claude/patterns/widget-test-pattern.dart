// Pattern: Widget test with theme and provider setup
// Source: test/task_card_test.dart
// Usage: All widget tests need MaterialApp + theme wrapping

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeboard/theme/app_theme.dart';

// ── Basic widget test ──────────────────────────────────────

void main() {
  testWidgets('ExampleWidget displays title', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Override providers that the widget depends on
          // exampleProvider.overrideWith((ref) => FakeExampleNotifier()),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: ExampleWidget(title: 'Test'),
          ),
        ),
      ),
    );

    expect(find.text('Test'), findsOneWidget);
  });

  // ── Test with async data ─────────────────────────────────

  testWidgets('shows loading then data', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itemsProvider.overrideWith((ref, params) =>
              Stream.value([ItemModel(id: '1', title: 'Item')])),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const ItemsScreen(),
        ),
      ),
    );

    // Initial: loading
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // After stream emits:
    await tester.pumpAndSettle();
    expect(find.text('Item'), findsOneWidget);
  });
}

// Key points:
// 1. Always wrap in ProviderScope + MaterialApp with AppTheme.light
// 2. Override providers that fetch data (don't hit real Firestore)
// 3. Use pumpAndSettle() for async operations
// 4. For services: use mocktail (MockClass extends Mock implements RealClass)
// 5. For Firestore: use fake_cloud_firestore package
