import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

class PlayerPrefs {
  static const _keyPrefix = 'ludo_';
  static const _xpKey = '${_keyPrefix}xp';
  static const _totalGamesKey = '${_keyPrefix}total_games';
  static const _winsKey = '${_keyPrefix}wins';
  static const _winStreakKey = '${_keyPrefix}win_streak';

  static SharedPreferences? _prefs;
  static final StreamController<void> _changeController = StreamController.broadcast();

  static Stream<void> get changes => _changeController.stream;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static const _soundEnabledKey = '${_keyPrefix}sound_enabled';
  static const _volumeKey = '${_keyPrefix}volume';
  static const _hapticsEnabledKey = '${_keyPrefix}haptics_enabled';
  static const _boardThemeKey = '${_keyPrefix}board_theme';

  static int get xp => _prefs?.getInt(_xpKey) ?? 0;
  static Future<void> setXp(int value) async {
    await _prefs?.setInt(_xpKey, value);
    _changeController.add(null);
  }

  static int get totalGames => _prefs?.getInt(_totalGamesKey) ?? 0;
  static Future<void> incrementTotalGames() async {
    await _prefs?.setInt(_totalGamesKey, totalGames + 1);
    _changeController.add(null);
  }

  static int get wins => _prefs?.getInt(_winsKey) ?? 0;
  static Future<void> incrementWins() async {
    await _prefs?.setInt(_winsKey, wins + 1);
    _changeController.add(null);
  }

  static int get winStreak => _prefs?.getInt(_winStreakKey) ?? 0;
  static Future<void> setWinStreak(int value) async {
    await _prefs?.setInt(_winStreakKey, value);
    _changeController.add(null);
  }

  static double get winRate {
    final tg = totalGames;
    if (tg == 0) return 0.0;
    return wins / tg * 100.0;
  }

  static Future<void> resetStats() async {
    await _prefs?.remove(_xpKey);
    await _prefs?.remove(_totalGamesKey);
    await _prefs?.remove(_winsKey);
    await _prefs?.remove(_winStreakKey);
    _changeController.add(null);
  }

  // Settings properties
  static bool get soundEnabled => _prefs?.getBool(_soundEnabledKey) ?? true;
  static Future<void> setSoundEnabled(bool value) async {
    await _prefs?.setBool(_soundEnabledKey, value);
    _changeController.add(null);
  }

  static double get volume => _prefs?.getDouble(_volumeKey) ?? 1.0;
  static Future<void> setVolume(double value) async {
    await _prefs?.setDouble(_volumeKey, value);
    _changeController.add(null);
  }

  static bool get hapticsEnabled => _prefs?.getBool(_hapticsEnabledKey) ?? true;
  static Future<void> setHapticsEnabled(bool value) async {
    await _prefs?.setBool(_hapticsEnabledKey, value);
    _changeController.add(null);
  }

  static String get boardTheme => _prefs?.getString(_boardThemeKey) ?? 'Neon Dark';
  static Future<void> setBoardTheme(String value) async {
    await _prefs?.setString(_boardThemeKey, value);
    _changeController.add(null);
  }

  // Player name / avatar per local player slot
  static String playerName(int index) => _prefs?.getString('${_keyPrefix}player_name_$index') ?? 'Player ${index + 1}';
  static Future<void> setPlayerName(int index, String name) async {
    await _prefs?.setString('${_keyPrefix}player_name_$index', name);
    _changeController.add(null);
  }

  static String? playerAvatarPath(int index) => _prefs?.getString('${_keyPrefix}player_avatar_$index');
  static Future<void> setPlayerAvatarPath(int index, String path) async {
    await _prefs?.setString('${_keyPrefix}player_avatar_$index', path);
    _changeController.add(null);
  }

  static Future<void> dispose() async {
    await _changeController.close();
  }
}
