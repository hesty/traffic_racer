import 'package:flutter/material.dart';

import '../entities/traffic_vehicle.dart';
import '../progression/car_catalog.dart';
import '../world/vehicle_painter.dart';

/// Paints a car exactly as it appears on the road, so a tile is a true preview
/// rather than a generic icon. Shared by the garage and the paywall.
class CarPreview extends StatelessWidget {
  const CarPreview({super.key, required this.skin});

  final CarSkin skin;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.infinite, painter: _CarPreviewPainter(skin));
}

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
