import 'package:flutter/material.dart';

import '../game/traffic_racer_game.dart';
import 'ui_theme.dart';

class PauseOverlay extends StatelessWidget {
  const PauseOverlay({super.key, required this.game});

  final TrafficRacerGame game;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xAA05071A),
      child: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            Text('PAUSED', style: UiTheme.title(40)),
            const Spacer(flex: 3),
            PrimaryButton(
              label: 'RESUME',
              icon: Icons.play_arrow_rounded,
              onPressed: game.resumeRun,
            ),
            const SizedBox(height: 12),
            GhostButton(
              label: 'RESTART',
              icon: Icons.replay_rounded,
              onPressed: game.restartRun,
            ),
            const SizedBox(height: 12),
            GhostButton(
              label: 'MENU',
              icon: Icons.home_rounded,
              onPressed: game.backToMenu,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
