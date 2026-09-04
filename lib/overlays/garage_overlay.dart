import 'package:flutter/material.dart';

import '../game/traffic_racer_game.dart';
import '../progression/car_catalog.dart';
import 'car_preview.dart';
import 'ui_theme.dart';

/// Buy and pick the player's car. Shown over the menu or the result screen.
///
/// Coin cars are bought outright; pass-only cars are never bought here at all,
/// they send the player to the paywall and unlock themselves once the Turbo
/// Pass is active.
class GarageOverlay extends StatelessWidget {
  const GarageOverlay({super.key, required this.game});

  final TrafficRacerGame game;

  @override
  Widget build(BuildContext context) {
    final garage = game.progression.garage;
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xEE05071A),
      child: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([garage, game.progression.purchases]),
          builder: (context, _) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: game.closeGarage,
                      iconSize: 28,
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                      ),
                      tooltip: 'Back',
                    ),
                    const SizedBox(width: 4),
                    Text('GARAGE', style: UiTheme.title(26)),
                    const Spacer(),
                    InfoChip(
                      icon: Icons.monetization_on_rounded,
                      text: '${garage.coins}',
                      color: UiTheme.coin,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.82,
                  ),
                  itemCount: CarCatalog.all.length,
                  itemBuilder: (context, i) {
                    final skin = CarCatalog.all[i];
                    final drivable = garage.canDrive(skin.id);
                    return _CarTile(
                      skin: skin,
                      drivable: drivable,
                      selected: garage.garage.selectedId == skin.id,
                      affordable: garage.coins >= skin.price,
                      onTap: () {
                        if (drivable) {
                          garage.select(skin.id);
                        } else if (skin.premium) {
                          game.openPaywall();
                        } else {
                          game.buyCar(skin.id);
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CarTile extends StatelessWidget {
  const _CarTile({
    required this.skin,
    required this.drivable,
    required this.selected,
    required this.affordable,
    required this.onTap,
  });

  final CarSkin skin;
  final bool drivable;
  final bool selected;
  final bool affordable;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final border = selected
        ? UiTheme.accent
        : drivable
        ? Colors.white38
        : skin.premium
        ? UiTheme.pass.withValues(alpha: 0.5)
        : Colors.white12;
    return Material(
      color: selected ? UiTheme.accent.withValues(alpha: 0.12) : UiTheme.panel,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border, width: selected ? 2 : 1),
          ),
          child: Column(
            children: [
              Expanded(
                child: Opacity(
                  opacity: drivable ? 1 : 0.55,
                  child: CarPreview(skin: skin),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                skin.name,
                textAlign: TextAlign.center,
                style: UiTheme.label.copyWith(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 6),
              _StateRow(
                skin: skin,
                drivable: drivable,
                selected: selected,
                affordable: affordable,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StateRow extends StatelessWidget {
  const _StateRow({
    required this.skin,
    required this.drivable,
    required this.selected,
    required this.affordable,
  });

  final CarSkin skin;
  final bool drivable;
  final bool selected;
  final bool affordable;

  @override
  Widget build(BuildContext context) {
    if (selected) {
      return const _Tag(
        icon: Icons.check_rounded,
        text: 'SELECTED',
        color: UiTheme.accent,
      );
    }
    if (drivable) {
      return const _Tag(
        icon: Icons.touch_app_rounded,
        text: 'TAP TO USE',
        color: Colors.white70,
      );
    }
    if (skin.premium) {
      return const _Tag(
        icon: Icons.workspace_premium_rounded,
        text: 'PASS',
        color: UiTheme.pass,
      );
    }
    return _Tag(
      icon: affordable ? Icons.monetization_on_rounded : Icons.lock_rounded,
      text: '${skin.price}',
      color: affordable ? UiTheme.coin : Colors.white38,
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.icon, required this.text, required this.color});

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
