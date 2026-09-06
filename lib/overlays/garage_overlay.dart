import 'package:flutter/material.dart';

import '../game/traffic_racer_game.dart';
import '../progression/car_catalog.dart';
import 'car_preview.dart';
import 'car_showcase.dart';
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
    return MenuSurface(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
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
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text('Garage', style: UiTheme.title(26)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InfoChip(
                        icon: Icons.monetization_on_rounded,
                        text: '${garage.coins}',
                        color: UiTheme.coin,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 520 ? 3 : 2;
                      final scale =
                          MediaQuery.textScalerOf(context).scale(14) / 14;
                      return CustomScrollView(
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                            sliver: SliverToBoxAdapter(
                              child: CarShowcase(
                                skin: garage.selectedSkin,
                                compact: true,
                                caption: 'Your current ride',
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                            sliver: SliverToBoxAdapter(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Choose your next ride',
                                      style: UiTheme.label.copyWith(
                                        color: UiTheme.ink,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${CarCatalog.all.where((skin) => garage.canDrive(skin.id)).length}/${CarCatalog.all.length}',
                                    style: UiTheme.label,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                            sliver: SliverGrid(
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: columns,
                                    mainAxisSpacing: 12,
                                    crossAxisSpacing: 12,
                                    mainAxisExtent: 204 + (scale - 1) * 90,
                                  ),
                              delegate: SliverChildBuilderDelegate((
                                context,
                                i,
                              ) {
                                final skin = CarCatalog.all[i];
                                final drivable = garage.canDrive(skin.id);
                                return _CarTile(
                                  skin: skin,
                                  drivable: drivable,
                                  selected: garage.garage.selectedId == skin.id,
                                  affordable: garage.coins >= skin.price,
                                  coins: garage.coins,
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
                              }, childCount: CarCatalog.all.length),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
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
    required this.coins,
    required this.onTap,
  });

  final CarSkin skin;
  final bool drivable;
  final bool selected;
  final bool affordable;
  final int coins;
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
    final enabled = drivable || skin.premium || affordable;
    return Semantics(
      button: true,
      selected: selected,
      label: '${skin.label} ${skin.kind.name}',
      child: Material(
        color: selected
            ? UiTheme.accent.withValues(alpha: 0.12)
            : UiTheme.panel,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border, width: selected ? 2 : 1),
            ),
            child: Column(
              children: [
                Expanded(
                  child: Opacity(opacity: 1, child: CarPreview(skin: skin)),
                ),
                const SizedBox(height: 8),
                Text(
                  skin.label,
                  textAlign: TextAlign.center,
                  style: UiTheme.label.copyWith(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  skin.kind.name,
                  style: UiTheme.label.copyWith(fontSize: 11),
                ),
                const SizedBox(height: 8),
                _StateRow(
                  skin: skin,
                  drivable: drivable,
                  selected: selected,
                  affordable: affordable,
                ),
                if (!enabled) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${skin.price - coins} more coins',
                    textAlign: TextAlign.center,
                    style: UiTheme.label.copyWith(fontSize: 10),
                  ),
                ],
              ],
            ),
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
        text: 'Selected',
        color: UiTheme.accent,
      );
    }
    if (drivable) {
      return const _Tag(
        icon: Icons.touch_app_rounded,
        text: 'Use car',
        color: Colors.white70,
      );
    }
    if (skin.premium) {
      return const _Tag(
        icon: Icons.workspace_premium_rounded,
        text: 'Turbo Pass',
        color: UiTheme.pass,
      );
    }
    return _Tag(
      icon: affordable ? Icons.monetization_on_rounded : Icons.lock_rounded,
      text: '${skin.price}',
      color: affordable ? UiTheme.coin : UiTheme.muted,
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
        Flexible(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
