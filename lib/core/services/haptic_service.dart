import 'package:flutter/services.dart';
import 'package:ludo_game/core/services/player_prefs.dart';

/// Thin wrapper around [HapticFeedback] that respects user settings.
class HapticService {
  HapticService._();

  static Future<void> lightTap() async {
    if (PlayerPrefs.hapticsEnabled) {
      await HapticFeedback.lightImpact();
    }
  }

  static Future<void> mediumTap() async {
    if (PlayerPrefs.hapticsEnabled) {
      await HapticFeedback.mediumImpact();
    }
  }

  static Future<void> heavyTap() async {
    if (PlayerPrefs.hapticsEnabled) {
      await HapticFeedback.heavyImpact();
    }
  }

  static Future<void> selection() async {
    if (PlayerPrefs.hapticsEnabled) {
      await HapticFeedback.selectionClick();
    }
  }

  static Future<void> vibrate() async {
    if (PlayerPrefs.hapticsEnabled) {
      await HapticFeedback.vibrate();
    }
  }
}
