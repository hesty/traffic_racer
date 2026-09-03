import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stores the best score and distance on the device.
class HighScoreService {
  static const _scoreKey = 'high_score';
  static const _distanceKey = 'best_distance_m';

  final ValueNotifier<int> bestScore = ValueNotifier(0);
  final ValueNotifier<int> bestDistanceMeters = ValueNotifier(0);

  SharedPreferences? _prefs;

  Future<void> load() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      bestScore.value = _prefs!.getInt(_scoreKey) ?? 0;
      bestDistanceMeters.value = _prefs!.getInt(_distanceKey) ?? 0;
    } catch (_) {}
  }

  /// Records a finished run. Returns true when a new high score was set.
  bool submit({required int score, required int distanceMeters}) {
    var isRecord = false;
    if (score > bestScore.value) {
      bestScore.value = score;
      _prefs?.setInt(_scoreKey, score);
      isRecord = true;
    }
    if (distanceMeters > bestDistanceMeters.value) {
      bestDistanceMeters.value = distanceMeters;
      _prefs?.setInt(_distanceKey, distanceMeters);
    }
    return isRecord;
  }
}
