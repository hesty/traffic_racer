import 'package:flutter/material.dart';

import '../progression/car_catalog.dart';
import 'car_preview.dart';
import 'ui_theme.dart';

/// The same vehicle as on the road, displayed on a perspective pit-lane floor.
class CarShowcase extends StatelessWidget {
  const CarShowcase({
    super.key,
    required this.skin,
    this.caption = 'Ready for the open road',
    this.compact = false,
  });

  final CarSkin skin;
  final String caption;
  final bool compact;

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: '${skin.label} ${skin.kind.name}. $caption',
    child: ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: ColoredBox(
        color: UiTheme.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(skin.label, style: UiTheme.title(24)),
                        const SizedBox(height: 3),
                        Text(
                          skin.kind.name[0].toUpperCase() +
                              skin.kind.name.substring(1),
                          style: UiTheme.label,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    skin.premium
                        ? Icons.workspace_premium_outlined
                        : Icons.sports_motorsports_outlined,
                    color: skin.premium ? UiTheme.pass : UiTheme.muted,
                    size: 24,
                  ),
                ],
              ),
            ),
            SizedBox(
              height: compact ? 108 : 150,
              width: double.infinity,
              child: CustomPaint(
                painter: const _PitLanePainter(),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 14),
                  child: CarPreview(skin: skin),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: UiTheme.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      caption,
                      style: UiTheme.label.copyWith(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _PitLanePainter extends CustomPainter {
  const _PitLanePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final horizon = size.height * 0.34;
    final line = Paint()
      ..color = const Color(0xFF354A50)
      ..strokeWidth = 1;
    for (var i = -3; i <= 3; i++) {
      canvas.drawLine(
        Offset(size.width / 2 + i * 24, horizon),
        Offset(size.width / 2 + i * 110, size.height),
        line,
      );
    }
    for (final fraction in [0.42, 0.58, 0.82, 1.0]) {
      canvas.drawLine(
        Offset(0, size.height * fraction),
        Offset(size.width, size.height * fraction),
        line,
      );
    }
    final bay = Path()
      ..moveTo(size.width * 0.34, size.height * 0.46)
      ..lineTo(size.width * 0.23, size.height * 0.9)
      ..lineTo(size.width * 0.77, size.height * 0.9)
      ..lineTo(size.width * 0.66, size.height * 0.46);
    canvas.drawPath(
      bay,
      Paint()
        ..color = UiTheme.accent.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height * 0.81),
        width: size.width * 0.38,
        height: 18,
      ),
      Paint()
        ..color = const Color(0x66070F13)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
  }

  @override
  bool shouldRepaint(_PitLanePainter oldDelegate) => false;
}
