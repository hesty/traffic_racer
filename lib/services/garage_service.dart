import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../progression/car_catalog.dart';
import '../progression/garage.dart';
import '../progression/wallet.dart';

/// Coin balance plus owned/selected cars. One notifier because a purchase
/// changes both at once.
class GarageService extends ChangeNotifier {
  static const _key = 'garage_v1';

  Wallet _wallet = const Wallet(0);
  Garage _garage = Garage.initial();
  SharedPreferences? _prefs;

  int get coins => _wallet.balance;
  Garage get garage => _garage;
  CarSkin get selectedSkin => _garage.selectedSkin;

  Future<void> load() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final raw = _prefs!.getString(_key);
      if (raw != null) {
        final json = jsonDecode(raw) as Map<String, Object?>;
        _wallet = Wallet(json['coins'] as int? ?? 0);
        _garage = Garage.fromJson(json);
      }
    } catch (e) {
      debugPrint('Garage load failed: $e');
    }
  }

  void creditCoins(int amount) {
    if (amount <= 0) return;
    _wallet = _wallet.credit(amount);
    _save();
    notifyListeners();
  }

  bool buy(String id) {
    final after = _garage.buy(id, _wallet);
    if (after == null) return false;
    _wallet = after;
    _save();
    notifyListeners();
    return true;
  }

  bool select(String id) {
    if (!_garage.select(id)) return false;
    _save();
    notifyListeners();
    return true;
  }

  void _save() {
    _prefs?.setString(
      _key,
      jsonEncode({'coins': _wallet.balance, ..._garage.toJson()}),
    );
  }
}
