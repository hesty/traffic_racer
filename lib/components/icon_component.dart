import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class IconComponent extends PositionComponent {
  final IconData icon;
  final Color color;

  IconComponent({
    required this.icon,
    required Vector2 size,
    required Vector2 position,
    this.color = Colors.white,
  }) : super(size: size, position: position);

  @override
  void render(Canvas canvas) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: size.y,
          color: color,
          fontFamily: icon.fontFamily,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(size.x / 2 - textPainter.width / 2, size.y / 2 - textPainter.height / 2),
    );
  }
}
