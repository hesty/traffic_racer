import 'package:flutter/material.dart';

import '../game/traffic_racer_game.dart';
import 'ui_theme.dart';

class GameOverOverlay extends StatelessWidget {
  const GameOverOverlay({super.key, required this.game});

  final TrafficRacerGame game;

  @override
  Widget build(BuildContext context) {
    final stats = game.stats;
    return Container(
      color: const Color(0xBB05071A),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 28),
              padding: const EdgeInsets.all(24),
              decoration: UiTheme.panelDecoration(radius: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShaderMask(
                    shaderCallback: (b) => const LinearGradient(
                      colors: [Color(0xFFFF5252), UiTheme.accentDark],
                    ).createShader(b),
                    child: Text('WRECKED', style: UiTheme.title(40)),
                  ),
                  if (game.isNewRecord) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: UiTheme.accent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.emoji_events, size: 18, color: Colors.black),
                          SizedBox(width: 6),
                          Text('NEW HIGH SCORE',
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2)),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Text('${stats.score}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 56,
                          fontWeight: FontWeight.w900,
                          height: 1)),
                  Text('SCORE', style: UiTheme.label),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        StatTile(
                          icon: Icons.speed,
                          label: 'Level',
                          value: '${stats.level}',
                          color: const Color(0xFF39C0FF),
                        ),
                        StatTile(
                          icon: Icons.straighten,
                          label: 'Distance',
                          value: _distance(game.distanceMeters),
                          color: const Color(0xFF66BB6A),
                        ),
                        StatTile(
                          icon: Icons.bolt,
                          label: 'Near miss',
                          value: '${stats.nearMisses}',
                          color: UiTheme.accent,
                        ),
                        StatTile(
                          icon: Icons.whatshot,
                          label: 'Best combo',
                          value: 'x${stats.bestCombo}',
                          color: UiTheme.accentDark,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ValueListenableBuilder<int>(
                    valueListenable: game.highScores.bestScore,
                    builder: (_, best, _) =>
                        Text('BEST  $best', style: UiTheme.label),
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'RACE AGAIN',
                    icon: Icons.replay_rounded,
                    onPressed: game.startRun,
                  ),
                  const SizedBox(height: 12),
                  GhostButton(
                    label: 'MAIN MENU',
                    icon: Icons.home_rounded,
                    onPressed: game.backToMenu,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _distance(int meters) =>
      meters >= 1000 ? '${(meters / 1000).toStringAsFixed(1)} km' : '$meters m';
}
