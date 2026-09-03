import 'package:flutter/material.dart';

import '../game/hud_model.dart';
import '../game/power_up_manager.dart';
import '../game/traffic_racer_game.dart';
import 'ui_theme.dart';

/// In-race heads-up display: score, level, speed, combo and power-up timers.
class HudOverlay extends StatelessWidget {
  const HudOverlay({super.key, required this.game});

  final TrafficRacerGame game;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: ListenableBuilder(
          listenable: game.hud,
          builder: (context, _) {
            final hud = game.hud;
            return Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PauseButton(onPressed: game.pauseRun),
                    const Spacer(),
                    _ScoreBlock(hud: hud),
                    const Spacer(),
                    _Chip(icon: Icons.speed, text: 'LV ${hud.level}'),
                  ],
                ),
                const SizedBox(height: 10),
                if (hud.combo > 1) _ComboBanner(hud: hud),
                const Spacer(),
                _PowerUpRow(progress: hud.powerUpProgress),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: _Speedometer(kmh: hud.speedKmh),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PauseButton extends StatelessWidget {
  const _PauseButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black45,
      shape: const CircleBorder(side: BorderSide(color: Colors.white24)),
      child: IconButton(
        onPressed: onPressed,
        icon: const Icon(Icons.pause_rounded, color: Colors.white),
        tooltip: 'Pause',
      ),
    );
  }
}

class _ScoreBlock extends StatelessWidget {
  const _ScoreBlock({required this.hud});

  final HudModel hud;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '${hud.score}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 38,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
            shadows: [Shadow(color: Colors.black87, blurRadius: 10, offset: Offset(0, 3))],
          ),
        ),
        if (hud.bestScore > 0)
          Text('BEST ${hud.bestScore}',
              style: UiTheme.label.copyWith(
                  fontSize: 11,
                  color: hud.score > hud.bestScore ? UiTheme.accent : Colors.white60)),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 6),
          Text(text,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
        ],
      ),
    );
  }
}

class _ComboBanner extends StatelessWidget {
  const _ComboBanner({required this.hud});

  final HudModel hud;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'COMBO x${hud.combo}',
          style: TextStyle(
            color: UiTheme.accent,
            fontSize: 22 + (hud.combo.clamp(0, 8)) * 1.2,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            shadows: const [Shadow(color: Colors.black87, blurRadius: 8, offset: Offset(0, 2))],
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 140,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: hud.comboProgress,
              minHeight: 5,
              backgroundColor: Colors.black38,
              color: UiTheme.accent,
            ),
          ),
        ),
      ],
    );
  }
}

class _PowerUpRow extends StatelessWidget {
  const _PowerUpRow({required this.progress});

  final Map<PowerUpType, double> progress;

  @override
  Widget build(BuildContext context) {
    if (progress.isEmpty) return const SizedBox(height: 44);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final entry in progress.entries)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Container(
              width: 92,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: entry.key.color.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: entry.key.color),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(entry.key.icon, color: entry.key.color, size: 16),
                      const SizedBox(width: 4),
                      Text(entry.key.label,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: entry.value,
                      minHeight: 4,
                      backgroundColor: Colors.black38,
                      color: entry.key.color,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _Speedometer extends StatelessWidget {
  const _Speedometer({required this.kmh});

  final int kmh;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('$kmh',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  height: 1)),
          const SizedBox(width: 4),
          const Padding(
            padding: EdgeInsets.only(bottom: 3),
            child: Text('km/h', style: TextStyle(color: Colors.white70, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
