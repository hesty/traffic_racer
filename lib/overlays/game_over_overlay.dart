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

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xAA05071A),
      child: SafeArea(
        child: FillOrScroll(
          child: Column(
            children: [
              const Spacer(flex: 2),
              ShaderMask(
                shaderCallback: (b) => const LinearGradient(
                  colors: [Color(0xFFFF5252), UiTheme.accentDark],
                ).createShader(b),
                child: Text('WRECKED', style: UiTheme.title(40)),
              ),
              const SizedBox(height: 20),
              Text('${stats.score}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 72,
                      fontWeight: FontWeight.w900,
                      height: 1)),
              const SizedBox(height: 6),
              Text(
                game.isNewRecord
                    ? 'NEW BEST'
                    : 'BEST  ${game.highScores.bestScore.value}',
                style: UiTheme.label.copyWith(
                    fontSize: 14,
                    color: game.isNewRecord ? UiTheme.accent : Colors.white70),
              ),
              const SizedBox(height: 16),
              Text(
                'LV ${stats.level}   ·   $distance   ·   ${stats.nearMisses} NEAR MISS',
                textAlign: TextAlign.center,
                style: UiTheme.label.copyWith(color: Colors.white),
              ),
              if (summary != null) ...[
                const SizedBox(height: 18),
                _Rewards(summary: summary),
              ],
              const Spacer(flex: 3),
              PrimaryButton(
                label: 'RACE AGAIN',
                icon: Icons.replay_rounded,
                onPressed: game.startRun,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GhostButton(
                      label: 'GARAGE',
                      icon: Icons.garage_rounded,
                      onPressed: game.openGarage,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GhostButton(
                      label: 'MENU',
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
          text: '+${summary.totalCoins} COINS',
          color: UiTheme.coin,
          fontSize: 18,
        ),
        if (summary.streakDays > 1) ...[
          const SizedBox(height: 6),
          Text(
            '${summary.streakDays} DAY STREAK  ·  x$multiplier COINS',
            style: UiTheme.label.copyWith(color: UiTheme.accentDark, fontSize: 12),
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
        if (summary.ghostBeaten)
          const _BonusLine(
            icon: Icons.flag_rounded,
            text: 'Ghost beaten',
            reward: GameConfig.ghostBeatenBonus,
            color: TrafficRacerGame.ghostColor,
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
            child: Text(text.toUpperCase(),
                overflow: TextOverflow.ellipsis,
                style: UiTheme.label.copyWith(color: Colors.white, fontSize: 12)),
          ),
          const SizedBox(width: 8),
          Text('+$reward',
              style: const TextStyle(
                  color: UiTheme.coin, fontWeight: FontWeight.w800, fontSize: 13)),
        ],
      ),
    );
  }
}
