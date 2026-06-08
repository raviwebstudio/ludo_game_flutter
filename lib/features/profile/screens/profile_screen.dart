import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ludo_game/core/constants/colors.dart';
import 'package:ludo_game/core/constants/dimensions.dart';
import 'package:ludo_game/core/constants/text_styles.dart';
import 'package:ludo_game/shared/widgets/glass_morphism.dart';
import 'package:ludo_game/shared/widgets/gradient_button.dart';
import 'package:ludo_game/core/services/player_prefs.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

/// Premium Profile and Player Statistics Screen.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = 'Ludo Master';
  String? _avatarPath;
  int _xp = 0;
  int _totalGames = 0;
  int _wins = 0;
  int _winStreak = 0;
  int _coins = 25450;

  StreamSubscription<void>? _changesSubscription;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _changesSubscription = PlayerPrefs.changes.listen((_) => _loadPrefs());
  }

  @override
  void dispose() {
    _changesSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    setState(() {
      _name = PlayerPrefs.playerName(0);
      _avatarPath = PlayerPrefs.playerAvatarPath(0);
      _xp = PlayerPrefs.xp;
      _totalGames = PlayerPrefs.totalGames;
      _wins = PlayerPrefs.wins;
      _winStreak = PlayerPrefs.winStreak;
      _coins = PlayerPrefs.coins;
    });
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final result = await picker.pickImage(source: ImageSource.gallery);
    if (result != null) {
      await PlayerPrefs.setPlayerAvatarPath(0, result.path);
    }
  }

  Future<void> _editName() async {
    final controller = TextEditingController(text: _name);
    final res = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Name'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Save')),
        ],
      ),
    );
    if (res != null && res.trim().isNotEmpty) {
      await PlayerPrefs.setPlayerName(0, res.trim());
    }
  }

  Future<void> _editCoins() async {
    final controller = TextEditingController(text: '$_coins');
    final res = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Coins'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Save')),
        ],
      ),
    );
    if (res != null) {
      final parsed = int.tryParse(res.trim());
      if (parsed != null && parsed >= 0) {
        await PlayerPrefs.setCoins(parsed);
      }
    }
  }

  Future<void> _editStat(String label, int currentValue, Future<void> Function(int) saveFunc) async {
    final controller = TextEditingController(text: '$currentValue');
    final res = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $label'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Save')),
        ],
      ),
    );
    if (res != null) {
      final parsed = int.tryParse(res.trim());
      if (parsed != null && parsed >= 0) {
        await saveFunc(parsed);
      }
    }
  }

  Future<void> _confirmReset() async {
    final res = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset All Stats'),
        content: const Text('Do you want to reset all stats?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Reset')),
        ],
      ),
    );
    if (res == true) {
      await PlayerPrefs.resetStats();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stats reset completed')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(LudoDimensions.spacing16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button + Title
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios, color: LudoColors.textLight),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'PLAYER PROFILE',
                        style: LudoTextStyles.displayMedium.copyWith(fontSize: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: LudoDimensions.spacing24),

                  // Avatar card
                  Center(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _pickAvatar,
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [LudoColors.purple, LudoColors.softBlue],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: LudoColors.purple.withValues(alpha: 0.4),
                                      blurRadius: 24,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: LudoColors.darkNavyDark,
                                    ),
                                    child: Center(
                                      child: _avatarPath == null
                                          ? Icon(
                                              Icons.person,
                                              color: LudoColors.textLight,
                                              size: 64,
                                            )
                                          : ClipOval(
                                              child: Image.file(
                                                File(_avatarPath!),
                                                fit: BoxFit.cover,
                                                width: 120,
                                                height: 120,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: LudoColors.mintGreen,
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ],
                          ),
                        ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: _editName,
                          child: Text(
                            _name,
                            style: LudoTextStyles.headlineSmall.copyWith(color: LudoColors.textLight),
                          ),
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: _editCoins,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.monetization_on, color: LudoColors.gold, size: 20),
                              const SizedBox(width: 6),
                              Text(
                                '$_coins Coins',
                                style: LudoTextStyles.bodyLarge.copyWith(
                                  color: LudoColors.gold,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: LudoDimensions.spacing32),

                  // Player Level / Progress
                  Text(
                    'LEVEL PROGRESS',
                    style: LudoTextStyles.labelSmall.copyWith(
                      color: LudoColors.mintGreen,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GlassMorphism(
                    opacity: 0.08,
                    blur: 12,
                    borderRadius: BorderRadius.circular(LudoDimensions.radius16),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Level ${( (_xp / 1000).floor() + 1)}',
                              style: LudoTextStyles.labelSmall.copyWith(
                                color: LudoColors.textLight,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '$_xp / ${((_xp / 1000).floor() + 1) * 1000} XP',
                              style: LudoTextStyles.labelSmall.copyWith(color: LudoColors.textMedium),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Stack(
                          children: [
                            Container(
                              height: 10,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: ((_xp / (((_xp / 1000).floor() + 1) * 1000))).clamp(0.0, 1.0),
                              child: Container(
                                height: 10,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [LudoColors.softBlue, LudoColors.brightBlue],
                                  ),
                                  borderRadius: BorderRadius.circular(5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: LudoColors.brightBlue.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

                  const SizedBox(height: LudoDimensions.spacing24),

                  // Stats Section
                  Text(
                    'STATISTICS',
                    style: LudoTextStyles.labelSmall.copyWith(
                      color: LudoColors.mintGreen,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      _buildStatCard('Total Games', '$_totalGames', Icons.sports_esports, LudoColors.softBlue, onTap: () => _editStat('Total Games', _totalGames, PlayerPrefs.setTotalGames)),
                      _buildStatCard('Wins', '$_wins', Icons.emoji_events, LudoColors.gold, onTap: () => _editStat('Wins', _wins, PlayerPrefs.setWins)),
                      _buildStatCard('Win Rate', '${PlayerPrefs.winRate.toStringAsFixed(1)}%', Icons.percent, LudoColors.brightBlue),
                      _buildStatCard('Win Streak', '$_winStreak', Icons.local_fire_department, LudoColors.redToken, onTap: () => _editStat('Win Streak', _winStreak, PlayerPrefs.setWinStreak)),
                    ],
                  ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

                  const SizedBox(height: LudoDimensions.spacing32),

                  Center(
                    child: GradientButton(
                      label: 'RESET ALL STATS',
                      onPressed: _confirmReset,
                      colors: const [LudoColors.redToken, Color(0xFFC0392B)],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: GlassMorphism(
        opacity: 0.06,
        blur: 12,
        borderRadius: BorderRadius.circular(LudoDimensions.radius16),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: LudoTextStyles.labelSmall.copyWith(color: LudoColors.textMedium),
                ),
                Icon(icon, color: color, size: 20),
              ],
            ),
            Text(
              value,
              style: LudoTextStyles.displayMedium.copyWith(fontSize: 24),
            ),
          ],
        ),
      ),
    );
  }
}
