import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ludo_game/injection.dart';
import 'package:ludo_game/core/services/firebase_service.dart';
import 'package:ludo_game/core/services/player_prefs.dart';
import 'package:ludo_game/features/home/screens/home_screen.dart';
import 'package:ludo_game/features/auth/screens/login_screen.dart';
import 'package:ludo_game/core/constants/colors.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  StreamSubscription<User?>? _authSubscription;
  User? _currentUser;
  bool _loadingData = false;

  @override
  void initState() {
    super.initState();
    final firebaseService = getIt<FirebaseService>();
    _authSubscription = firebaseService.authStateChanges.listen((user) async {
      if (user != null && _currentUser?.uid != user.uid) {
        setState(() {
          _currentUser = user;
          _loadingData = true;
        });
        try {
          await firebaseService.loadDataFromFirestore();
        } catch (e) {
          debugPrint('Failed to load user data: $e');
        } finally {
          if (mounted) {
            setState(() => _loadingData = false);
          }
        }
      } else if (user == null && _currentUser != null) {
        setState(() {
          _currentUser = null;
        });
        await PlayerPrefs.resetStats();
      } else if (_currentUser == null && user != null) {
        setState(() {
          _currentUser = user;
          _loadingData = true;
        });
        try {
          await firebaseService.loadDataFromFirestore();
        } catch (e) {
          debugPrint('Failed to load user data: $e');
        } finally {
          if (mounted) {
            setState(() => _loadingData = false);
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firebaseService = getIt<FirebaseService>();

    return StreamBuilder<User?>(
      stream: firebaseService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting || _loadingData) {
          return const Scaffold(
            backgroundColor: LudoColors.darkNavy,
            body: Center(
              child: CircularProgressIndicator(
                color: LudoColors.brightBlue,
              ),
            ),
          );
        }

        if (snapshot.hasData) {
          return const HomeScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
