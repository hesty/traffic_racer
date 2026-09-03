import 'package:flutter_test/flutter_test.dart';
import 'package:turbo_traffic_rush/core/game_config.dart';
import 'package:turbo_traffic_rush/progression/mission.dart';
import 'package:turbo_traffic_rush/progression/mission_catalog.dart';
import 'package:turbo_traffic_rush/progression/mission_tracker.dart';
import 'package:turbo_traffic_rush/progression/run_stats.dart';

RunStats stats({
  int distance = 0,
  int nearMisses = 0,
  int combo = 0,
  int overtakes = 0,
  int powerUps = 0,
  int level = 1,
  int seconds = 0,
}) =>
    RunStats(
      distanceMeters: distance,
      nearMisses: nearMisses,
      bestCombo: combo,
      overtakes: overtakes,
      powerUpsCollected: powerUps,
      level: level,
      surviveSeconds: seconds,
    );

void main() {
  group('MissionCatalog', () {
    test('is deterministic per day and varies between days', () {
      final a = MissionCatalog.forDay(20260903);
      final b = MissionCatalog.forDay(20260903);
      final c = MissionCatalog.forDay(20260904);
      expect(a.length, GameConfig.missionsPerDay);
      expect([for (final m in a) (m.kind, m.target)],
          [for (final m in b) (m.kind, m.target)]);
      expect(
        [for (final m in a) (m.kind, m.target)] !=
            [for (final m in c) (m.kind, m.target)],
        isTrue,
      );
    });

    test('rolls distinct kinds with matching tier rewards', () {
      for (var day = 20260101; day < 20260131; day++) {
        final missions = MissionCatalog.forDay(day);
        expect(missions.map((m) => m.kind).toSet().length, missions.length);
        for (final m in missions) {
          final tier = m.kind.targets.indexOf(m.target);
          expect(tier, greaterThanOrEqualTo(0));
          expect(m.coinReward, GameConfig.missionRewards[tier]);
        }
      }
    });
  });

  group('Mission', () {
    test('round-trips through json', () {
      final m = Mission(
          id: 'x', kind: MissionKind.distanceMeters, target: 2500, coinReward: 60)
        ..progress = 1200;
      final copy = Mission.fromJson(m.toJson());
      expect(copy.kind, MissionKind.distanceMeters);
      expect(copy.progress, 1200);
      expect(copy.completed, isFalse);
      expect(copy.progressLabel, '1.2 km / 2.5 km');
      expect(copy.description, 'Drive 2.5 km');
    });
  });

  group('MissionTracker', () {
    test('cumulative kinds add up across runs', () {
      final m = Mission(
          id: 'a', kind: MissionKind.nearMisses, target: 10, coinReward: 40);
      final tracker = MissionTracker([m]);
      final done = <Mission>[];

      tracker.onRunStarted();
      tracker.onRunTick(stats(nearMisses: 4), done);
      expect(m.progress, 4);
      expect(done, isEmpty);

      tracker.onRunStarted();
      tracker.onRunTick(stats(nearMisses: 3), done);
      expect(m.progress, 7);
      tracker.onRunTick(stats(nearMisses: 6), done);
      expect(m.progress, 10);
      expect(done, [m]);
      expect(m.completed, isTrue);

      // Completed missions stop changing and never fire twice.
      tracker.onRunTick(stats(nearMisses: 20), done);
      expect(done.length, 1);
      expect(m.progress, 10);
    });

    test('best-single-run kinds keep the day best but do not add', () {
      final m = Mission(
          id: 'b', kind: MissionKind.comboReached, target: 5, coinReward: 40);
      final tracker = MissionTracker([m]);
      final done = <Mission>[];

      tracker.onRunStarted();
      tracker.onRunTick(stats(combo: 3), done);
      tracker.onRunStarted();
      tracker.onRunTick(stats(combo: 2), done);
      expect(m.progress, 3);
      tracker.onRunTick(stats(combo: 5), done);
      expect(done, [m]);
    });

    test('reports whether progress changed', () {
      final m = Mission(
          id: 'c', kind: MissionKind.surviveSeconds, target: 60, coinReward: 40);
      final tracker = MissionTracker([m])..onRunStarted();
      final done = <Mission>[];
      expect(tracker.onRunTick(stats(seconds: 10), done), isTrue);
      expect(tracker.onRunTick(stats(seconds: 10), done), isFalse);
      expect(tracker.allCompleted, isFalse);
      tracker.onRunTick(stats(seconds: 61), done);
      expect(tracker.allCompleted, isTrue);
    });
  });
}
