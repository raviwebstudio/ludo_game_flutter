import 'package:flutter/material.dart';
import 'package:ludo_game/core/constants/text_styles.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Center(
        child: Text('Edit profile not implemented yet', style: LudoTextStyles.bodyLarge),
      ),
    );
  }
}
