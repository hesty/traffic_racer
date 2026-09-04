import 'car_catalog.dart';
import 'wallet.dart';

/// Which cars the player owns and which one is on the road.
///
/// [unlockedIds] only ever holds cars bought with coins. Pass-only cars are
/// not owned but rented: whether they can be driven is decided by the live
/// entitlement, passed in as `passActive`.
class Garage {
  Garage({required Set<String> unlockedIds, required this.selectedId})
      : unlockedIds = {CarCatalog.defaultId, ...unlockedIds};

  Garage.initial() : this(unlockedIds: const {}, selectedId: CarCatalog.defaultId);

  final Set<String> unlockedIds;
  String selectedId;

  CarSkin get selectedSkin => CarCatalog.byId(selectedId);

  bool isUnlocked(String id) => unlockedIds.contains(id);

  /// Whether [id] can be put on the road right now.
  bool canDrive(String id, {required bool passActive}) {
    final skin = CarCatalog.byId(id);
    if (skin.id != id) return false;
    return skin.premium ? passActive : isUnlocked(id);
  }

  /// Buys and selects [id], paying from [wallet]. Returns the wallet after the
  /// purchase, or null when the car is unknown, pass-only, already owned or
  /// unaffordable.
  Wallet? buy(String id, Wallet wallet) {
    if (isUnlocked(id)) return null;
    final skin = CarCatalog.byId(id);
    if (skin.id != id || skin.premium) return null;
    final after = wallet.spend(skin.price);
    if (after == null) return null;
    unlockedIds.add(id);
    selectedId = id;
    return after;
  }

  /// Selects a drivable car. Returns false when it is locked.
  bool select(String id, {required bool passActive}) {
    if (!canDrive(id, passActive: passActive)) return false;
    selectedId = id;
    return true;
  }

  /// Falls back to the default car when the selected one is pass-only and the
  /// pass has lapsed. Returns true when the selection changed.
  bool dropUndrivable({required bool passActive}) {
    if (canDrive(selectedId, passActive: passActive)) return false;
    selectedId = CarCatalog.defaultId;
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
    // A pass-only car may have been selected in an earlier session. The
    // entitlement is not known this early, so keep it and let
    // [dropUndrivable] settle it once the store has answered.
    if (!garage.canDrive(garage.selectedId, passActive: true)) {
      garage.selectedId = CarCatalog.defaultId;
    }
    return garage;
  }
}
