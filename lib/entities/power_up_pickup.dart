import '../game/power_up_manager.dart';

/// A collectible floating above a lane.
class PowerUpPickup {
  PowerUpPickup({required this.type, required this.lane, required this.z});

  final PowerUpType type;
  final int lane;
  double z;
  double age = 0;
}
