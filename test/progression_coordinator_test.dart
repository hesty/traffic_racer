import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turbo_traffic_rush/core/game_config.dart';
import 'package:turbo_traffic_rush/game/progression_coordinator.dart';
import 'package:turbo_traffic_rush/progression/car_catalog.dart';
import 'package:turbo_traffic_rush/progression/mission.dart';
import 'package:turbo_traffic_rush/progression/run_stats.dart';
import 'package:turbo_traffic_rush/services/missions_service.dart';

/// Drives the coordinator like the game does: a fixed clock, mocked prefs,
/// and run snapshots fed through the hooks.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  var today = DateTime(2026, 9, 3, 12);
  DateTime now() => today;

  RunStats snapshot({int distance = 0, int nearMisses = 0, int seconds = 0}) =>
      RunStats(
        distanceMeters: distance,
        nearMisses: nearMisses,
        bestCombo: 0,
        overtakes: 0,
        powerUpsCollected: 0,
        level: 1,
        surviveSeconds: seconds,
      );

  setUp(() {
    today = DateTime(2026, 9, 3, 12);
    SharedPreferences.setMockInitialValues({});
  });

  test('pass doubles run earnings without doubling mission rewards', () async {
    final free = ProgressionCoordinator(now: now);
    await free.load();
    free.onRunStarted();
    final stats = snapshot(distance: 2400, nearMisses: 5, seconds: 60);
    final freeSummary = free.onRunFinished(stats);
    SharedPreferences.setMockInitialValues({'pass_active_v1': true});
    final paid = ProgressionCoordinator(now: now);
    await paid.load();
    paid.onRunStarted();
    final paidSummary = paid.onRunFinished(stats);
    expect(paidSummary.runCoins, freeSummary.runCoins * 2);
    expect(paidSummary.missionCoins, freeSummary.missionCoins);
    expect(
      freeSummary.potentialPassBonus,
      paidSummary.runCoins - freeSummary.runCoins,
    );
    expect(paidSummary.potentialPassBonus, 0);
  });

  test('a run pays coins and persists', () async {
    final p = ProgressionCoordinator(now: now);
    await p.load();
    expect(p.missions.missions.length, GameConfig.missionsPerDay);

    p.onRunStarted();
    expect(p.streak.streak.value.count, 1);
    p.onRunProgress(snapshot(distance: 2400, nearMisses: 5, seconds: 60));
    final summary = p.onRunFinished(
      snapshot(distance: 2400, nearMisses: 5, seconds: 60),
    );

    expect(
      summary.runCoins,
      (2400 * GameConfig.coinsPerMeter).round() +
          5 * GameConfig.coinsPerNearMiss,
    );
    expect(p.garage.coins, summary.totalCoins);

    // Everything survives a reload from the same prefs.
    final again = ProgressionCoordinator(now: now);
    await again.load();
    expect(again.garage.coins, p.garage.coins);
    expect(again.streak.streak.value.count, 1);
    expect(
      [for (final m in again.missions.missions) m.progress],
      [for (final m in p.missions.missions) m.progress],
    );
  });

  test('missions pay on completion and the all-done bonus once', () async {
    final p = ProgressionCoordinator(now: now);
    await p.load();
    p.onRunStarted();
    final before = p.garage.coins;

    // Max out every stat so all missions complete in one snapshot.
    const huge = RunStats(
      distanceMeters: 100000,
      nearMisses: 1000,
      bestCombo: 100,
      overtakes: 1000,
      powerUpsCollected: 100,
      level: 50,
      surviveSeconds: 10000,
    );
    p.onRunProgress(huge);
    expect(p.justCompleted.length, GameConfig.missionsPerDay);
    expect(p.allBonusJustEarned, isTrue);
    final rewards = p.justCompleted.fold<int>(0, (a, m) => a + m.coinReward);
    expect(
      p.garage.coins - before,
      rewards + GameConfig.missionAllCompleteBonus,
    );

    p.onRunProgress(huge);
    expect(p.justCompleted, isEmpty);
    expect(p.allBonusJustEarned, isFalse);

    final summary = p.onRunFinished(huge);
    expect(summary.missionsCompleted.length, GameConfig.missionsPerDay);
    expect(summary.allMissionsBonus, isTrue);
    expect(summary.missionCoins, rewards + GameConfig.missionAllCompleteBonus);
  });

  test('missions roll over when the day changes', () async {
    final service = MissionsService(now: now);
    await service.load();
    final first = [for (final m in service.missions) (m.kind, m.target)];
    service.onRunProgress(
      const RunStats(
        distanceMeters: 100000,
        nearMisses: 1000,
        bestCombo: 100,
        overtakes: 1000,
        powerUpsCollected: 100,
        level: 50,
        surviveSeconds: 10000,
      ),
      <Mission>[],
    );
    expect(service.allCompleted, isTrue);

    today = DateTime(2026, 9, 4, 0, 5);
    service.onRunStarted();
    expect(service.allCompleted, isFalse);
    expect(service.missions.every((m) => m.progress == 0), isTrue);
    expect(
      [for (final m in service.missions) (m.kind, m.target)] != first,
      isTrue,
    );
  });

  test('garage purchase goes through the wallet', () async {
    final p = ProgressionCoordinator(now: now);
    await p.load();
    final car = CarCatalog.all[1];
    expect(p.garage.buy(car.id), isFalse);
    p.garage.creditCoins(car.price);
    expect(p.garage.buy(car.id), isTrue);
    expect(p.garage.selectedSkin.id, car.id);
    expect(p.garage.coins, 0);
  });
}
