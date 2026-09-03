import '../core/game_config.dart';

/// Tracks score, level, distance and the near-miss combo for a single run.
class ScoreKeeper {
  int score = 0;
  int level = 1;
  int combo = 0;
  int bestCombo = 0;
  int nearMisses = 0;
  int overtakes = 0;
  double distance = 0;
  double comboTimeLeft = 0;

  double _scoreAccumulator = 0;

  bool get comboActive => combo > 0 && comboTimeLeft > 0;

  void reset() {
    score = 0;
    level = 1;
    combo = 0;
    bestCombo = 0;
    nearMisses = 0;
    overtakes = 0;
    distance = 0;
    comboTimeLeft = 0;
    _scoreAccumulator = 0;
  }

  /// Advances the run by [dz] world units. Returns true when the level
  /// increased during this call.
  bool addDistance(double dz, {double multiplier = 1}) {
    distance += dz;
    _scoreAccumulator += dz / GameConfig.distanceScoreDivisor * multiplier;
    final whole = _scoreAccumulator.floor();
    if (whole > 0) {
      score += whole;
      _scoreAccumulator -= whole;
    }
    return _refreshLevel();
  }

  /// Registers a close pass and returns the bonus awarded.
  int registerNearMiss({double multiplier = 1}) {
    combo += 1;
    if (combo > bestCombo) bestCombo = combo;
    nearMisses += 1;
    comboTimeLeft = GameConfig.comboWindow;
    final bonus = (GameConfig.nearMissBonus * combo * multiplier).round();
    score += bonus;
    _refreshLevel();
    return bonus;
  }

  void registerOvertake() => overtakes += 1;

  void tick(double dt) {
    if (comboTimeLeft > 0) {
      comboTimeLeft -= dt;
      if (comboTimeLeft <= 0) {
        comboTimeLeft = 0;
        combo = 0;
      }
    }
  }

  bool _refreshLevel() {
    final newLevel = score ~/ GameConfig.scorePerLevel + 1;
    if (newLevel != level) {
      level = newLevel;
      return true;
    }
    return false;
  }
}
