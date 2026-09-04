import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/game_config.dart';

/// Decides when the paywall may show itself unprompted.
///
/// Exactly one automatic prompt per install: once the player has finished
/// [GameConfig.paywallAutoPromptAfterRuns] runs they see the paywall a single
/// time, and never again unless they open it themselves.
class PaywallPromptService {
  static const _runsKey = 'runs_completed';
  static const _shownKey = 'paywall_auto_shown';

  int _runsCompleted = 0;
  bool _autoShown = false;
  SharedPreferences? _prefs;

  int get runsCompleted => _runsCompleted;
  bool get autoShown => _autoShown;

  Future<void> load() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _runsCompleted = _prefs!.getInt(_runsKey) ?? 0;
      _autoShown = _prefs!.getBool(_shownKey) ?? false;
    } catch (e) {
      debugPrint('Paywall prompt load failed: $e');
    }
  }

  /// Counts a finished run and answers whether the paywall should open itself
  /// now. Returns true at most once per install, and never while [passActive].
  bool onRunFinished({required bool passActive}) {
    _runsCompleted++;
    _prefs?.setInt(_runsKey, _runsCompleted);
    if (passActive || _autoShown) return false;
    if (_runsCompleted < GameConfig.paywallAutoPromptAfterRuns) return false;
    _autoShown = true;
    _prefs?.setBool(_shownKey, true);
    return true;
  }
}
