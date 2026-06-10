import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ludo_game/injection.dart';
import 'package:ludo_game/core/services/firebase_service.dart';
import 'package:ludo_game/core/services/auth_health_check.dart';
import 'package:ludo_game/core/services/player_prefs.dart';
import 'package:ludo_game/features/home/screens/home_screen.dart';
import 'package:ludo_game/features/auth/screens/login_screen.dart';
import 'package:ludo_game/core/constants/colors.dart';
import 'package:ludo_game/core/constants/text_styles.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isRetrying = false;
  StreamSubscription<void>? _statsSubscription;
  String? _currentSyncedUid;

  @override
  void dispose() {
    _statsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _retryInitialization() async {
    setState(() => _isRetrying = true);
    await AuthHealthCheck.runDiagnostics();
    setState(() => _isRetrying = false);
  }

  /// Listens to user profile updates in Firestore and syncs them to local PlayerPrefs.
  void _setupStatsSync(User user) {
    if (_currentSyncedUid == user.uid) return;
    _statsSubscription?.cancel();
    _currentSyncedUid = user.uid;

    final firebaseService = getIt<FirebaseService>();
    _statsSubscription = firebaseService.userDocStream().listen(
      (snapshot) {
        if (snapshot.exists) {
          final data = snapshot.data();
          if (data != null) {
            final name = data['name'] as String? ?? 'Player';
            final coins = data['coins'] as int? ?? 1000;
            final totalGames = (data['gamesPlayed'] as int? ?? data['totalGames'] as int?) ?? 0;
            final wins = data['wins'] as int? ?? 0;
            final winStreak = data['winStreak'] as int? ?? 0;

            PlayerPrefs.setPlayerName(0, name);
            PlayerPrefs.setCoins(coins);
            PlayerPrefs.setTotalGames(totalGames);
            PlayerPrefs.setWins(wins);
            PlayerPrefs.setWinStreak(winStreak);

            final photoUrl = data['photoUrl'] as String?;
            if (photoUrl != null && photoUrl.isNotEmpty) {
              PlayerPrefs.setPlayerAvatarPath(0, photoUrl);
            }
          }
        }
      },
      onError: (e) {
        debugPrint("AuthGate: Error syncing user stats: $e");
      },
    );
  }

  void _clearStatsSync() {
    _statsSubscription?.cancel();
    _statsSubscription = null;
    _currentSyncedUid = null;
  }

  @override
  Widget build(BuildContext context) {
    // ── Fallback Screen if Firebase Core initialization failed ──
    if (!AuthHealthCheck.isFirebaseCoreReady) {
      return Scaffold(
        backgroundColor: LudoColors.darkNavy,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [LudoColors.darkNavyDark, LudoColors.darkNavy],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.cloud_off,
                      color: LudoColors.redToken,
                      size: 80,
                    ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
                    const SizedBox(height: 24),
                    Text(
                      'Firebase Services Offline',
                      style: LudoTextStyles.displayMedium.copyWith(fontSize: 26),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'We could not connect to Firebase. Authentication and online multiplayer features are disabled.',
                      style: LudoTextStyles.bodyMedium.copyWith(color: LudoColors.textMedium),
                      textAlign: TextAlign.center,
                    ),
                    if (AuthHealthCheck.initializationError != null) ...[
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: Text(
                          AuthHealthCheck.initializationError!,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: LudoColors.redToken,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                    const SizedBox(height: 40),
                    if (_isRetrying)
                      const CircularProgressIndicator(color: LudoColors.brightBlue)
                    else ...[
                      ElevatedButton(
                        onPressed: _retryInitialization,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: LudoColors.brightBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.refresh),
                            const SizedBox(width: 8),
                            Text(
                              'Retry Connection',
                              style: LudoTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: () {
                          // Bypasses login and routes directly to the HomeScreen
                          Navigator.pushReplacementNamed(context, '/home');
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Play Offline / AI Mode',
                          style: LudoTextStyles.bodyLarge,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final firebaseService = getIt<FirebaseService>();

    return StreamBuilder<User?>(
      stream: firebaseService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: LudoColors.darkNavy,
            body: Center(
              child: CircularProgressIndicator(
                color: LudoColors.brightBlue,
              ),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          debugPrint('[Navigation] User is authenticated (UID: ${snapshot.data!.uid}). Showing HomeScreen.');
          _setupStatsSync(snapshot.data!);
          return const HomeScreen();
        }

        debugPrint('[Navigation] User is not authenticated. Showing LoginScreen.');
        _clearStatsSync();
        return const LoginScreen();
      },
    );
  }
}
