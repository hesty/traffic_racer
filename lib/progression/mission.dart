import '../core/game_config.dart';

enum MissionKind {
  nearMisses,
  distanceMeters,
  comboReached,
  overtakes,
  powerUpsCollected,
  levelReached,
  surviveSeconds,
}

extension MissionKindInfo on MissionKind {
  /// Cumulative kinds add up across every run of the day; the others only
  /// count the best single run.
  bool get isCumulative => switch (this) {
        MissionKind.nearMisses ||
        MissionKind.distanceMeters ||
        MissionKind.overtakes ||
        MissionKind.powerUpsCollected =>
          true,
        _ => false,
      };

  List<int> get targets => switch (this) {
        MissionKind.nearMisses => GameConfig.missionNearMissTargets,
        MissionKind.distanceMeters => GameConfig.missionDistanceTargets,
        MissionKind.comboReached => GameConfig.missionComboTargets,
        MissionKind.overtakes => GameConfig.missionOvertakeTargets,
        MissionKind.powerUpsCollected => GameConfig.missionPowerUpTargets,
        MissionKind.levelReached => GameConfig.missionLevelTargets,
        MissionKind.surviveSeconds => GameConfig.missionSurviveTargets,
      };
}

/// One daily goal. Progress is mutated in place by the tracker and persisted
/// by the missions service.
class Mission {
  Mission({
    required this.id,
    required this.kind,
    required this.target,
    required this.coinReward,
    this.progress = 0,
    this.completed = false,
  });

  final String id;
  final MissionKind kind;
  final int target;
  final int coinReward;
  int progress;
  bool completed;

  double get progressFraction =>
      target == 0 ? 1 : (progress / target).clamp(0.0, 1.0);

  String get description => switch (kind) {
        MissionKind.nearMisses => 'Near miss $target cars',
        MissionKind.distanceMeters => 'Drive ${_km(target)}',
        MissionKind.comboReached => 'Reach combo x$target',
        MissionKind.overtakes => 'Overtake $target cars',
        MissionKind.powerUpsCollected => 'Collect $target power-ups',
        MissionKind.levelReached => 'Reach level $target',
        MissionKind.surviveSeconds => 'Survive $target s',
      };

  /// Short progress label, e.g. `1.2 / 2.5 km` or `3 / 5`.
  String get progressLabel => kind == MissionKind.distanceMeters
      ? '${_km(progress.clamp(0, target))} / ${_km(target)}'
      : '${progress.clamp(0, target)} / $target';

  static String _km(int meters) {
    final km = meters / 1000;
    final text = km == km.roundToDouble()
        ? km.toStringAsFixed(0)
        : km.toStringAsFixed(1);
    return '$text km';
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'kind': kind.name,
        'target': target,
        'reward': coinReward,
        'progress': progress,
        'completed': completed,
      };

  factory Mission.fromJson(Map<String, Object?> json) => Mission(
        id: json['id'] as String,
        kind: MissionKind.values.byName(json['kind'] as String),
        target: json['target'] as int,
        coinReward: json['reward'] as int,
        progress: json['progress'] as int? ?? 0,
        completed: json['completed'] as bool? ?? false,
      );
}
