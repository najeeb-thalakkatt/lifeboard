/// Base class for all Lifeboard app exceptions.
abstract class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => message;
}

// ── Auth Exceptions ────────────────────────────────────────────

/// Thrown when the user cancels a sign-in flow (Google or Apple).
class AuthCancelledException extends AppException {
  const AuthCancelledException() : super('Sign-in was cancelled');
}

// ── Space Exceptions ───────────────────────────────────────────

/// Thrown when an invite code doesn't match any space.
class SpaceNotFoundException extends AppException {
  const SpaceNotFoundException() : super('No space found with that invite code');
}

/// Thrown when the user is already a member of the space.
class AlreadyMemberException extends AppException {
  const AlreadyMemberException() : super('You are already a member of this space');
}
