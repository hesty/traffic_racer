import 'package:flutter/material.dart';
import '../progression/car_catalog.dart';
import 'car_preview.dart';
import 'ui_theme.dart';

/// A garage podium, with the actual procedural vehicle used by the game.
class CarShowcase extends StatelessWidget {
  const CarShowcase({
    super.key,
    required this.skin,
    this.caption = 'Ready to race',
    this.compact = false,
  });
  final CarSkin skin;
  final String caption;
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF243C55), Color(0xFF101D30)],
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white12),
    ),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                skin.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Icon(
              skin.premium
                  ? Icons.workspace_premium_rounded
                  : Icons.sports_motorsports_rounded,
              color: skin.premium ? UiTheme.pass : UiTheme.accent,
              size: 22,
            ),
          ],
        ),
        SizedBox(
          height: compact ? 76 : 116,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                bottom: 2,
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.diagonal3Values(1, 0.22, 1),
                  child: Container(
                    width: 220,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: UiTheme.pass.withValues(alpha: 0.4),
                        width: 3,
                      ),
                      color: Colors.white.withValues(alpha: 0.04),
                    ),
                  ),
                ),
              ),
              Positioned.fill(child: CarPreview(skin: skin)),
            ],
          ),
        ),
        Text(
          caption,
          textAlign: TextAlign.center,
          style: UiTheme.label.copyWith(fontSize: 12),
        ),
      ],
    ),
  );
}
