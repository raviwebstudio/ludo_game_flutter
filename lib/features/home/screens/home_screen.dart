import 'dart:math';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/dimensions.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/services/player_prefs.dart';
import '../widgets/game_mode_card.dart';
import '../../../shared/widgets/glass_morphism.dart';

/// The main lobby screen — dark navy background, diamond board preview,
/// "PLAY NOW" button, and mode cards.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _name = 'Player 1';
  String? _avatarPath;
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

  void _loadPrefs() {
    if (!mounted) return;
    setState(() {
      _name = PlayerPrefs.playerName(0);
      _avatarPath = PlayerPrefs.playerAvatarPath(0);
      _coins = PlayerPrefs.coins;
    });
  }

  String _formatCoins(int value) {
    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return value.toString().replaceAllMapped(reg, (Match m) => '${m[1]},');
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
            colors: [
              LudoColors.darkNavyDark,
              LudoColors.darkNavy,
              LudoColors.darkNavyDark,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: LudoDimensions.spacing16,
            ),
            child: Column(
              children: [
                const SizedBox(height: LudoDimensions.spacing12),

                // ── Top Bar ──
                _buildTopBar(context),
                const SizedBox(height: LudoDimensions.spacing24),

                // ── Diamond Board Preview ──
                _buildDiamondBoard()
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .scale(
                      begin: const Offset(0.8, 0.8),
                      duration: 600.ms,
                      curve: Curves.easeOut,
                    ),

                const SizedBox(height: LudoDimensions.spacing24),

                // ── Play Now Button ──
                _buildPlayNowButton(context)
                    .animate()
                    .fadeIn(delay: 300.ms, duration: 500.ms)
                    .slideY(begin: 0.2, duration: 500.ms),

                const SizedBox(height: LudoDimensions.spacing24),

                // ── Mode Cards ──
                GameModeCard(
                  icon: Icons.people,
                  title: 'PLAY OFFLINE',
                  subtitle: '2‑4 Players • No WiFi Required',
                  onTap: () => Navigator.pushNamed(context, '/game/players'),
                ).animate().fadeIn(delay: 500.ms, duration: 400.ms)
                    .slideX(begin: -0.1, duration: 400.ms),

                const SizedBox(height: LudoDimensions.spacing12),

                GameModeCard(
                  icon: Icons.smart_toy,
                  title: 'PRACTICE VS AI',
                  subtitle: 'Master the Game • Easy to Hard',
                  gradientColors: const [
                    LudoColors.purple,
                    LudoColors.purpleLight,
                  ],
                  onTap: () => Navigator.pushNamed(context, '/game/players'),
                ).animate().fadeIn(delay: 600.ms, duration: 400.ms)
                    .slideX(begin: 0.1, duration: 400.ms),

                const SizedBox(height: LudoDimensions.spacing12),

                GameModeCard(
                  icon: Icons.public,
                  title: 'ONLINE MULTIPLAYER',
                  subtitle: 'Play Online With Friends',
                  badge: 'COMING SOON',
                  gradientColors: [
                    LudoColors.darkNavyLight,
                    LudoColors.darkNavyLight.withValues(alpha: 0.8),
                  ],
                  onTap: () => _showComingSoonDialog(context),
                ).animate().fadeIn(delay: 700.ms, duration: 400.ms)
                    .slideX(begin: -0.1, duration: 400.ms),

                const SizedBox(height: LudoDimensions.spacing32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Top Bar ──────────────────────────────────────────────────────────────

  Widget _buildTopBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Profile Avatar + Name
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/profile'),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: LudoColors.mintGreen.withValues(alpha: 0.5),
                    width: 2,
                  ),
                  color: LudoColors.darkNavyLight,
                ),
                child: _avatarPath == null
                    ? const Icon(Icons.person, color: LudoColors.textMedium, size: 22)
                    : ClipOval(
                        child: _avatarPath!.startsWith('assets/')
                            ? Image.asset(
                                _avatarPath!,
                                fit: BoxFit.cover,
                                width: 44,
                                height: 44,
                                errorBuilder: (context, error, stackTrace) => const Icon(
                                  Icons.person,
                                  color: LudoColors.textMedium,
                                  size: 22,
                                ),
                              )
                            : Image.file(
                                File(_avatarPath!),
                                fit: BoxFit.cover,
                                width: 44,
                                height: 44,
                                errorBuilder: (context, error, stackTrace) => const Icon(
                                  Icons.person,
                                  color: LudoColors.textMedium,
                                  size: 22,
                                ),
                              ),
                      ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'WELCOME',
                    style: LudoTextStyles.labelSmall.copyWith(
                      color: LudoColors.textMedium,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                  Text(
                    _name.toUpperCase(),
                    style: LudoTextStyles.labelBold.copyWith(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Coins
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: LudoColors.darkNavyLight,
                borderRadius: BorderRadius.circular(LudoDimensions.radius24),
                border: Border.all(
                  color: Colors.black.withValues(alpha: 0.08),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.monetization_on,
                      color: LudoColors.gold, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    '${_formatCoins(_coins)} G',
                    style: LudoTextStyles.labelBold.copyWith(
                      color: LudoColors.gold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: LudoColors.darkNavyLight,
                borderRadius: BorderRadius.circular(LudoDimensions.radius24),
                border: Border.all(
                  color: Colors.black.withValues(alpha: 0.08),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.diamond,
                      color: LudoColors.redToken.withValues(alpha: 0.8), size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '42',
                    style: LudoTextStyles.labelBold,
                  ),
                ],
              ),
            ),
          ],
        ),

        // Action Buttons: Settings Gear + Notification Bell
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Settings Gear
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/settings'),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: LudoColors.darkNavyLight,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                child: const Icon(Icons.settings,
                    color: LudoColors.textLight, size: 18),
              ),
            ),
            const SizedBox(width: 8),
            // Notification bell
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: LudoColors.darkNavyLight,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
              child: const Icon(Icons.notifications_none,
                  color: LudoColors.textMedium, size: 18),
            ),
          ],
        ),
      ],
    );
  }

  // ── Diamond Board Preview ───────────────────────────────────────────────

  Widget _buildDiamondBoard() {
    const boardSize = 220.0;
    return SizedBox(
      width: boardSize + 40,
      height: boardSize + 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Decorative floating orbs
          Positioned(
            left: 10,
            top: 20,
            child: _floatingOrb(40, LudoColors.purpleLight.withValues(alpha: 0.4)),
          ),
          Positioned(
            right: 10,
            bottom: 30,
            child: _floatingOrb(50, LudoColors.mintGreen.withValues(alpha: 0.4)),
          ),

          // Rotated diamond
          Transform.rotate(
            angle: pi / 4,
            child: Container(
              width: boardSize * 0.7,
              height: boardSize * 0.7,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: LudoColors.purple.withValues(alpha: 0.2),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(color: LudoColors.redToken.withValues(alpha: 0.4)),
                          ),
                          Expanded(
                            child: Container(color: LudoColors.greenToken.withValues(alpha: 0.4)),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(color: LudoColors.blueToken.withValues(alpha: 0.4)),
                          ),
                          Expanded(
                            child: Container(color: LudoColors.yellowToken.withValues(alpha: 0.4)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Center dice icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                '⚅',
                style: TextStyle(fontSize: 32),
              ),
            ),
          ),

          // Castle icons at 4 corners of diamond
          ..._buildCastleIcons(boardSize * 0.7),
        ],
      ),
    );
  }

  List<Widget> _buildCastleIcons(double size) {
    return [
      Positioned(top: 8, child: Icon(Icons.castle, color: LudoColors.mintGreen.withValues(alpha: 0.6), size: 22)),
      Positioned(bottom: 8, child: Icon(Icons.castle, color: LudoColors.mintGreen.withValues(alpha: 0.6), size: 22)),
      Positioned(left: 8, child: Icon(Icons.castle, color: LudoColors.mintGreen.withValues(alpha: 0.6), size: 22)),
      Positioned(right: 8, child: Icon(Icons.castle, color: LudoColors.purpleLight.withValues(alpha: 0.6), size: 22)),
    ];
  }

  Widget _floatingOrb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(color: color, blurRadius: size * 0.5),
        ],
      ),
    );
  }

  // ── Play Now Button ─────────────────────────────────────────────────────

  Widget _buildPlayNowButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/game/players'),
      child: Container(
        width: double.infinity,
        height: 64,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [LudoColors.purple, LudoColors.purpleLight],
          ),
          borderRadius: BorderRadius.circular(LudoDimensions.radius16),
          boxShadow: [
            BoxShadow(
              color: LudoColors.purple.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'PLAY NOW',
              style: LudoTextStyles.displayMedium.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.sports_esports, color: Colors.white, size: 28),
          ],
        ),
      ),
    );
  }

  void _showComingSoonDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: GlassMorphism(
            opacity: 0.15,
            blur: 16,
            borderRadius: BorderRadius.circular(LudoDimensions.radius24),
            padding: const EdgeInsets.all(LudoDimensions.spacing24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.public,
                  color: LudoColors.cyan,
                  size: 48,
                ).animate().scale(duration: 400.ms),
                const SizedBox(height: 16),
                Text(
                  'Coming Soon',
                  style: LudoTextStyles.headlineSmall.copyWith(
                    color: LudoColors.textLight,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Online multiplayer is coming in the next update. Stay tuned!',
                  textAlign: TextAlign.center,
                  style: LudoTextStyles.bodyMedium.copyWith(color: LudoColors.textMedium),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: LudoColors.purple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(LudoDimensions.radius12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'OK',
                      style: LudoTextStyles.labelBold.copyWith(fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

