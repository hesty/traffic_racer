import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../game/traffic_racer_game.dart';
import 'ui_theme.dart';

/// Minimal title screen: name, best score, start, three small toggles.
class MenuOverlay extends StatelessWidget {
  const MenuOverlay({super.key, required this.game});

  final TrafficRacerGame game;

  bool get _tiltSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  Widget build(BuildContext context) {
    final settings = game.settings;
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x9905071A), Color(0x3305071A), Color(0xDD05071A)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              ShaderMask(
                shaderCallback: (b) => const LinearGradient(
                  colors: [UiTheme.accent, UiTheme.accentDark],
                ).createShader(b),
                child: Text('TURBO\nTRAFFIC RUSH',
                    textAlign: TextAlign.center, style: UiTheme.title(46)),
              ),
              const SizedBox(height: 14),
              ValueListenableBuilder<int>(
                valueListenable: game.highScores.bestScore,
                builder: (_, best, _) => Text(
                  best > 0 ? 'BEST  $best' : 'SWIPE TO CHANGE LANE',
                  style: UiTheme.label.copyWith(fontSize: 14, color: Colors.white),
                ),
              ),
              const Spacer(flex: 3),
              PrimaryButton(
                label: 'START',
                icon: Icons.play_arrow_rounded,
                onPressed: game.startRun,
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Toggle(
                    listenable: settings.soundEnabled,
                    onIcon: Icons.volume_up_rounded,
                    offIcon: Icons.volume_off_rounded,
                    onTap: settings.toggleSound,
                  ),
                  const SizedBox(width: 14),
                  _Toggle(
                    listenable: settings.musicEnabled,
                    onIcon: Icons.music_note_rounded,
                    offIcon: Icons.music_off_rounded,
                    onTap: settings.toggleMusic,
                  ),
                  if (_tiltSupported) ...[
                    const SizedBox(width: 14),
                    _Toggle(
                      listenable: settings.tiltEnabled,
                      onIcon: Icons.screen_rotation_alt_rounded,
                      offIcon: Icons.screen_rotation_alt_rounded,
                      onTap: settings.toggleTilt,
                    ),
                  ],
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

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.listenable,
    required this.onIcon,
    required this.offIcon,
    required this.onTap,
  });

  final ValueListenable<bool> listenable;
  final IconData onIcon;
  final IconData offIcon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: listenable,
      builder: (_, on, _) => Material(
        color: on ? UiTheme.accent.withValues(alpha: 0.2) : Colors.black38,
        shape: CircleBorder(
          side: BorderSide(color: on ? UiTheme.accent : Colors.white24),
        ),
        child: IconButton(
          onPressed: onTap,
          iconSize: 24,
          icon: Icon(on ? onIcon : offIcon,
              color: on ? UiTheme.accent : Colors.white54),
        ),
      ),
    );
  }
}
