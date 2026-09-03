import '../core/game_config.dart';
import '../progression/ghost_player.dart';
import '../progression/ghost_recorder.dart';
import '../progression/mission.dart';
import '../progression/run_stats.dart';
import '../progression/wallet.dart';
import '../services/garage_service.dart';
import '../services/ghost_service.dart';
import '../services/missions_service.dart';
import '../services/streak_service.dart';

/// Everything a finished run earned, for the game-over screen.
class RunSummary {
  const RunSummary({
    required this.runCoins,
    required this.missionCoins,
    required this.missionsCompleted,
    required this.allMissionsBonus,
    required this.ghostBeaten,
    required this.streakDays,
    required this.streakMultiplier,
  });

  /// Coins from distance, near misses and the ghost bonus (streak applied).
  final int runCoins;

  /// Coins paid for missions completed during this run, bonus included.
  final int missionCoins;
  final List<Mission> missionsCompleted;
  final bool allMissionsBonus;
  final bool ghostBeaten;
  final int streakDays;
  final double streakMultiplier;

  int get totalCoins => runCoins + missionCoins;
}

/// Glue between one run and the persistent progression features: missions,
/// coins/garage, the ghost racer and the daily streak. The game calls the
/// `onRun*` hooks; overlays read the services directly.
class ProgressionCoordinator {
  ProgressionCoordinator({DateTime Function()? now})
      : missions = MissionsService(now: now),
        streak = StreakService(now: now),
        garage = GarageService(),
        ghosts = GhostService();

  final MissionsService missions;
  final GarageService garage;
  final StreakService streak;
  final GhostService ghosts;

  final GhostRecorder _recorder = GhostRecorder();
  GhostPlayer? _ghost;

  /// Ghost position for the current frame; only meaningful when [hasGhost].
  final GhostPlayerState ghostState = GhostPlayerState();

  /// Missions completed by the most recent [onRunProgress] call.
  final List<Mission> justCompleted = [];
  bool allBonusJustEarned = false;
  bool ghostBeatenJustNow = false;
  bool ghostBeaten = false;

  final List<Mission> _completedThisRun = [];
  int _missionCoinsThisRun = 0;
  bool _allBonusThisRun = false;

  bool get hasGhost => _ghost != null;

  Future<void> load() => Future.wait([
        missions.load(),
        garage.load(),
        streak.load(),
        ghosts.load(),
      ]);

  void onRunStarted() {
    missions.onRunStarted();
    streak.registerPlay();
    _recorder.reset();
    final trace = ghosts.best.value;
    _ghost = trace == null ? null : (GhostPlayer(trace)..reset());
    ghostState
      ..distanceMeters = 0
      ..finished = false;
    justCompleted.clear();
    _completedThisRun.clear();
    _missionCoinsThisRun = 0;
    _allBonusThisRun = false;
    allBonusJustEarned = false;
    ghostBeatenJustNow = false;
    ghostBeaten = false;
  }

  /// Per-frame hook: records the player's pace and advances the ghost.
  void onRunTick({
    required double runTime,
    required double distanceMeters,
    required int lane,
  }) {
    _recorder.tick(runTime, distanceMeters: distanceMeters, lane: lane);
    _ghost?.sampleInto(runTime, ghostState);
  }

  /// Low-rate hook (HUD cadence): mission progress and the ghost-beaten check.
  /// Afterwards [justCompleted], [allBonusJustEarned] and [ghostBeatenJustNow]
  /// describe what happened in this call.
  void onRunProgress(RunStats stats) {
    justCompleted.clear();
    allBonusJustEarned = false;
    ghostBeatenJustNow = false;

    missions.onRunProgress(stats, justCompleted);
    for (final m in justCompleted) {
      garage.creditCoins(m.coinReward);
      _missionCoinsThisRun += m.coinReward;
      _completedThisRun.add(m);
    }
    if (missions.claimAllCompleteBonus()) {
      garage.creditCoins(GameConfig.missionAllCompleteBonus);
      _missionCoinsThisRun += GameConfig.missionAllCompleteBonus;
      _allBonusThisRun = true;
      allBonusJustEarned = true;
    }

    final ghost = _ghost;
    if (!ghostBeaten &&
        ghost != null &&
        stats.distanceMeters >= ghost.trace.finalDistanceMeters) {
      ghostBeaten = true;
      ghostBeatenJustNow = true;
    }
  }

  void onRunPaused() => missions.save();

  RunSummary onRunFinished(RunStats stats, {required bool isNewRecord}) {
    onRunProgress(stats);
    final runCoins = _runCoins(stats);
    garage.creditCoins(runCoins);
    missions.save();
    if (isNewRecord) ghosts.submit(_recorder.finish());
    return RunSummary(
      runCoins: runCoins,
      missionCoins: _missionCoinsThisRun,
      missionsCompleted: List.of(_completedThisRun),
      allMissionsBonus: _allBonusThisRun,
      ghostBeaten: ghostBeaten,
      streakDays: streak.streak.value.count,
      streakMultiplier: streak.coinMultiplier,
    );
  }

  /// What the run would pay if it ended now (for the HUD).
  int previewCoins(RunStats stats) => _runCoins(stats) + _missionCoinsThisRun;

  /// Metres the player is ahead of the ghost (negative = behind), or null
  /// without a ghost.
  int? ghostGapMeters(double distanceMeters) =>
      hasGhost ? (distanceMeters - ghostState.distanceMeters).round() : null;

  int _runCoins(RunStats stats) => CoinFormula.forRun(
        distanceMeters: stats.distanceMeters,
        nearMisses: stats.nearMisses,
        ghostBeaten: ghostBeaten,
        streakMultiplier: streak.coinMultiplier,
      );
}
