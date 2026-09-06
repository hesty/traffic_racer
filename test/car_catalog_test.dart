import 'package:flutter_test/flutter_test.dart';
import 'package:turbo_traffic_rush/progression/car_catalog.dart';
import 'package:turbo_traffic_rush/entities/traffic_vehicle.dart';
import 'package:flutter/material.dart';

void main() {
  group('CarCatalog', () {
    test('defaultId returns the first sedan amber skin', () {
      expect(CarCatalog.defaultId, equals('sedan_amber'));
    });

    test('byId returns the first entry for unknown ids', () {
      final s = CarCatalog.byId('nonexistent');
      expect(s.id, equals(CarCatalog.defaultId));
    });

    test('premium returns only cars with premium=true', () {
      expect(CarCatalog.premium.length, greaterThan(0));
      for (final skin in CarCatalog.premium) {
        expect(skin.premium, isTrue);
        expect(skin.price, 0);
      }
    });

    test('all contains the expected varieties', () {
      final ids = [for (final s in CarCatalog.all) s.id];
      expect(ids.contains('sedan_amber'), isTrue);
      expect(ids.contains('pass_bullion'), isTrue);
    });

    test('CarSkin name combines label and kind', () {
      final sedan = CarCatalog.byId('sedan_amber');
      expect(sedan.name, equals('AMBER SEDAN'));
    });
  });

  group('VehicleKind', () {
    test('every catalog entry has a valid VehicleKind', () {
      final kinds = VehicleKind.values.toSet();
      for (final skin in CarCatalog.all) {
        expect(kinds.contains(skin.kind), isTrue,
            reason: '${skin.id} has kind ${skin.kind}');
      }
    });
  });
}
