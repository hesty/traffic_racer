import 'package:flutter/material.dart';

/// Shared styling for the Flutter overlays drawn above the game.
class UiTheme {
  UiTheme._();

  static const accent = Color(0xFFF2D21B);
  static const accentDark = Color(0xFFFF7A29);
  static const panel = Color(0xCC0B1024);
  static const panelBorder = Color(0x33FFFFFF);

  static TextStyle title(double size) => TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w900,
        letterSpacing: 2,
        height: 1.05,
        color: Colors.white,
        shadows: const [
          Shadow(color: Color(0xAA000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      );

  static const label = TextStyle(
    color: Colors.white70,
    fontSize: 13,
    letterSpacing: 1.2,
    fontWeight: FontWeight.w600,
  );

  static const value = TextStyle(
    color: Colors.white,
    fontSize: 22,
    fontWeight: FontWeight.w800,
  );

  static BoxDecoration panelDecoration({double radius = 20}) => BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: panelBorder),
        boxShadow: const [
          BoxShadow(color: Color(0x66000000), blurRadius: 24, offset: Offset(0, 10)),
        ],
      );
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.color = UiTheme.accent,
    this.foreground = Colors.black,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 26),
      label: Text(label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: foreground,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        elevation: 10,
        shadowColor: color.withValues(alpha: 0.6),
      ),
    );
  }
}

class GhostButton extends StatelessWidget {
  const GhostButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 22),
      label: Text(label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 1)),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white38),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      ),
    );
  }
}
