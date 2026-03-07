import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Encapsulates all Sentry SDK interactions.
///
/// DSN is read from `--dart-define=SENTRY_DSN=...` at build time.
/// When empty (e.g. local dev), all operations silently no-op.
class SentryService {
  SentryService({String? dsn})
      : _dsn = dsn ??
            const String.fromEnvironment('SENTRY_DSN', defaultValue: '');

  final String _dsn;

  bool get isEnabled => _dsn.isNotEmpty;

  /// Captures an exception with optional stack trace and tags.
  Future<void> captureException(
    dynamic exception, {
    StackTrace? stackTrace,
    Map<String, String>? tags,
  }) async {
    if (!isEnabled) return;
    await Sentry.captureException(
      exception,
      stackTrace: stackTrace,
      withScope: tags != null
          ? (scope) {
              for (final entry in tags.entries) {
                scope.setTag(entry.key, entry.value);
              }
            }
          : null,
    );
  }

  /// Sets the authenticated user on the Sentry scope.
  void setUser({
    required String id,
    String? email,
    String? username,
  }) {
    if (!isEnabled) return;
    Sentry.configureScope((scope) {
      scope.setUser(SentryUser(
        id: id,
        email: email,
        username: username,
      ));
    });
  }

  /// Clears the user from the Sentry scope (on logout).
  void clearUser() {
    if (!isEnabled) return;
    Sentry.configureScope((scope) {
      scope.setUser(null);
    });
  }
}

/// Global provider for [SentryService].
final sentryServiceProvider = Provider<SentryService>((ref) {
  return SentryService();
});
