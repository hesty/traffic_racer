import 'mission.dart';

/// Immutable snapshot of one run's counters, in the units missions use.
class RunStats {
  const RunStats({
    required this.distanceMeters,
    required this.nearMisses,
    required this.bestCombo,
    required this.overtakes,
    required this.powerUpsCollected,
    required this.level,
    required this.surviveSeconds,
  });

  static const zero = RunStats(
    distanceMeters: 0,
    nearMisses: 0,
    bestCombo: 0,
    overtakes: 0,
    powerUpsCollected: 0,
    level: 1,
    surviveSeconds: 0,
  );

  final int distanceMeters;
  final int nearMisses;
  final int bestCombo;
  final int overtakes;
  final int powerUpsCollected;
  final int level;
  final int surviveSeconds;

  int valueFor(MissionKind kind) => switch (kind) {
        MissionKind.nearMisses => nearMisses,
        MissionKind.distanceMeters => distanceMeters,
        MissionKind.comboReached => bestCombo,
        MissionKind.overtakes => overtakes,
        MissionKind.powerUpsCollected => powerUpsCollected,
        MissionKind.levelReached => level,
        MissionKind.surviveSeconds => surviveSeconds,
      };
}
