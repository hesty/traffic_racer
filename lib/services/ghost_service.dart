import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../progression/ghost_trace.dart';

/// Stores the pace trace of the best run so later runs can race it.
class GhostService {
  static const _key = 'ghost_v1';

  final ValueNotifier<GhostTrace?> best = ValueNotifier(null);
  SharedPreferences? _prefs;

  Future<void> load() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final raw = _prefs!.getString(_key);
      if (raw != null) {
        final trace = GhostTrace.fromJson(jsonDecode(raw) as List<Object?>);
        if (!trace.isEmpty) best.value = trace;
      }
    } catch (e) {
      debugPrint('Ghost load failed: $e');
    }
  }

  /// Replaces the stored ghost. The caller decides when a run qualifies (it
  /// should be the same run that set the high score).
  void submit(GhostTrace trace) {
    if (trace.isEmpty) return;
    best.value = trace;
    _prefs?.setString(_key, jsonEncode(trace.toJson()));
  }
}
