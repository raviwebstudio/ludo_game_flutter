import 'package:flutter/material.dart';
import 'package:ludo_game/core/constants/text_styles.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Achievements')),
      body: Center(
        child: Text('No achievements yet', style: LudoTextStyles.bodyLarge),
      ),
    );
  }
}
