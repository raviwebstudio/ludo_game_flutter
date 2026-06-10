import 'package:firebase_auth/firebase_auth.dart';

class AuthErrorHandler {
  /// Returns the exact message for any Firebase Auth or generic exception.
  static String getFriendlyErrorMessage(dynamic e) {
    if (e is FirebaseAuthException) {
      return e.message ?? e.toString();
    }
    return e.toString();
  }
}
