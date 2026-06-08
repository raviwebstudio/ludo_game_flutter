import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/dimensions.dart';
import '../../../core/constants/text_styles.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/glass_morphism.dart';
import '../../../injection.dart';
import '../../../presentation/bloc/game_bloc.dart';
import '../../../core/services/player_prefs.dart';
import 'game_screen.dart';
import 'dart:developer';

enum PlayerColor { red, green, blue, yellow }

/// Player count selector screen — choose 2, 3, or 4 players and start game.
class PlayerSelector extends StatefulWidget {
  const PlayerSelector({super.key});

  @override
  State<PlayerSelector> createState() => _PlayerSelectorState();
}

class _PlayerSelectorState extends State<PlayerSelector> {
  int _selectedCount = 2;
  late List<Color> _currentPlayerColors;
  List<PlayerColor> selectedColors = [];

  PlayerColor _colorToPlayerColor(Color color) {
    if (color == LudoColors.redToken) return PlayerColor.red;
    if (color == LudoColors.greenToken) return PlayerColor.green;
    if (color == LudoColors.blueToken) return PlayerColor.blue;
    return PlayerColor.yellow;
  }

  Color _playerColorToColor(PlayerColor pc) {
    switch (pc) {
      case PlayerColor.red:
        return LudoColors.redToken;
      case PlayerColor.green:
        return LudoColors.greenToken;
      case PlayerColor.blue:
        return LudoColors.blueToken;
      case PlayerColor.yellow:
        return LudoColors.yellowToken;
    }
  }

  String _colorName(Color color) {
    if (color == LudoColors.redToken) return 'Red';
    if (color == LudoColors.greenToken) return 'Green';
    if (color == LudoColors.blueToken) return 'Blue';
    return 'Yellow';
  }

  void _updateSelectedColors() {
    selectedColors = _currentPlayerColors.take(_selectedCount).map(_colorToPlayerColor).toList();
  }

  @override
  void initState() {
    super.initState();
    final p1Color = Color(PlayerPrefs.player1ColorValue);
    _currentPlayerColors = [
      p1Color,
      LudoColors.greenToken,
      LudoColors.yellowToken,
      LudoColors.blueToken,
    ];
    _resolveColorConflicts(0, p1Color);
    _updateSelectedColors();
  }

  void _resolveColorConflicts(int changedIndex, Color newColor) {
    final availableColors = [
      LudoColors.redToken,
      LudoColors.greenToken,
      LudoColors.yellowToken,
      LudoColors.blueToken,
    ];

    for (int i = 0; i < 4; i++) {
      if (i == changedIndex) continue;
      if (_currentPlayerColors[i] == newColor) {
        final unused = availableColors.firstWhere(
          (c) => !_currentPlayerColors.contains(c),
          orElse: () => newColor,
        );
        _currentPlayerColors[i] = unused;
      }
    }
  }

