import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ludo_game/core/constants/colors.dart';
import 'package:ludo_game/core/constants/dimensions.dart';
import 'package:ludo_game/core/constants/text_styles.dart';
import 'package:ludo_game/core/services/sound_manager.dart';
import 'package:ludo_game/core/services/player_prefs.dart';
import 'package:ludo_game/shared/widgets/glass_morphism.dart';

/// Premium Settings screen to manage sound, haptic feedback and custom themes.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _soundEnabled;
  late double _volume;
  late bool _hapticsEnabled;
  late String _selectedTheme;

  @override
  void initState() {
    super.initState();
    _soundEnabled = PlayerPrefs.soundEnabled;
    _volume = PlayerPrefs.volume;
    _hapticsEnabled = PlayerPrefs.hapticsEnabled;
    _selectedTheme = PlayerPrefs.boardTheme;
  }

  void _toggleSound(bool value) {
    setState(() {
      _soundEnabled = value;
      SoundManager().setMuted(!value);
    });
  }

  void _updateVolume(double value) {
    setState(() {
      _volume = value;
      SoundManager().setVolume(value);
    });
  }

  void _toggleHaptics(bool value) {
    setState(() {
      _hapticsEnabled = value;
      PlayerPrefs.setHapticsEnabled(value);
    });
  }

  void _changeTheme(String? value) {
    if (value != null) {
      setState(() {
        _selectedTheme = value;
        PlayerPrefs.setBoardTheme(value);
      });
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
                  // Header
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios, color: LudoColors.textLight),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'SETTINGS',
                        style: LudoTextStyles.displayMedium.copyWith(fontSize: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: LudoDimensions.spacing24),

                  // Sound & Haptics Section
                  _buildSectionHeader('SOUND & HAPTICS'),
                  const SizedBox(height: 8),
                  GlassMorphism(
                    opacity: 0.08,
                    blur: 12,
                    borderRadius: BorderRadius.circular(LudoDimensions.radius16),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildToggleTile(
                          icon: Icons.volume_up,
                          title: 'Sound Effects',
                          value: _soundEnabled,
                          onChanged: _toggleSound,
                        ),
                        if (_soundEnabled) ...[
                          const Divider(color: Colors.black12),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              children: [
                                const Icon(Icons.volume_mute, color: LudoColors.textMedium, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: SliderTheme(
                                    data: SliderThemeData(
                                      activeTrackColor: LudoColors.brightBlue,
                                      inactiveTrackColor: Colors.black.withValues(alpha: 0.08),
                                      thumbColor: LudoColors.brightBlue,
                                      overlayColor: LudoColors.brightBlue.withValues(alpha: 0.2),
                                      trackHeight: 4,
                                    ),
                                    child: Slider(
                                      value: _volume,
                                      onChanged: _updateVolume,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.volume_up, color: LudoColors.brightBlue, size: 20),
                              ],
                            ),
                          ),
                        ],
                        const Divider(color: Colors.black12),
                        _buildToggleTile(
                          icon: Icons.vibration,
                          title: 'Haptic Feedback',
                          value: _hapticsEnabled,
                          onChanged: _toggleHaptics,
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms),

                  const SizedBox(height: LudoDimensions.spacing24),

                  // Game Settings Section
                  _buildSectionHeader('DISPLAY & THEME'),
                  const SizedBox(height: 8),
                  GlassMorphism(
                    opacity: 0.08,
                    blur: 12,
                    borderRadius: BorderRadius.circular(LudoDimensions.radius16),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildDropdownTile(
                          icon: Icons.palette,
                          title: 'Board Theme',
                          value: _selectedTheme,
                          options: const ['Neon Dark', 'Classic Board', 'Royal Gold'],
                          onChanged: _changeTheme,
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 150.ms, duration: 400.ms),

                  const SizedBox(height: LudoDimensions.spacing24),

                  // About Section
                  _buildSectionHeader('ABOUT'),
                  const SizedBox(height: 8),
                  GlassMorphism(
                    opacity: 0.08,
                    blur: 12,
                    borderRadius: BorderRadius.circular(LudoDimensions.radius16),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildInfoTile('Version', '1.0.0 (Elite Edition)'),
                        const Divider(color: Colors.black12),
                        _buildInfoTile('Developer', 'Antigravity AI'),
                        const Divider(color: Colors.black12),
                        _buildInfoTile('Engine', 'Flutter 3.x'),
                      ],
                    ),
                  ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Text(
        title,
        style: LudoTextStyles.labelSmall.copyWith(
          color: LudoColors.mintGreen,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildToggleTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: LudoColors.textLight, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: LudoTextStyles.bodyMedium.copyWith(
                color: LudoColors.textLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: LudoColors.mintGreen,
            activeTrackColor: LudoColors.mintGreen.withValues(alpha: 0.3),
            inactiveThumbColor: LudoColors.textMedium,
            inactiveTrackColor: Colors.black.withValues(alpha: 0.08),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownTile({
    required IconData icon,
    required String title,
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: LudoColors.textLight, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: LudoTextStyles.bodyMedium.copyWith(
                color: LudoColors.textLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          DropdownButton<String>(
            value: value,
            dropdownColor: LudoColors.darkNavyLight,
            underline: const SizedBox(),
            icon: const Icon(Icons.arrow_drop_down, color: LudoColors.mintGreen),
            items: options.map((opt) {
              return DropdownMenuItem<String>(
                value: opt,
                child: Text(
                  opt,
                  style: LudoTextStyles.bodyMedium.copyWith(color: LudoColors.textLight),
                ),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: LudoTextStyles.bodyMedium.copyWith(
              color: LudoColors.textMedium,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: LudoTextStyles.bodyMedium.copyWith(
              color: LudoColors.textLight,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
