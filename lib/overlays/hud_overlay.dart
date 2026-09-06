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
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: UiTheme.panelDecoration(radius: 18),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _PauseButton(onPressed: game.pauseRun),
                      const SizedBox(width: 12),
                      Expanded(child: _ScoreBlock(hud: hud)),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Level ${hud.level}',
                            style: UiTheme.label.copyWith(
                              color: UiTheme.ink,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.monetization_on_outlined,
                                color: UiTheme.coin,
                                size: 15,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '+${hud.coinsThisRun}',
                                style: UiTheme.label.copyWith(
                                  color: UiTheme.coin,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (game.isTestDrive)
                  const InfoChip(
                    icon: Icons.sports_motorsports_rounded,
                    text: 'Free test drive',
                    color: UiTheme.pass,
                    fontSize: 12,
                  ),
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
      color: UiTheme.background,
      borderRadius: BorderRadius.circular(12),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '${hud.score}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              height: 1.1,
              fontFeatures: [FontFeature.tabularFigures()],
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
              shadows: [
                Shadow(
                  color: Colors.black87,
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        if (hud.bestScore > 0)
          Text(
            'Best ${hud.bestScore}',
            style: UiTheme.label.copyWith(
              fontSize: 11,
              color: hud.score > hud.bestScore ? UiTheme.accent : UiTheme.muted,
            ),
          ),
      ],
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
          '×${hud.combo} combo',
          style: TextStyle(
            color: UiTheme.accent,
            fontSize: 22 + (hud.combo.clamp(0, 8)) * 1.2,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            shadows: const [
              Shadow(
                color: Colors.black87,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
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
    return Wrap(
      alignment: WrapAlignment.center,
      runSpacing: 8,
      children: [
        for (final entry in progress.entries)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Container(
              width: 128,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: UiTheme.panel,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: entry.key.color.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(entry.key.icon, color: entry.key.color, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        entry.key.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
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
      width: 124,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: UiTheme.panelDecoration(radius: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '$kmh',
                    style: UiTheme.value.copyWith(
                      fontSize: 34,
                      height: 1,
                      letterSpacing: -1,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text('km/h', style: UiTheme.label.copyWith(fontSize: 11)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(
              12,
              (i) => Expanded(
                child: Container(
                  height: 4,
                  margin: const EdgeInsets.only(right: 2),
                  color: i < (kmh / 300 * 12).clamp(0, 12)
                      ? (i >= 10 ? UiTheme.accent : UiTheme.pass)
                      : UiTheme.panelBorder,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
