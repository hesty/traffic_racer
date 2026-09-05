import 'package:flutter/material.dart';

import '../progression/car_catalog.dart';

/// Shared styling for the Flutter overlays drawn above the game.
class UiTheme {
  UiTheme._();

  static const accent = Color(0xFFFF844B);
  static const accentDark = Color(0xFFE85C35);
  static const coin = Color(0xFFFFC93C);

  /// Turbo Pass violet, deliberately away from the amber the coin economy
  /// owns so a paid unlock never reads as something coins could buy.
  static const pass = Color(0xFFC5D7F0);
  static const passDark = Color(0xFF809FC9);
  static const panel = Color(0xED101D30);
  static const panelBorder = Color(0x33FFFFFF);

  static TextStyle title(double size) => TextStyle(
    fontSize: size,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.8,
    fontStyle: FontStyle.italic,
    height: 1.05,
    color: Colors.white,
    shadows: const [
      Shadow(color: Color(0xAA000000), blurRadius: 12, offset: Offset(0, 4)),
    ],
  );

  static const label = TextStyle(
    color: Colors.white70,
    fontSize: 13,
    letterSpacing: 0.2,
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
      BoxShadow(
        color: Color(0x66000000),
        blurRadius: 24,
        offset: Offset(0, 10),
      ),
    ],
  );
}

/// Fills the available height so `Spacer`s inside [child] spread the content
/// out, but falls back to scrolling when a short screen cannot fit it all.
class FillOrScroll extends StatelessWidget {
  const FillOrScroll({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: padding,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: constraints.maxHeight - padding.vertical,
          ),
          child: IntrinsicHeight(child: child),
        ),
      ),
    );
  }
}

/// Small pill with an icon and a short label, used across menu, HUD and
/// result screens.
class InfoChip extends StatelessWidget {
  const InfoChip({
    super.key,
    required this.icon,
    required this.text,
    this.color = Colors.white,
    this.fontSize = 15,
  });

  final IconData icon;
  final String text;
  final Color color;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: fontSize + 3),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: fontSize,
            ),
          ),
        ],
      ),
    );
  }
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

  /// Null disables the button, which the paywall uses while a purchase is in
  /// flight or before the store has answered.
  final VoidCallback? onPressed;
  final Color color;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 26),
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.4,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: foreground,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 2,
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
    this.color,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  /// Tints the label and the outline; null keeps the plain white button.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 22),
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: color ?? Colors.white,
        side: BorderSide(
          color: color?.withValues(alpha: 0.6) ?? Colors.white38,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

/// Slim call to action for the Turbo Pass, used where a third full-width
/// button would crowd the screen.
class PassBanner extends StatelessWidget {
  const PassBanner({super.key, required this.onTap, this.message});

  final String? message;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: UiTheme.pass.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: UiTheme.pass.withValues(alpha: 0.55)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.workspace_premium_rounded,
                size: 18,
                color: UiTheme.pass,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  message ??
                      'Turbo Pass: ${CarCatalog.premium.length} cars + 2× run coins',
                  style: UiTheme.label.copyWith(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: UiTheme.pass,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
