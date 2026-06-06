import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/dimensions.dart';
import '../../../core/constants/text_styles.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../injection.dart';
import '../../../presentation/bloc/game_bloc.dart';
import 'game_screen.dart';

/// Player count selector screen — choose 2, 3, or 4 players and start game.
class PlayerSelector extends StatefulWidget {
  const PlayerSelector({super.key});

  @override
  State<PlayerSelector> createState() => _PlayerSelectorState();
}

class _PlayerSelectorState extends State<PlayerSelector> {
  int _selectedCount = 2;

  static const _playerColors = [
    LudoColors.redToken,
    LudoColors.greenToken,
    LudoColors.yellowToken,
    LudoColors.blueToken,
  ];

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
                        onTap: () => setState(() => _selectedCount = count),
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
                                  : Colors.white.withValues(alpha: 0.1),
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
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _playerColors[i].withValues(alpha: 0.2),
                            border: Border.all(
                              color: _playerColors[i],
                              width: 2.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _playerColors[i].withValues(alpha: 0.3),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              Icons.person,
                              color: _playerColors[i],
                              size: 28,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Player ${i + 1}',
                          style: LudoTextStyles.labelSmall.copyWith(
                            color: _playerColors[i],
                          ),
                        ),
                      ],
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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => getIt<GameBloc>()..add(StartGame(_selectedCount)),
          child: const GameScreen(),
        ),
      ),
    );
  }
}
