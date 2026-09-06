import 'package:flutter/material.dart';

import '../core/game_config.dart';
import '../game/progression_coordinator.dart';
import '../game/traffic_racer_game.dart';
import 'ui_theme.dart';

/// End-of-run screen: score, one line of stats, what the run earned, and the
/// buttons to go again, visit the garage or leave.
class GameOverOverlay extends StatelessWidget {
  const GameOverOverlay({super.key, required this.game});

  final TrafficRacerGame game;

  @override
  Widget build(BuildContext context) {
    final stats = game.stats;
    final meters = game.distanceMeters;
    final distance = meters >= 1000
        ? '${(meters / 1000).toStringAsFixed(1)} km'
        : '$meters m';
    final summary = game.lastRunSummary;

    return MenuSurface(
      child: SizedBox(
        child: FillOrScroll(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              Icon(
                game.isNewRecord
                    ? Icons.emoji_events_outlined
                    : Icons.sports_score_rounded,
                color: UiTheme.accent,
                size: 40,
              ),
              const SizedBox(height: 12),
              Text(
                game.isNewRecord ? 'A new personal best.' : 'What a ride.',
                style: UiTheme.title(32),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Run complete',
                style: UiTheme.label,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Text(
                '${stats.score}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 64,
                  letterSpacing: -2,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                game.isNewRecord
                    ? 'Personal record'
                    : 'Personal best  ${game.highScores.bestScore.value}',
                textAlign: TextAlign.center,
                style: UiTheme.label.copyWith(
                  fontSize: 14,
                  color: game.isNewRecord ? UiTheme.accent : Colors.white70,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 18,
                ),
                decoration: UiTheme.panelDecoration(),
                child: Row(
                  children: [
                    Expanded(
                      child: RaceStat(label: 'Level', value: '${stats.level}'),
                    ),
                    Expanded(
                      child: RaceStat(label: 'Distance', value: distance),
                    ),
                    Expanded(
                      child: RaceStat(
                        label: 'Near misses',
                        value: '${stats.nearMisses}',
                      ),
                    ),
                  ],
                ),
              ),
              if (summary != null) ...[
                const SizedBox(height: 18),
                _Rewards(summary: summary),
              ],
              const SizedBox(height: 24),
              const Spacer(flex: 3),
              ListenableBuilder(
                listenable: game.progression.purchases,
                builder: (_, _) => game.progression.purchases.isActive
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: PassBanner(
                          onTap: game.openPaywall,
                          message: game.lastTestDriveSkin != null
                              ? 'Enjoyed ${game.lastTestDriveSkin!.label}? Keep driving it with Turbo Pass.'
                              : summary != null &&
                                    summary.potentialPassBonus > 0
                              ? 'This run with Turbo Pass: +${summary.potentialPassBonus} extra coins. See benefits'
                              : null,
                        ),
                      ),
              ),
              PrimaryButton(
                label: 'Race again',
                icon: Icons.replay_rounded,
                onPressed: game.startRun,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GhostButton(
                      label: 'Garage',
                      icon: Icons.garage_rounded,
                      onPressed: game.openGarage,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GhostButton(
                      label: 'Menu',
                      icon: Icons.home_rounded,
                      onPressed: game.backToMenu,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

/// Coins earned plus every bonus line that applied to this run.
class _Rewards extends StatelessWidget {
  const _Rewards({required this.summary});

  final RunSummary summary;

  @override
  Widget build(BuildContext context) {
    final multiplier = summary.streakMultiplier.toStringAsFixed(1);
    return Column(
      children: [
        InfoChip(
          icon: Icons.monetization_on_rounded,
          text: '+${summary.totalCoins} coins earned',
          color: UiTheme.coin,
          fontSize: 18,
        ),
        if (summary.streakDays > 1) ...[
          const SizedBox(height: 6),
          Text(
            '${summary.streakDays}-day streak: ×$multiplier coins',
            style: UiTheme.label.copyWith(
              color: UiTheme.accentDark,
              fontSize: 12,
            ),
          ),
        ],
        if (summary.passMultiplier > 1) ...[
          const SizedBox(height: 6),
          Text(
            'Turbo Pass: ×${summary.passMultiplier.toStringAsFixed(1)} coins',
            style: UiTheme.label.copyWith(color: UiTheme.pass, fontSize: 12),
          ),
        ],
        const SizedBox(height: 10),
        for (final m in summary.missionsCompleted)
          _BonusLine(
            icon: Icons.check_circle_rounded,
            text: m.description,
            reward: m.coinReward,
            color: UiTheme.accent,
          ),
        if (summary.allMissionsBonus)
          const _BonusLine(
            icon: Icons.emoji_events_rounded,
            text: 'All missions done',
            reward: GameConfig.missionAllCompleteBonus,
            color: UiTheme.accent,
          ),
      ],
    );
  }
}

class _BonusLine extends StatelessWidget {
  const _BonusLine({
    required this.icon,
    required this.text,
    required this.reward,
    required this.color,
  });

  final IconData icon;
  final String text;
  final int reward;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: UiTheme.label.copyWith(color: Colors.white, fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '+$reward',
            style: const TextStyle(
              color: UiTheme.coin,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
