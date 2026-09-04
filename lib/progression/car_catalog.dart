import 'dart:ui';

import '../entities/traffic_vehicle.dart';

/// A purchasable look for the player's car: a body shape plus a paint colour.
class CarSkin {
  const CarSkin({
    required this.id,
    required this.kind,
    required this.color,
    required this.label,
    required this.price,
    this.premium = false,
  });

  final String id;
  final VehicleKind kind;
  final Color color;
  final String label;

  /// Coin price. Always 0 for a [premium] car, which coins cannot buy at all.
  final int price;

  /// Locked behind the Turbo Pass entitlement rather than behind coins.
  final bool premium;

  String get name => '$label ${kind.name}'.toUpperCase();
}

/// Every car the garage can show. The first entry is the free default and
/// matches the original hardcoded player car; the [premium] entries only ride
/// while the Turbo Pass is active.
class CarCatalog {
  CarCatalog._();

  static const String defaultId = 'sedan_amber';

  static const List<CarSkin> all = [
    CarSkin(id: defaultId, kind: VehicleKind.sedan, color: Color(0xFFF2D21B), label: 'Amber', price: 0),
    CarSkin(id: 'sedan_blue', kind: VehicleKind.sedan, color: Color(0xFF1E88E5), label: 'Cobalt', price: 150),
    CarSkin(id: 'hatchback_red', kind: VehicleKind.hatchback, color: Color(0xFFE53935), label: 'Cherry', price: 150),
    CarSkin(id: 'hatchback_green', kind: VehicleKind.hatchback, color: Color(0xFF43A047), label: 'Lime', price: 250),
    CarSkin(id: 'suv_white', kind: VehicleKind.suv, color: Color(0xFFECEFF1), label: 'Pearl', price: 350),
    CarSkin(id: 'van_orange', kind: VehicleKind.van, color: Color(0xFFF4511E), label: 'Ember', price: 350),
    CarSkin(id: 'suv_purple', kind: VehicleKind.suv, color: Color(0xFF8E24AA), label: 'Violet', price: 500),
    CarSkin(id: 'hatchback_cyan', kind: VehicleKind.hatchback, color: Color(0xFF00ACC1), label: 'Cyan', price: 650),
    CarSkin(id: 'sedan_black', kind: VehicleKind.sedan, color: Color(0xFF37474F), label: 'Shadow', price: 800),
    CarSkin(id: 'van_pink', kind: VehicleKind.van, color: Color(0xFFEC407A), label: 'Neon', price: 1000),
    // Turbo Pass exclusives; coins never unlock these.
    CarSkin(id: 'pass_bullion', kind: VehicleKind.sedan, color: Color(0xFFFFC400), label: 'Bullion', price: 0, premium: true),
    CarSkin(id: 'pass_chrome', kind: VehicleKind.suv, color: Color(0xFFB0BEC5), label: 'Chrome', price: 0, premium: true),
    CarSkin(id: 'pass_carbon', kind: VehicleKind.van, color: Color(0xFF263238), label: 'Carbon', price: 0, premium: true),
    CarSkin(id: 'pass_aurora', kind: VehicleKind.hatchback, color: Color(0xFF00E5A0), label: 'Aurora', price: 0, premium: true),
  ];

  /// The pass-only cars, in catalogue order. The paywall previews these.
  static List<CarSkin> get premium =>
      [for (final skin in all) if (skin.premium) skin];

  static CarSkin byId(String id) =>
      all.firstWhere((s) => s.id == id, orElse: () => all.first);
}
