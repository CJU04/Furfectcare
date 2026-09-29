import 'package:firebase_auth/firebase_auth.dart';

/// Maps Firebase Auth exceptions to clear, non-technical messages that an
/// everyday user can understand. Raw Firebase error codes are kept in
/// [detail] for developer logging.
class AuthErrorMapper {
  AuthErrorMapper._();

  static String friendlyMessage(Object error,
      {String fallback = 'Something went wrong. Please try again.'}) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'user-not-found':
          return 'No account was found with that email. Please check and try again, or create an account.';
        case 'wrong-password':
        case 'invalid-credential':
        case 'invalid-login-credentials':
          return 'Incorrect email or password. Please try again.';
        case 'user-disabled':
          return 'This account has been disabled. Please contact support.';
        case 'too-many-requests':
          return 'Too many attempts. Please wait a moment and try again.';
        case 'email-already-in-use':
          return 'An account with this email already exists. Try signing in instead.';
        case 'weak-password':
          return 'Your password is too weak. Use at least 6 characters.';
        case 'operation-not-allowed':
          return 'This sign-in option is not enabled. Please try another method.';
        case 'requires-recent-login':
          return 'For your security, please sign in again before changing this.';
        case 'network-request-failed':
          return 'No internet connection. Check your connection and try again.';
        case 'invalid-action-code':
          return 'This password reset link is invalid or has expired. Request a new one.';
        case 'user-mismatch':
          return 'This reset link was issued for a different account.';
        case 'expired-action-code':
          return 'This link has expired. Please request a new one.';
        default:
          return fallback;
      }
    }
    return fallback;
  }

  /// Creates a human-readable error available for logging (never shown raw).
  static String debugDetail(Object error) => error.toString();
}
