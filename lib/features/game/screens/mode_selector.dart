import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/dimensions.dart';
import '../../../core/constants/text_styles.dart';

/// Select between Local Multiplayer and vs AI mode.
class ModeSelector extends StatelessWidget {
  const ModeSelector({super.key});

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios, color: LudoColors.textLight),
                ),
                const SizedBox(height: LudoDimensions.spacing24),

                Center(
                  child: Text('SELECT MODE', style: LudoTextStyles.displayMedium),
                ).animate().fadeIn(duration: 400.ms),

                const SizedBox(height: LudoDimensions.spacing40),

                // Local Multiplayer
                _ModeOptionCard(
                  icon: Icons.people,
                  title: 'Local Multiplayer',
                  description: '2–4 Players on the same device.\nAll play together!',
                  gradient: [LudoColors.softBlue, LudoColors.brightBlue],
                  onTap: () => Navigator.pushNamed(context, '/game/players'),
                ).animate().fadeIn(delay: 200.ms, duration: 400.ms)
                    .slideX(begin: -0.1, duration: 400.ms),

                const SizedBox(height: LudoDimensions.spacing16),

                // vs AI
                _ModeOptionCard(
                  icon: Icons.smart_toy,
                  title: 'Practice vs AI',
                  description: 'Play against the computer.\nPerfect for practise!',
                  gradient: [LudoColors.purple, LudoColors.purpleLight],
                  onTap: () => Navigator.pushNamed(context, '/game/players'),
                ).animate().fadeIn(delay: 350.ms, duration: 400.ms)
                    .slideX(begin: 0.1, duration: 400.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeOptionCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _ModeOptionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradient,
    required this.onTap,
  });

  @override
  State<_ModeOptionCard> createState() => _ModeOptionCardState();
}

class _ModeOptionCardState extends State<_ModeOptionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) {
          _ctrl.reverse();
          widget.onTap();
        },
        onTapCancel: () => _ctrl.reverse(),
        child: Container(
          padding: const EdgeInsets.all(LudoDimensions.spacing24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(LudoDimensions.radius24),
            boxShadow: [
              BoxShadow(
                color: widget.gradient.first.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(LudoDimensions.radius16),
                ),
                child: Icon(widget.icon, color: Colors.white, size: 36),
              ),
              const SizedBox(width: LudoDimensions.spacing16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: LudoTextStyles.headlineSmall
                          .copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.description,
                      style: LudoTextStyles.bodyMedium
                          .copyWith(color: Colors.white.withValues(alpha: 0.8)),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white.withValues(alpha: 0.5),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
