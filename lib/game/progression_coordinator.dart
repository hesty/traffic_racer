import '../core/game_config.dart';
import '../progression/mission.dart';
import '../progression/run_stats.dart';
import '../progression/wallet.dart';
import '../services/garage_service.dart';
import '../services/missions_service.dart';
import '../services/paywall_prompt_service.dart';
import '../services/purchase_service.dart';
import '../services/streak_service.dart';

/// Everything a finished run earned, for the game-over screen.
class RunSummary {
  const RunSummary({
    required this.runCoins,
    required this.missionCoins,
    required this.missionsCompleted,
    required this.allMissionsBonus,
    required this.streakDays,
    required this.streakMultiplier,
    required this.passMultiplier,
  });

  /// Coins from distance and near misses (streak applied).
  final int runCoins;

  /// Coins paid for missions completed during this run, bonus included.
  final int missionCoins;
  final List<Mission> missionsCompleted;
  final bool allMissionsBonus;
  final int streakDays;
  final double streakMultiplier;

  /// Coin multiplier the Turbo Pass contributed; 1 without a pass, and also 1
  /// while [GameConfig.passCoinMultiplier] leaves the pass purely cosmetic.
  final double passMultiplier;

  int get totalCoins => runCoins + missionCoins;
}

/// Glue between one run and the persistent progression features: missions,
/// coins/garage and the daily streak. The game calls the `onRun*` hooks;
/// overlays read the services directly.
class ProgressionCoordinator {
  ProgressionCoordinator({DateTime Function()? now})
      : missions = MissionsService(now: now),
        streak = StreakService(now: now),
        purchases = PurchaseService(),
        paywallPrompt = PaywallPromptService() {
    garage = GarageService(passActive: () => purchases.isActive);
    // The garage lends out the pass-only cars, so it has to repaint and
    // possibly drop its selection whenever the entitlement moves.
    purchases.addListener(garage.onPassChanged);
  }

  final MissionsService missions;
  late final GarageService garage;
  final StreakService streak;
  final PurchaseService purchases;
  final PaywallPromptService paywallPrompt;

  /// Set by [onRunFinished] when the just-ended run earned the one automatic
  /// paywall of this install.
  bool paywallDue = false;

  /// Missions completed by the most recent [onRunProgress] call.
  final List<Mission> justCompleted = [];
  bool allBonusJustEarned = false;

  final List<Mission> _completedThisRun = [];
  int _missionCoinsThisRun = 0;
  bool _allBonusThisRun = false;

  Future<void> load() async {
    await Future.wait([
      missions.load(),
      garage.load(),
      streak.load(),
      purchases.load(),
      paywallPrompt.load(),
    ]);
    // The stored selection was kept optimistically; settle it now that the
    // entitlement is known.
    garage.onPassChanged();
  }

  void onRunStarted() {
    missions.onRunStarted();
    streak.registerPlay();
    justCompleted.clear();
    _completedThisRun.clear();
    _missionCoinsThisRun = 0;
    _allBonusThisRun = false;
    allBonusJustEarned = false;
  }

  /// Low-rate hook (HUD cadence): mission progress. Afterwards [justCompleted]
  /// and [allBonusJustEarned] describe what happened in this call.
  void onRunProgress(RunStats stats) {
    justCompleted.clear();
    allBonusJustEarned = false;

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
  }

  void onRunPaused() => missions.save();

  RunSummary onRunFinished(RunStats stats) {
    onRunProgress(stats);
    final runCoins = _runCoins(stats);
    garage.creditCoins(runCoins);
    missions.save();
    paywallDue = paywallPrompt.onRunFinished(passActive: purchases.isActive);
    return RunSummary(
      runCoins: runCoins,
      missionCoins: _missionCoinsThisRun,
      missionsCompleted: List.of(_completedThisRun),
      allMissionsBonus: _allBonusThisRun,
      streakDays: streak.streak.value.count,
      streakMultiplier: streak.coinMultiplier,
      passMultiplier: purchases.coinMultiplier,
    );
  }

  /// What the run would pay if it ended now (for the HUD).
  int previewCoins(RunStats stats) => _runCoins(stats) + _missionCoinsThisRun;

  int _runCoins(RunStats stats) => CoinFormula.forRun(
        distanceMeters: stats.distanceMeters,
        nearMisses: stats.nearMisses,
        streakMultiplier: streak.coinMultiplier,
        passMultiplier: purchases.coinMultiplier,
      );
}
