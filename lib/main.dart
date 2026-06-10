import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ludo_game/injection.dart';
import 'package:ludo_game/core/services/player_prefs.dart';
import 'package:ludo_game/core/services/auth_health_check.dart';
import 'package:ludo_game/core/theme/app_theme.dart';
import 'package:ludo_game/features/splash/screens/splash_screen.dart';
import 'package:ludo_game/features/home/screens/home_screen.dart';
import 'package:ludo_game/features/game/screens/mode_selector.dart';
import 'package:ludo_game/features/game/screens/player_selector.dart';
import 'package:ludo_game/features/game/screens/game_screen.dart';
import 'package:ludo_game/features/profile/screens/profile_screen.dart';
import 'package:ludo_game/features/profile/screens/edit_profile_screen.dart';
import 'package:ludo_game/features/profile/screens/achievements_screen.dart';
import 'package:ludo_game/features/settings/screens/settings_screen.dart';

// New Firebase screens / gates
import 'package:ludo_game/features/auth/widgets/auth_gate.dart';
import 'package:ludo_game/features/auth/screens/login_screen.dart';
import 'package:ludo_game/features/auth/screens/signup_screen.dart';
import 'package:ludo_game/features/game/screens/online_lobby_screen.dart';
import 'package:ludo_game/features/game/screens/online_waiting_room.dart';
import 'package:ludo_game/features/game/screens/online_game_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Run startup diagnostics and health checks
  await AuthHealthCheck.runDiagnostics();
  
  await PlayerPrefs.init();
  setupDependencyInjection();
  runApp(const LudoGame());
}

class LudoGame extends StatefulWidget {
  const LudoGame({super.key});

  @override
  State<LudoGame> createState() => _LudoGameState();
}

class _LudoGameState extends State<LudoGame> {
  StreamSubscription<void>? _changesSubscription;

  @override
  void initState() {
    super.initState();
    _changesSubscription = PlayerPrefs.changes.listen((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _changesSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ludo Elite',
      theme: AppTheme.ludoTheme,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/auth': (context) => const AuthGate(),
        '/auth/login': (context) => const LoginScreen(),
        '/auth/signup': (context) => const SignupScreen(),
        '/home': (context) => const HomeScreen(),
        '/game/mode': (context) => const ModeSelector(),
        '/game/players': (context) => const PlayerSelector(),
        '/game': (context) => const GameScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/profile/edit': (context) => const EditProfileScreen(),
        '/profile/achievements': (context) => const AchievementsScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/online/lobby': (context) => const OnlineLobbyScreen(),
        '/online/waiting': (context) => const OnlineWaitingRoom(),
        '/online/game': (context) => const OnlineGameScreen(),
      },
    );
  }
}