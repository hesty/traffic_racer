import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../progression/car_catalog.dart';

/// Shared styling for the Flutter overlays drawn above the game.
class UiTheme {
  UiTheme._();

  static const background = Color(0xFF101F25);
  static const surface = Color(0xFF1B3038);
  static const ink = Color(0xFFF4F3EA);
  static const muted = Color(0xFFA7BBC2);
  static const accent = Color(0xFFFF9861);
  static const accentDark = Color(0xFFFFAD80);
  static const coin = Color(0xFFF3D179);
  static const pass = Color(0xFFB1D8EA);
  static const passDark = Color(0xFF7CB5CF);
  static const panel = Color(0xF21B3038);
  static const panelBorder = Color(0xFF334850);

  static TextStyle title(double size) => TextStyle(
    fontSize: size,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.8,
    height: 1.08,
    color: ink,
  );

  static const label = TextStyle(
    color: muted,
    fontSize: 13,
    height: 1.35,
    fontWeight: FontWeight.w500,
  );

  static const value = TextStyle(
    color: ink,
    fontSize: 22,
    fontWeight: FontWeight.w800,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static BoxDecoration panelDecoration({double radius = 20}) => BoxDecoration(
    color: panel,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: panelBorder),
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
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 560,
              minHeight: math.max(0, constraints.maxHeight - padding.vertical),
            ),
            child: IntrinsicHeight(child: child),
          ),
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
        color: UiTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: fontSize + 3),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
                fontSize: fontSize,
              ),
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
    this.foreground = UiTheme.background,
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
          letterSpacing: -0.2,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: foreground,
        minimumSize: const Size(0, 56),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
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
          letterSpacing: 0,
        ),
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 52),
        backgroundColor: UiTheme.surface,
        foregroundColor: color ?? UiTheme.ink,
        side: BorderSide(
          color: color?.withValues(alpha: 0.6) ?? UiTheme.panelBorder,
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
      color: UiTheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: UiTheme.panelBorder),
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

/// Shared opaque backdrop keeps menu text legible over every road environment.
class MenuSurface extends StatelessWidget {
  const MenuSurface({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: UiTheme.background,
    child: SizedBox.expand(child: SafeArea(child: child)),
  );
}

class RaceStat extends StatelessWidget {
  const RaceStat({super.key, required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(value, style: UiTheme.value),
      ),
      const SizedBox(height: 4),
      Text(label, style: UiTheme.label, textAlign: TextAlign.center),
    ],
  );
}
