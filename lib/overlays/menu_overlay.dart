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
        child: FillOrScroll(
          child: _MenuBody(game: game, tiltSupported: _tiltSupported),
        ),
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
      children: [
        const Spacer(),
        Text(
          'TURBO TRAFFIC RUSH',
          textAlign: TextAlign.center,
          style: UiTheme.title(30),
        ),
        const SizedBox(height: 14),
        ListenableBuilder(
          listenable: progression.garage,
          builder: (_, _) => CarShowcase(skin: progression.garage.selectedSkin),
        ),
        const SizedBox(height: 10),
        ValueListenableBuilder<int>(
          valueListenable: game.highScores.bestScore,
          builder: (_, best, _) => Text(
            best > 0 ? 'BEST  $best' : 'SWIPE TO CHANGE LANE',
            style: UiTheme.label.copyWith(fontSize: 14, color: Colors.white),
          ),
        ),
        const SizedBox(height: 10),
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
        const Spacer(),
        ListenableBuilder(
          listenable: progression.missions,
          builder: (_, _) =>
              _MissionsPanel(missions: progression.missions.missions),
        ),
        const Spacer(flex: 2),
        SizedBox(
          width: double.infinity,
          child: PrimaryButton(
            label: 'START',
            icon: Icons.play_arrow_rounded,
            onPressed: game.startRun,
          ),
        ),
        const SizedBox(height: 10),
        GhostButton(
          label: 'GARAGE',
          icon: Icons.garage_rounded,
          onPressed: game.openGarage,
        ),
        const SizedBox(height: 10),
        ListenableBuilder(
          listenable: progression.purchases,
          builder: (_, _) => progression.purchases.isActive
              ? const InfoChip(
                  icon: Icons.workspace_premium_rounded,
                  text: 'TURBO PASS ACTIVE',
                  color: UiTheme.pass,
                  fontSize: 13,
                )
              : PassBanner(onTap: game.openPaywall),
        ),
        const SizedBox(height: 16),
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
            if (tiltSupported) ...[
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
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 6,
      children: [
        InfoChip(
          icon: Icons.monetization_on_rounded,
          text: '$coins',
          color: UiTheme.coin,
          fontSize: 14,
        ),
        if (streak.count > 0)
          InfoChip(
            icon: Icons.local_fire_department_rounded,
            text: streak.count == 1 ? '1 DAY' : '${streak.count} DAYS',
            color: UiTheme.accentDark,
            fontSize: 14,
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
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: UiTheme.panelDecoration(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flag_rounded, size: 16, color: Colors.white70),
              const SizedBox(width: 6),
              Flexible(child: Text('Daily missions', style: UiTheme.label)),
              const Spacer(),
              Text(
                '${missions.where((m) => m.completed).length}/${missions.length}',
                style: UiTheme.label.copyWith(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final m in missions) ...[
            _MissionRow(mission: m),
            if (m != missions.last) const SizedBox(height: 8),
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
                        fontSize: 14,
                        decoration: done ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                  Text(
                    done ? 'DONE' : mission.progressLabel,
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
                  color: done ? UiTheme.accent : UiTheme.coin,
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
          icon: Icon(
            on ? onIcon : offIcon,
            color: on ? UiTheme.accent : Colors.white54,
          ),
        ),
      ),
    );
  }
}
