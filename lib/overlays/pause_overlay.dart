import 'package:flutter/material.dart';

import '../game/traffic_racer_game.dart';
import 'ui_theme.dart';

class PauseOverlay extends StatelessWidget {
  const PauseOverlay({super.key, required this.game});
  final TrafficRacerGame game;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: UiTheme.background.withValues(alpha: 0.94),
    child: SafeArea(
      child: FillOrScroll(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            const Center(
              child: Icon(
                Icons.pause_circle_outline_rounded,
                color: UiTheme.accent,
                size: 52,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Take a breather.',
              style: UiTheme.title(36),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Your run is paused. Ready when you are.',
              style: UiTheme.label,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: UiTheme.panelDecoration(),
              child: Row(
                children: [
                  Expanded(
                    child: RaceStat(
                      label: 'Score',
                      value: '${game.stats.score}',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: RaceStat(
                      label: 'Level',
                      value: '${game.stats.level}',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              label: 'Resume racing',
              icon: Icons.play_arrow_rounded,
              onPressed: game.resumeRun,
            ),
            const SizedBox(height: 12),
            GhostButton(
              label: 'Restart run',
              icon: Icons.replay_rounded,
              onPressed: game.restartRun,
            ),
            const SizedBox(height: 12),
            GhostButton(
              label: 'Back to menu',
              icon: Icons.home_outlined,
              onPressed: game.backToMenu,
            ),
            const SizedBox(height: 20),
            const Spacer(),
          ],
        ),
      ),
    ),
  );
}