  void _showColorPicker(int playerIndex) {
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
                Text(
                  'SELECT COLOR',
                  style: LudoTextStyles.headlineSmall.copyWith(
                    color: LudoColors.textLight,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose color for Player ${playerIndex + 1}',
                  style: LudoTextStyles.bodyMedium.copyWith(color: LudoColors.textMedium),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    LudoColors.redToken,
                    LudoColors.greenToken,
                    LudoColors.blueToken,
                    LudoColors.yellowToken,
                  ].map((color) {
                    final colorEnum = _colorToPlayerColor(color);
                    final isAlreadySelectedByOther = selectedColors.contains(colorEnum) &&
                        _currentPlayerColors.indexOf(color) != playerIndex;
                    final isCurrent = _currentPlayerColors[playerIndex] == color;

                    return GestureDetector(
                      onTap: isAlreadySelectedByOther
                          ? null
                          : () async {
                              setState(() {
                                _currentPlayerColors[playerIndex] = color;
                                _updateSelectedColors();
                              });
                              log('Player ${playerIndex + 1} selected ${_colorName(color)}');
                              Navigator.pop(context);

                              if (playerIndex == 0) {
                                await PlayerPrefs.setPlayer1ColorValue(color.toARGB32());
                              }
                            },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isAlreadySelectedByOther
                              ? color.withValues(alpha: 0.3)
                              : color,
                          border: Border.all(
                            color: isCurrent
                                ? Colors.white
                                : Colors.transparent,
                            width: isCurrent ? 3.5 : 0,
                          ),
                          boxShadow: isAlreadySelectedByOther
                              ? null
                              : [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.4),
                                    blurRadius: isCurrent ? 12 : 6,
                                    spreadRadius: isCurrent ? 2 : 1,
                                  ),
                                ],
                        ),
                        child: isCurrent
                            ? const Icon(Icons.check, color: Colors.white, size: 24)
                            : isAlreadySelectedByOther
                                ? Icon(Icons.block, color: Colors.white.withValues(alpha: 0.5), size: 20)
                                : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
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
          child: Padding(
            padding: const EdgeInsets.all(LudoDimensions.spacing16),
            child: Column(
              children: [
                // Back button
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios,
                        color: LudoColors.textLight),
                  ),
                ),
                const SizedBox(height: LudoDimensions.spacing16),

                Text('HOW MANY PLAYERS?', style: LudoTextStyles.displayMedium)
                    .animate()
                    .fadeIn(duration: 400.ms),

                const SizedBox(height: LudoDimensions.spacing40),

                // Player count selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [2, 3, 4].map((count) {
                    final isSelected = count == _selectedCount;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _selectedCount = count;
                          _updateSelectedColors();
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? LudoColors.purple
                                : LudoColors.darkNavyLight,
                            borderRadius: BorderRadius.circular(
                                LudoDimensions.radius20),
                            border: Border.all(
                              color: isSelected
                                  ? LudoColors.purpleLight
                                  : Colors.black.withValues(alpha: 0.08),
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: LudoColors.purple
                                          .withValues(alpha: 0.4),
                                      blurRadius: 16,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$count',
                                style: LudoTextStyles.displayMedium.copyWith(
                                  color: isSelected
                                      ? Colors.white
                                      : LudoColors.textMedium,
                                ),
                              ),
                              Text(
                                'Players',
                                style: LudoTextStyles.labelSmall.copyWith(
                                  color: isSelected
                                      ? Colors.white.withValues(alpha: 0.8)
                                      : LudoColors.textMedium,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

                const SizedBox(height: LudoDimensions.spacing40),

                // Player color preview
                Text(
                  'PLAYERS',
                  style: LudoTextStyles.labelSmall.copyWith(
                    letterSpacing: 2,
                    color: LudoColors.textMedium,
                  ),
                ),
                const SizedBox(height: LudoDimensions.spacing16),

                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: List.generate(_selectedCount, (i) {
                    final color = _currentPlayerColors[i];
                    return GestureDetector(
                      onTap: () => _showColorPicker(i),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color.withValues(alpha: 0.2),
                              border: Border.all(
                                color: color,
                                width: 2.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.3),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                Icons.person,
                                color: color,
                                size: 28,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Player ${i + 1}',
                            style: LudoTextStyles.labelSmall.copyWith(
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ).animate().fadeIn(delay: 400.ms, duration: 400.ms),

                const Spacer(),

                // Start game button
                GradientButton(
                  label: 'START GAME',
                  colors: const [LudoColors.mintGreen, Color(0xFF00C9A7)],
                  onPressed: () => _startGame(context),
                ).animate().fadeIn(delay: 600.ms, duration: 400.ms)
                    .slideY(begin: 0.2, duration: 400.ms),

                const SizedBox(height: LudoDimensions.spacing32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _startGame(BuildContext context) {
    _updateSelectedColors();
    if (selectedColors.length != selectedColors.toSet().length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All players must have unique colors!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => getIt<GameBloc>()..add(StartGame(_selectedCount, playerColors: _currentPlayerColors)),
          child: const GameScreen(),
        ),
      ),
    );
  }
}
