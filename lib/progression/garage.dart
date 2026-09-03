import 'car_catalog.dart';
import 'wallet.dart';

/// Which cars the player owns and which one is on the road.
class Garage {
  Garage({required Set<String> unlockedIds, required this.selectedId})
      : unlockedIds = {CarCatalog.defaultId, ...unlockedIds};

  Garage.initial() : this(unlockedIds: const {}, selectedId: CarCatalog.defaultId);

  final Set<String> unlockedIds;
  String selectedId;

  CarSkin get selectedSkin => CarCatalog.byId(selectedId);

  bool isUnlocked(String id) => unlockedIds.contains(id);

  /// Buys and selects [id], paying from [wallet]. Returns the wallet after the
  /// purchase, or null when the car is unknown, already owned or unaffordable.
  Wallet? buy(String id, Wallet wallet) {
    if (isUnlocked(id)) return null;
    final skin = CarCatalog.byId(id);
    if (skin.id != id) return null;
    final after = wallet.spend(skin.price);
    if (after == null) return null;
    unlockedIds.add(id);
    selectedId = id;
    return after;
  }

  /// Selects an owned car. Returns false when the car is locked.
  bool select(String id) {
    if (!isUnlocked(id)) return false;
    selectedId = id;
    return true;
  }

  Map<String, Object?> toJson() => {
        'unlocked': unlockedIds.toList(),
        'selected': selectedId,
      };

  factory Garage.fromJson(Map<String, Object?> json) {
    final unlocked = (json['unlocked'] as List?)?.cast<String>() ?? const [];
    final garage = Garage(
      unlockedIds: unlocked.toSet(),
      selectedId: json['selected'] as String? ?? CarCatalog.defaultId,
    );
    if (!garage.isUnlocked(garage.selectedId)) {
      garage.selectedId = CarCatalog.defaultId;
    }
    return garage;
  }
}
