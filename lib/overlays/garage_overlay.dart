import 'package:flutter/material.dart';

import '../entities/traffic_vehicle.dart';
import '../game/traffic_racer_game.dart';
import '../progression/car_catalog.dart';
import '../world/vehicle_painter.dart';
import 'ui_theme.dart';

/// Buy and pick the player's car. Shown over the menu or the result screen.
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
          listenable: garage,
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
                    return _CarTile(
                      skin: skin,
                      owned: garage.garage.isUnlocked(skin.id),
                      selected: garage.garage.selectedId == skin.id,
                      affordable: garage.coins >= skin.price,
                      onTap: () {
                        if (garage.garage.isUnlocked(skin.id)) {
                          garage.select(skin.id);
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
    required this.owned,
    required this.selected,
    required this.affordable,
    required this.onTap,
  });

  final CarSkin skin;
  final bool owned;
  final bool selected;
  final bool affordable;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final border = selected
        ? UiTheme.accent
        : owned
        ? Colors.white38
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
                  opacity: owned ? 1 : 0.55,
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: _CarPreviewPainter(skin),
                  ),
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
                owned: owned,
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
    required this.owned,
    required this.selected,
    required this.affordable,
  });

  final CarSkin skin;
  final bool owned;
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
    if (owned) {
      return const _Tag(
        icon: Icons.touch_app_rounded,
        text: 'TAP TO USE',
        color: Colors.white70,
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

/// Paints the car exactly as it appears on the road, so the tile is a true
/// preview rather than a generic icon.
class _CarPreviewPainter extends CustomPainter {
  const _CarPreviewPainter(this.skin);

  final CarSkin skin;

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width * 0.58 * skin.kind.widthFactor;
    VehiclePainter.draw(
      canvas,
      bottomCenter: Offset(size.width / 2, size.height * 0.92),
      width: width,
      kind: skin.kind,
      color: skin.color,
      lightsAlpha: 0.4,
      isPlayer: true,
    );
  }

  @override
  bool shouldRepaint(_CarPreviewPainter oldDelegate) =>
      oldDelegate.skin != skin;
}
