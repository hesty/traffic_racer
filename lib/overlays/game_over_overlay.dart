import 'package:flutter/material.dart';

import '../game/traffic_racer_game.dart';
import 'ui_theme.dart';

/// Minimal end-of-run screen: score, one line of stats, two buttons.
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

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xAA05071A),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              ShaderMask(
                shaderCallback: (b) => const LinearGradient(
                  colors: [Color(0xFFFF5252), UiTheme.accentDark],
                ).createShader(b),
                child: Text('WRECKED', style: UiTheme.title(40)),
              ),
              const SizedBox(height: 24),
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
              const SizedBox(height: 20),
              Text(
                'LV ${stats.level}   ·   $distance   ·   ${stats.nearMisses} NEAR MISS',
                textAlign: TextAlign.center,
                style: UiTheme.label.copyWith(color: Colors.white),
              ),
              const Spacer(flex: 3),
              PrimaryButton(
                label: 'RACE AGAIN',
                icon: Icons.replay_rounded,
                onPressed: game.startRun,
              ),
              const SizedBox(height: 12),
              GhostButton(
                label: 'MENU',
                icon: Icons.home_rounded,
                onPressed: game.backToMenu,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
