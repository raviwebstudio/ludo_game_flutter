import 'package:flutter/material.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:ludo_game/injection.dart';
import 'package:ludo_game/core/services/player_prefs.dart';
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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PlayerPrefs.init();
  setupDependencyInjection();
  runApp(const LudoGame());
}

class LudoGame extends StatelessWidget {
  const LudoGame({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveSizer(
      builder: (context, orientation, screenType) {
        return MaterialApp(
          title: 'Ludo Elite',
          theme: AppTheme.ludoTheme,
          debugShowCheckedModeBanner: false,
          initialRoute: '/',
          routes: {
            '/': (context) => const SplashScreen(),
            '/home': (context) => const HomeScreen(),
            '/game/mode': (context) => const ModeSelector(),
            '/game/players': (context) => const PlayerSelector(),
            '/game': (context) => const GameScreen(),
            '/profile': (context) => const ProfileScreen(),
            '/profile/edit': (context) => const EditProfileScreen(),
            '/profile/achievements': (context) => const AchievementsScreen(),
            '/settings': (context) => const SettingsScreen(),
          },
        );
      },
    );
  }
}