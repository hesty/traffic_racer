import 'package:flutter_test/flutter_test.dart';
import 'package:turbo_traffic_rush/core/game_config.dart';
import 'package:turbo_traffic_rush/game/power_up_manager.dart';
import 'package:turbo_traffic_rush/game/score_keeper.dart';

void main() {
  group('ScoreKeeper', () {
    test('distance converts to score and levels up', () {
      final s = ScoreKeeper();
      var levelled = false;
      for (var i = 0; i < 100; i++) {
        levelled |= s.addDistance(GameConfig.scorePerLevel *
            GameConfig.distanceScoreDivisor /
            50);
      }
      expect(s.score, greaterThanOrEqualTo(GameConfig.scorePerLevel * 2));
      expect(s.level, greaterThan(1));
      expect(levelled, isTrue);
    });

    test('near misses build a combo that expires', () {
      final s = ScoreKeeper();
      expect(s.registerNearMiss(), GameConfig.nearMissBonus);
      expect(s.registerNearMiss(), GameConfig.nearMissBonus * 2);
      expect(s.combo, 2);
      s.tick(GameConfig.comboWindow + 0.1);
      expect(s.combo, 0);
      expect(s.bestCombo, 2);
      expect(s.nearMisses, 2);
    });

    test('score multiplier scales near-miss bonus', () {
      final s = ScoreKeeper();
      expect(s.registerNearMiss(multiplier: 2), GameConfig.nearMissBonus * 2);
    });
  });

  group('PowerUpManager', () {
    test('timers count down with frame time', () {
      final p = PowerUpManager();
      p.activate(PowerUpType.shield);
      expect(p.shielded, isTrue);
      expect(p.tick(GameConfig.powerUpDuration / 2), isEmpty);
      expect(p.shielded, isTrue);
      expect(p.tick(GameConfig.powerUpDuration), [PowerUpType.shield]);
      expect(p.shielded, isFalse);
    });

    test('nitro and slow motion are mutually exclusive', () {
      final p = PowerUpManager();
      p.activate(PowerUpType.slowMotion);
      p.activate(PowerUpType.nitro);
      expect(p.isActive(PowerUpType.slowMotion), isFalse);
      expect(p.speedMultiplier, GameConfig.nitroMultiplier);
      expect(p.timeScale, 1);
    });
  });
}
