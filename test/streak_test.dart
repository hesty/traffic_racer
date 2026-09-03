import 'package:flutter_test/flutter_test.dart';
import 'package:turbo_traffic_rush/core/game_config.dart';
import 'package:turbo_traffic_rush/progression/day_key.dart';
import 'package:turbo_traffic_rush/progression/streak.dart';

void main() {
  test('day keys encode calendar days', () {
    expect(dayKeyOf(DateTime(2026, 9, 3, 23, 59)), 20260903);
    expect(dateOfDayKey(20260903), DateTime(2026, 9, 3));
  });

  group('StreakCalculator', () {
    test('starts at one, grows on consecutive days, resets after a gap', () {
      var s = StreakCalculator.registerPlay(Streak.none, DateTime(2026, 9, 1, 10));
      expect(s.count, 1);
      // Same day: unchanged (identical instance).
      expect(StreakCalculator.registerPlay(s, DateTime(2026, 9, 1, 22)), same(s));
      s = StreakCalculator.registerPlay(s, DateTime(2026, 9, 2, 1));
      expect(s.count, 2);
      s = StreakCalculator.registerPlay(s, DateTime(2026, 9, 3));
      expect(s.count, 3);
      s = StreakCalculator.registerPlay(s, DateTime(2026, 9, 5));
      expect(s.count, 1);
    });

    test('crosses month boundaries', () {
      final s = StreakCalculator.registerPlay(
          const Streak(count: 4, lastDayKey: 20260831), DateTime(2026, 9, 1));
      expect(s.count, 5);
    });
  });

  test('coin multiplier ramps and caps', () {
    expect(const Streak(count: 0, lastDayKey: 0).coinMultiplier, 1);
    expect(const Streak(count: 1, lastDayKey: 0).coinMultiplier, 1);
    expect(const Streak(count: 2, lastDayKey: 0).coinMultiplier,
        closeTo(1 + GameConfig.streakBonusPerDay, 1e-9));
    expect(const Streak(count: 50, lastDayKey: 0).coinMultiplier,
        closeTo(1 + GameConfig.streakBonusCap, 1e-9));
  });

  test('streak json round-trips', () {
    const s = Streak(count: 3, lastDayKey: 20260903);
    final copy = Streak.fromJson(s.toJson());
    expect(copy.count, 3);
    expect(copy.lastDayKey, 20260903);
  });
}
