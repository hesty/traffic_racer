import 'package:flutter/material.dart';

import '../game/traffic_racer_game.dart';
import 'ui_theme.dart';

class PauseOverlay extends StatelessWidget {
  const PauseOverlay({super.key, required this.game});

  final TrafficRacerGame game;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xAA05071A),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(28),
          decoration: UiTheme.panelDecoration(radius: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('PAUSED', style: UiTheme.title(36)),
              const SizedBox(height: 28),
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
                label: 'MAIN MENU',
                icon: Icons.home_rounded,
                onPressed: game.backToMenu,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
