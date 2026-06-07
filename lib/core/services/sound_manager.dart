import 'package:audioplayers/audioplayers.dart';
import 'package:ludo_game/core/services/player_prefs.dart';

/// Sound types used throughout Ludo Elite.
enum SoundType {
  diceRoll,
  tokenMove,
  capture,
  victory,
  buttonClick,
  bonusRoll,
}

/// Singleton audio manager.
///
/// Falls back gracefully if sound files are missing.
class SoundManager {
  static final SoundManager _instance = SoundManager._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  late bool _isMuted;
  late double _volume;

  factory SoundManager() => _instance;

  SoundManager._internal() {
    _isMuted = !PlayerPrefs.soundEnabled;
    _volume = PlayerPrefs.volume;
  }

  bool get isMuted => _isMuted;
  double get volume => _volume;

  /// Play a sound effect identified by [type].
  Future<void> playSound(SoundType type) async {
    if (_isMuted) return;

    final soundPath = _getSoundPath(type);
    try {
      await _audioPlayer.play(
        AssetSource(soundPath),
        volume: _volume,
      );
    } catch (_) {
      // Gracefully ignore – sound file may not exist yet.
    }
  }

  String _getSoundPath(SoundType type) {
    switch (type) {
      case SoundType.diceRoll:
        return 'sounds/dice_roll.mp3';
      case SoundType.tokenMove:
        return 'sounds/token_move.mp3';
      case SoundType.capture:
        return 'sounds/capture.mp3';
      case SoundType.victory:
        return 'sounds/victory.mp3';
      case SoundType.buttonClick:
        return 'sounds/button_click.mp3';
      case SoundType.bonusRoll:
        return 'sounds/bonus_roll.mp3';
    }
  }

  void toggleMute() {
    _isMuted = !_isMuted;
    PlayerPrefs.setSoundEnabled(!_isMuted);
  }

  void setMuted(bool muted) {
    _isMuted = muted;
    PlayerPrefs.setSoundEnabled(!_isMuted);
  }

  void setVolume(double v) {
    _volume = v.clamp(0.0, 1.0);
    PlayerPrefs.setVolume(_volume);
  }

  Future<void> stopAll() async {
    await _audioPlayer.stop();
  }

  Future<void> dispose() async {
    await _audioPlayer.dispose();
  }
}
