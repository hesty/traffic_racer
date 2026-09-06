import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../game/traffic_racer_game.dart';
import '../progression/mission.dart';
import '../progression/streak.dart';
import 'ui_theme.dart';
import 'car_showcase.dart';

/// Title screen: name, best score, coins and streak, today's missions,
/// start/garage buttons and three small toggles.
class MenuOverlay extends StatelessWidget {
  const MenuOverlay({super.key, required this.game});

  final TrafficRacerGame game;

  bool get _tiltSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  Widget build(BuildContext context) {
    return MenuSurface(
      child: FillOrScroll(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: _MenuBody(game: game, tiltSupported: _tiltSupported),
      ),
    );
  }
}

class _MenuBody extends StatelessWidget {
  const _MenuBody({required this.game, required this.tiltSupported});

  final TrafficRacerGame game;
  final bool tiltSupported;

  @override
  Widget build(BuildContext context) {
    final settings = game.settings;
    final progression = game.progression;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(
              Icons.sports_motorsports_rounded,
              color: UiTheme.accent,
              size: 28,
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Turbo Traffic Rush',
                style: TextStyle(
                  color: UiTheme.ink,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            ListenableBuilder(
              listenable: Listenable.merge([
                progression.garage,
                progression.streak.streak,
              ]),
              builder: (_, _) => _WalletRow(
                coins: progression.garage.coins,
                streak: progression.streak.streak.value,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                'Own the\nopen road.',
                style: UiTheme.title(38).copyWith(
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.5,
                ),
              ),
            ),
            const SizedBox(width: 12),
            ValueListenableBuilder<int>(
              valueListenable: game.highScores.bestScore,
              builder: (_, best, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Icon(
                    Icons.emoji_events_outlined,
                    color: UiTheme.coin,
                    size: 20,
                  ),
                  const SizedBox(height: 6),
                  Text('$best', style: UiTheme.value),
                  const Text('Personal best', style: UiTheme.label),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        ListenableBuilder(
          listenable: progression.garage,
          builder: (_, _) => CarShowcase(skin: progression.garage.selectedSkin),
        ),
        const SizedBox(height: 16),
        PrimaryButton(
          label: 'Start racing',
          icon: Icons.play_arrow_rounded,
          onPressed: game.startRun,
        ),
        const SizedBox(height: 10),
        ValueListenableBuilder<bool>(
          valueListenable: settings.tiltEnabled,
          builder: (_, tilt, _) => Text(
            tilt && tiltSupported
                ? 'Tilt your phone to steer'
                : 'Swipe left or right to change lanes',
            textAlign: TextAlign.center,
            style: UiTheme.label.copyWith(fontSize: 12),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: GhostButton(
                label: 'Garage',
                icon: Icons.garage_outlined,
                onPressed: game.openGarage,
              ),
            ),
            const SizedBox(width: 12),
            _Toggle(
              label: 'Sound',
              listenable: settings.soundEnabled,
              onIcon: Icons.volume_up_rounded,
              offIcon: Icons.volume_off_rounded,
              onTap: settings.toggleSound,
            ),
            const SizedBox(width: 6),
            _Toggle(
              label: 'Music',
              listenable: settings.musicEnabled,
              onIcon: Icons.music_note_rounded,
              offIcon: Icons.music_off_rounded,
              onTap: settings.toggleMusic,
            ),
            if (tiltSupported) ...[
              const SizedBox(width: 6),
              _Toggle(
                label: 'Tilt steering',
                listenable: settings.tiltEnabled,
                onIcon: Icons.screen_rotation_alt_rounded,
                offIcon: Icons.screen_rotation_alt_rounded,
                onTap: settings.toggleTilt,
              ),
            ],
          ],
        ),
        const SizedBox(height: 24),
        ListenableBuilder(
          listenable: progression.missions,
          builder: (_, _) =>
              _MissionsPanel(missions: progression.missions.missions),
        ),
        const SizedBox(height: 18),
        const Spacer(),
        ListenableBuilder(
          listenable: progression.purchases,
          builder: (_, _) => progression.purchases.isActive
              ? const Center(
                  child: InfoChip(
                    icon: Icons.workspace_premium_rounded,
                    text: 'Turbo Pass active',
                    color: UiTheme.pass,
                    fontSize: 13,
                  ),
                )
              : PassBanner(onTap: game.openPaywall),
        ),
      ],
    );
  }
}

class _WalletRow extends StatelessWidget {
  const _WalletRow({required this.coins, required this.streak});

  final int coins;
  final Streak streak;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 10,
      runSpacing: 6,
      children: [
        InfoChip(
          icon: Icons.monetization_on_rounded,
          text: '$coins',
          color: UiTheme.coin,
          fontSize: 12,
        ),
        if (streak.count > 0)
          InfoChip(
            icon: Icons.local_fire_department_rounded,
            text: '${streak.count}',
            color: UiTheme.accentDark,
            fontSize: 12,
          ),
      ],
    );
  }
}

/// Today's three goals with progress bars.
class _MissionsPanel extends StatelessWidget {
  const _MissionsPanel({required this.missions});

  final List<Mission> missions;

  @override
  Widget build(BuildContext context) {
    if (missions.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: UiTheme.panelDecoration(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flag_outlined, size: 18, color: UiTheme.muted),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Daily missions',
                  style: UiTheme.label.copyWith(
                    color: UiTheme.ink,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${missions.where((m) => m.completed).length}/${missions.length}',
                style: UiTheme.label.copyWith(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (final m in missions) ...[
            _MissionRow(mission: m),
            if (m != missions.last) const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

class _MissionRow extends StatelessWidget {
  const _MissionRow({required this.mission});

  final Mission mission;

  @override
  Widget build(BuildContext context) {
    final done = mission.completed;
    final color = done ? UiTheme.accent : Colors.white;
    return Row(
      children: [
        Icon(
          done ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
          size: 20,
          color: done ? UiTheme.accent : Colors.white38,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      mission.description,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    done ? 'Done' : mission.progressLabel,
                    style: UiTheme.label.copyWith(fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: mission.progressFraction,
                  minHeight: 4,
                  backgroundColor: Colors.black38,
                  color: done ? UiTheme.accent : UiTheme.pass,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '+${mission.coinReward}',
          style: const TextStyle(
            color: UiTheme.coin,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.label,
    required this.listenable,
    required this.onIcon,
    required this.offIcon,
    required this.onTap,
  });

  final String label;
  final ValueListenable<bool> listenable;
  final IconData onIcon;
  final IconData offIcon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: listenable,
      builder: (_, on, _) => Semantics(
        toggled: on,
        label: label,
        child: Material(
          color: UiTheme.surface,
          borderRadius: BorderRadius.circular(14),
          child: IconButton(
            onPressed: onTap,
            tooltip: '$label: ${on ? 'on' : 'off'}',
            constraints: const BoxConstraints(minWidth: 48, minHeight: 52),
            iconSize: 24,
            icon: Icon(
              on ? onIcon : offIcon,
              color: on ? UiTheme.ink : UiTheme.muted,
            ),
          ),
        ),
      ),
    );
  }
}
