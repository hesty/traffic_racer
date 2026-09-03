import 'dart:ui';

enum VehicleKind { sedan, hatchback, suv, van, truck, bus }

extension VehicleKindInfo on VehicleKind {
  /// Height / width ratio of the rear silhouette.
  double get aspect => switch (this) {
        VehicleKind.sedan => 0.72,
        VehicleKind.hatchback => 0.8,
        VehicleKind.suv => 0.9,
        VehicleKind.van => 1.05,
        VehicleKind.truck => 1.35,
        VehicleKind.bus => 1.4,
      };

  /// Width relative to a standard car.
  double get widthFactor => switch (this) {
        VehicleKind.sedan => 1.0,
        VehicleKind.hatchback => 0.95,
        VehicleKind.suv => 1.08,
        VehicleKind.van => 1.1,
        VehicleKind.truck => 1.2,
        VehicleKind.bus => 1.22,
      };
}

/// An AI vehicle driving along the track in a fixed lane.
class TrafficVehicle {
  TrafficVehicle({
    required this.kind,
    required this.color,
    required this.lane,
    required this.z,
    required this.speed,
  }) : cruiseSpeed = speed;

  final VehicleKind kind;
  final Color color;
  final int lane;

  /// Track position (world units, wraps around the track length).
  double z;

  /// Current forward speed in world units per second.
  double speed;

  /// Speed the vehicle returns to when the road ahead is clear.
  final double cruiseSpeed;

  /// True once the player has driven past this vehicle.
  bool passed = false;

  /// Last known signed distance from the player (for pass detection).
  double lastRelativeZ = double.nan;

  bool braking = false;
}
