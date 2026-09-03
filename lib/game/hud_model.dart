import 'package:flutter/foundation.dart';

import 'power_up_manager.dart';

/// Snapshot of what the HUD widgets display. The game pushes updates at a
/// modest rate so the widget tree is not rebuilt every frame.
class HudModel extends ChangeNotifier {
  int score = 0;
  int level = 1;
  int speedKmh = 0;
  int combo = 0;
  double comboProgress = 0;
  int bestScore = 0;
  Map<PowerUpType, double> powerUpProgress = const {};

  void publish({
    required int score,
    required int level,
    required int speedKmh,
    required int combo,
    required double comboProgress,
    required int bestScore,
    required Map<PowerUpType, double> powerUpProgress,
  }) {
    this.score = score;
    this.level = level;
    this.speedKmh = speedKmh;
    this.combo = combo;
    this.comboProgress = comboProgress;
    this.bestScore = bestScore;
    this.powerUpProgress = powerUpProgress;
    notifyListeners();
  }
}
