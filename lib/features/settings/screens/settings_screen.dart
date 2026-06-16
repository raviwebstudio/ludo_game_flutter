import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ludo_game/core/constants/colors.dart';
import 'package:ludo_game/core/constants/dimensions.dart';
import 'package:ludo_game/core/constants/text_styles.dart';
import 'package:ludo_game/core/services/sound_manager.dart';
import 'package:ludo_game/core/services/player_prefs.dart';

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
        color: const Color(0xFF0D1B2A),
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
                        icon: const Icon(Icons.arrow_back_ios, color: Color(0xFFF0F4FF)),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'SETTINGS',
                        style: LudoTextStyles.displayMedium.copyWith(fontSize: 20, color: const Color(0xFFF0F4FF)),
                      ),
                    ],
                  ),
                  const SizedBox(height: LudoDimensions.spacing24),

                  // Sound & Haptics Section
                  _buildSectionHeader('SOUND & HAPTICS'),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF162236),
                      borderRadius: BorderRadius.circular(LudoDimensions.radius16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.07),
                        width: 1,
                      ),
                    ),
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
                          Divider(color: Colors.white.withValues(alpha: 0.07)),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              children: [
                                const Icon(Icons.volume_mute, color: Color(0xFF8BA3C1), size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: SliderTheme(
                                    data: SliderThemeData(
                                      activeTrackColor: const Color(0xFF2979FF),
                                      inactiveTrackColor: const Color(0xFF1E3A5A),
                                      thumbColor: const Color(0xFF2979FF),
                                      overlayColor: const Color(0xFF2979FF).withValues(alpha: 0.2),
                                      trackHeight: 4,
                                    ),
                                    child: Slider(
                                      value: _volume,
                                      onChanged: _updateVolume,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.volume_up, color: Color(0xFF2979FF), size: 20),
                              ],
                            ),
                          ),
                        ],
                        Divider(color: Colors.white.withValues(alpha: 0.07)),
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
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF162236),
                      borderRadius: BorderRadius.circular(LudoDimensions.radius16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.07),
                        width: 1,
                      ),
                    ),
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
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF162236),
                      borderRadius: BorderRadius.circular(LudoDimensions.radius16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.07),
                        width: 1,
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildInfoTile('Version', '1.0.0 (Elite Edition)'),
                        Divider(color: Colors.white.withValues(alpha: 0.07)),
                        _buildInfoTile('Developer', 'Crowcent'),
                        Divider(color: Colors.white.withValues(alpha: 0.07)),
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
          color: const Color(0xFF00E5A0),
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
          Icon(icon, color: const Color(0xFFF0F4FF), size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: LudoTextStyles.bodyMedium.copyWith(
                color: const Color(0xFFF0F4FF),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFF00E5A0),
            activeTrackColor: const Color(0xFF00E5A0).withValues(alpha: 0.3),
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
          Icon(icon, color: const Color(0xFFF0F4FF), size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: LudoTextStyles.bodyMedium.copyWith(
                color: const Color(0xFFF0F4FF),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          DropdownButton<String>(
            value: value,
            dropdownColor: const Color(0xFF162236),
            underline: const SizedBox(),
            icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF00E5A0)),
            items: options.map((opt) {
              return DropdownMenuItem<String>(
                value: opt,
                child: Text(
                  opt,
                  style: LudoTextStyles.bodyMedium.copyWith(color: const Color(0xFFF0F4FF)),
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
              color: const Color(0xFFF0F4FF).withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: LudoTextStyles.bodyMedium.copyWith(
              color: const Color(0xFFF0F4FF),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
