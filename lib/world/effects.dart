import 'dart:ui';

/// A short-lived text label rising from a point on screen (screen fractions).
class FloatingText {
  FloatingText({
    required this.text,
    required this.color,
    required this.x,
    required this.y,
    this.life = 1.2,
    this.fontSize = 22,
  }) : maxLife = life;

  final String text;
  final Color color;
  final double x;
  double y;
  double life;
  final double maxLife;
  final double fontSize;

  double get alpha => (life / maxLife).clamp(0.0, 1.0);

  void update(double dt) {
    life -= dt;
    y -= dt * 0.08;
  }
}

/// A chunk of debris thrown out by a crash (screen pixels).
class Debris {
  Debris({
    required this.position,
    required this.velocity,
    required this.color,
    required this.size,
    this.life = 1.2,
  });

  Offset position;
  Offset velocity;
  final Color color;
  final double size;
  double life;

  void update(double dt) {
    life -= dt;
    velocity = Offset(velocity.dx * 0.98, velocity.dy + 900 * dt);
    position += velocity * dt;
  }
}
