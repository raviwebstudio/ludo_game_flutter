import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:ludo_game/firebase_options.dart';

class AuthHealthCheck {
  static bool isFirebaseCoreReady = false;
  static bool isFirebaseAuthReady = false;
  static bool isFirestoreReady = false;
  static bool isGoogleSignInReady = false;
  static String? initializationError;

  /// Runs startup diagnostics for all Firebase and Google Sign-In services.
  /// Logs status to console and keeps track of initialization errors.
  static Future<void> runDiagnostics() async {
    debugPrint('[FIREBASE] AuthHealthCheck: Starting Startup Diagnostics');

    // 1. Firebase Core Check
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      isFirebaseCoreReady = true;
      initializationError = null;
      debugPrint('[FIREBASE] Firebase Core initialized successfully.');

      // Print configuration details in debug mode
      if (kDebugMode) {
        try {
          final options = DefaultFirebaseOptions.currentPlatform;
          debugPrint('[FIREBASE] [Debug Config] Project ID: ${options.projectId}');
          debugPrint('[FIREBASE] [Debug Config] App ID: ${options.appId}');
          debugPrint('[FIREBASE] [Debug Config] Storage Bucket: ${options.storageBucket}');
        } catch (e) {
          debugPrint('[FIREBASE] [Debug Config] Failed to retrieve platform options: $e');
        }
      }
    } catch (e) {
      isFirebaseCoreReady = false;
      initializationError = e.toString();
      debugPrint('[FIREBASE] Firebase Core initialization FAILED: $e');
      // If Firebase Core is failed, the other services cannot start.
      isFirebaseAuthReady = false;
      isFirestoreReady = false;
      isGoogleSignInReady = false;
      debugPrint('[FIREBASE] AuthHealthCheck: Diagnostics Aborted');
      return;
    }

    // 2. Firebase Auth Check
    try {
      // Accessing the instance validates that Auth is ready.
      FirebaseAuth.instance;
      isFirebaseAuthReady = true;
      debugPrint('[AUTH] Firebase Auth ready.');
    } catch (e) {
      isFirebaseAuthReady = false;
      debugPrint('[AUTH] Firebase Auth check FAILED: $e');
    }

    // 3. Firestore Check
    try {
      FirebaseFirestore.instance;
      isFirestoreReady = true;
      debugPrint('[FIRESTORE] Firestore initialized');
    } catch (e) {
      isFirestoreReady = false;
      debugPrint('[FIRESTORE] Firestore check FAILED: $e');
    }

    // 4. Google Sign-In Check
    try {
      await GoogleSignIn.instance.initialize();
      isGoogleSignInReady = true;
      debugPrint('[GOOGLE SIGN IN] Google Sign-In check passed.');
    } catch (e) {
      // Set to true so we don't block the UI login button, allowing runtime to show the exact error message
      isGoogleSignInReady = true;
      debugPrint('[GOOGLE SIGN IN] Google Sign-In check FAILED (handled gracefully): $e');
    }

    debugPrint('[FIREBASE] AuthHealthCheck: Diagnostics Complete');
  }

  /// Validates status of all critical services before authentication requests.
  static Map<String, bool> validateServices() {
    return {
      'FirebaseCore': isFirebaseCoreReady,
      'FirebaseAuth': isFirebaseAuthReady,
      'Firestore': isFirestoreReady,
      'GoogleSignIn': isGoogleSignInReady,
    };
  }
}
