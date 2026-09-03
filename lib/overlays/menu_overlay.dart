import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../game/traffic_racer_game.dart';
import 'ui_theme.dart';

/// Title screen with the best score, controls help and settings.
class MenuOverlay extends StatelessWidget {
  const MenuOverlay({super.key, required this.game});

  final TrafficRacerGame game;

  bool get _tiltSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xCC05071A), Color(0x6605071A), Color(0xEE05071A)],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ShaderMask(
                  shaderCallback: (b) => const LinearGradient(
                    colors: [UiTheme.accent, UiTheme.accentDark],
                  ).createShader(b),
                  child: Text('TURBO\nTRAFFIC RUSH',
                      textAlign: TextAlign.center, style: UiTheme.title(44)),
                ),
                const SizedBox(height: 8),
                Image.asset('assets/images/car.png', height: 110,
                    filterQuality: FilterQuality.medium),
                const SizedBox(height: 8),
                _bestScore(),
                const SizedBox(height: 20),
                _howToPlay(),
                const SizedBox(height: 16),
                _settings(),
                const SizedBox(height: 28),
                PrimaryButton(
                  label: 'START RACE',
                  icon: Icons.play_arrow_rounded,
                  onPressed: game.startRun,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bestScore() {
    return ValueListenableBuilder<int>(
      valueListenable: game.highScores.bestScore,
      builder: (_, best, _) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black38,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: UiTheme.accent.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, color: UiTheme.accent, size: 20),
            const SizedBox(width: 8),
            Text('BEST  $best',
                style: UiTheme.value.copyWith(fontSize: 18, letterSpacing: 1.5)),
          ],
        ),
      ),
    );
  }

  Widget _howToPlay() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: UiTheme.panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('HOW TO PLAY', style: UiTheme.label),
          SizedBox(height: 12),
          _Hint(Icons.swipe, 'Swipe or tap a side to change lane'),
          _Hint(Icons.bolt, 'Squeeze past cars for NEAR MISS combos'),
          _Hint(Icons.shield, 'Grab power-ups: shield, nitro, 2x, slow-mo'),
          _Hint(Icons.speed, 'Every 1500 points the traffic gets faster'),
        ],
      ),
    );
  }

  Widget _settings() {
    final settings = game.settings;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: UiTheme.panelDecoration(),
      child: Column(
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: settings.soundEnabled,
            builder: (_, on, _) => SwitchListTile(
              value: on,
              onChanged: settings.setSound,
              activeThumbColor: UiTheme.accent,
              secondary: Icon(on ? Icons.volume_up : Icons.volume_off,
                  color: Colors.white70),
              title: const Text('Sound', style: TextStyle(color: Colors.white)),
              dense: true,
            ),
          ),
          if (_tiltSupported)
            ValueListenableBuilder<bool>(
              valueListenable: settings.tiltEnabled,
              builder: (_, on, _) => SwitchListTile(
                value: on,
                onChanged: settings.setTilt,
                activeThumbColor: UiTheme.accent,
                secondary: const Icon(Icons.screen_rotation_alt, color: Colors.white70),
                title: const Text('Tilt steering', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Lean the phone to change lanes',
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
                dense: true,
              ),
            ),
        ],
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, color: UiTheme.accent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
                style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.3)),
          ),
        ],
      ),
    );
  }
}
