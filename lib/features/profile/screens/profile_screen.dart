import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ludo_game/injection.dart';
import 'package:ludo_game/core/services/firebase_service.dart';
import 'package:ludo_game/core/constants/colors.dart';
import 'package:ludo_game/core/constants/dimensions.dart';
import 'package:ludo_game/core/constants/text_styles.dart';
import 'package:ludo_game/shared/widgets/glass_morphism.dart';
import 'package:ludo_game/shared/widgets/gradient_button.dart';
import 'package:ludo_game/core/services/player_prefs.dart';
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

  final List<String> _presets = [
    'assets/avatars/lion.png',
    'assets/avatars/tiger.png',
    'assets/avatars/panda.png',
    'assets/avatars/eagle.png',
    'assets/avatars/owl.png',
    'assets/avatars/peacock.png',
    'assets/avatars/penguin.png',
    'assets/avatars/fox.png',
    'assets/avatars/bear.png',
    'assets/avatars/rabbit.png',
    'assets/avatars/wolf.png',
    'assets/avatars/king.png',
    'assets/avatars/queen.png',
    'assets/avatars/boy.png',
    'assets/avatars/girl.png',
    'assets/avatars/crown.png',
  ];

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
      _coins = PlayerPrefs.getCoins();
    });
  }



  Future<void> _editName() async {
    final controller = TextEditingController(text: _name);
    final res = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: LudoColors.darkNavyLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LudoDimensions.radius16),
        ),
        title: const Text(
          'Edit Name',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white24),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: LudoColors.cyan),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: LudoColors.textMedium)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save', style: TextStyle(color: LudoColors.cyan, fontWeight: FontWeight.bold)),
          ),
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
        backgroundColor: LudoColors.darkNavyLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LudoDimensions.radius16),
        ),
        title: const Text(
          'Edit Coins',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white24),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: LudoColors.cyan),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: LudoColors.textMedium)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save', style: TextStyle(color: LudoColors.cyan, fontWeight: FontWeight.bold)),
          ),
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
        backgroundColor: LudoColors.darkNavyLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LudoDimensions.radius16),
        ),
        title: Text(
          'Edit $label',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white24),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: LudoColors.cyan),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: LudoColors.textMedium)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save', style: TextStyle(color: LudoColors.cyan, fontWeight: FontWeight.bold)),
          ),
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
        backgroundColor: LudoColors.darkNavyLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LudoDimensions.radius16),
        ),
        title: const Text(
          'Reset All Stats',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Do you want to reset all stats?',
          style: TextStyle(color: LudoColors.textMedium),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: LudoColors.textMedium)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset', style: TextStyle(color: LudoColors.redToken, fontWeight: FontWeight.bold)),
          ),
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
                                    ? const Icon(
                                        Icons.person,
                                        color: LudoColors.textLight,
                                        size: 64,
                                      )
                                    : ClipOval(
                                        child: _avatarPath!.startsWith('http')
                                            ? Image.network(
                                                _avatarPath!,
                                                fit: BoxFit.cover,
                                                width: 120,
                                                height: 120,
                                                errorBuilder: (context, error, stackTrace) => const Icon(
                                                  Icons.person,
                                                  color: LudoColors.textLight,
                                                  size: 64,
                                                ),
                                              )
                                            : _avatarPath!.startsWith('assets/')
                                                ? Image.asset(
                                                    _avatarPath!,
                                                    fit: BoxFit.cover,
                                                    width: 120,
                                                    height: 120,
                                                    errorBuilder: (context, error, stackTrace) => const Icon(
                                                      Icons.person,
                                                      color: LudoColors.textLight,
                                                      size: 64,
                                                    ),
                                                  )
                                                : Image.file(
                                                    File(_avatarPath!),
                                                    fit: BoxFit.cover,
                                                    width: 120,
                                                    height: 120,
                                                    errorBuilder: (context, error, stackTrace) => const Icon(
                                                      Icons.person,
                                                      color: LudoColors.textLight,
                                                      size: 64,
                                                    ),
                                                  ),
                                      ),
                              ),
                            ),
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
                                '${_formatCoins(_coins)} Coins',
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
                  GlassMorphism(
                    opacity: 0.08,
                    blur: 12,
                    borderRadius: BorderRadius.circular(LudoDimensions.radius16),
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: _buildStatCell(
                            label: 'GAMES',
                            value: '$_totalGames',
                            onTap: () => _editStat('Total Games', _totalGames, PlayerPrefs.setTotalGames),
                          ),
                        ),
                        _buildStatDivider(),
                        Expanded(
                          child: _buildStatCell(
                            label: 'WINS',
                            value: '$_wins',
                            onTap: () => _editStat('Wins', _wins, PlayerPrefs.setWins),
                          ),
                        ),
                        _buildStatDivider(),
                        Expanded(
                          child: _buildStatCell(
                            label: 'WIN RATE',
                            value: '${PlayerPrefs.winRate.toStringAsFixed(1)}%',
                          ),
                        ),
                        _buildStatDivider(),
                        Expanded(
                          child: _buildStatCell(
                            label: 'STREAK',
                            value: '$_winStreak',
                            onTap: () => _editStat('Win Streak', _winStreak, PlayerPrefs.setWinStreak),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

                  const SizedBox(height: LudoDimensions.spacing24),

                  // Preset Avatar Section
                  Text(
                    'SELECT PRESET AVATAR',
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
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: _presets.length,
                      itemBuilder: (context, index) {
                        final avatar = _presets[index];
                        final isSelected = _avatarPath == avatar;
                        return GestureDetector(
                          onTap: () async {
                            await PlayerPrefs.setPlayerAvatarPath(0, avatar);
                            setState(() {
                              _avatarPath = avatar;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? LudoColors.mintGreen
                                    : Colors.grey.withValues(alpha: 0.4),
                                width: isSelected ? 3.0 : 1.5,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: LudoColors.mintGreen.withValues(alpha: 0.35),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      )
                                    ]
                                  : null,
                            ),
                            padding: const EdgeInsets.all(3),
                            child: ClipOval(
                              child: Image.asset(
                                avatar,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const Icon(
                                  Icons.person,
                                  color: LudoColors.textLight,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ).animate().fadeIn(delay: 250.ms, duration: 400.ms),

                  const SizedBox(height: LudoDimensions.spacing24),

                  GestureDetector(
                    onTap: () => _showLogoutDialog(context),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      decoration: BoxDecoration(
                        color: LudoColors.darkNavyLight.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(LudoDimensions.radius16),
                        border: Border.all(
                          color: LudoColors.redToken.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout, color: LudoColors.redToken, size: 20),
                          SizedBox(width: 12),
                          Text(
                            'Logout',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: LudoDimensions.spacing24),

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

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 32,
      color: Colors.white.withValues(alpha: 0.1),
    );
  }

  Widget _buildStatCell({
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: LudoTextStyles.displayMedium.copyWith(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: LudoTextStyles.labelSmall.copyWith(
              color: LudoColors.cyan,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCoins(int value) {
    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return value.toString().replaceAllMapped(reg, (Match m) => '${m[1]},');
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassMorphism(
          opacity: 0.15,
          blur: 16,
          borderRadius: BorderRadius.circular(LudoDimensions.radius24),
          padding: const EdgeInsets.all(LudoDimensions.spacing24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Are you sure you want to log out?',
                style: TextStyle(
                  color: LudoColors.textMedium,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text(
                      'CANCEL',
                      style: TextStyle(color: LudoColors.textMedium, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text(
                      'LOGOUT',
                      style: TextStyle(color: LudoColors.redToken, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (res == true) {
      final firebaseService = getIt<FirebaseService>();
      await firebaseService.signOut();
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
      }
    }
  }
}
