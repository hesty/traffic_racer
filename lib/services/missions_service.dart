import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../progression/day_key.dart';
import '../progression/mission.dart';
import '../progression/mission_catalog.dart';
import '../progression/mission_tracker.dart';
import '../progression/run_stats.dart';

/// Owns today's missions and their persisted progress. Rolls fresh missions
/// whenever the calendar day changes.
class MissionsService extends ChangeNotifier {
  MissionsService({DateTime Function()? now}) : _now = now ?? DateTime.now;

  static const _key = 'missions_v1';

  final DateTime Function() _now;
  MissionTracker _tracker = MissionTracker(const []);
  int _dayKey = 0;
  bool _allBonusPaid = false;
  SharedPreferences? _prefs;

  List<Mission> get missions => _tracker.missions;
  bool get allCompleted => _tracker.allCompleted;
  bool get allBonusPaid => _allBonusPaid;

  Future<void> load() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final raw = _prefs!.getString(_key);
      if (raw != null) {
        final json = jsonDecode(raw) as Map<String, Object?>;
        final day = json['day'] as int? ?? 0;
        if (day == dayKeyOf(_now())) {
          final list = (json['missions'] as List).cast<Map<String, Object?>>();
          _tracker = MissionTracker([for (final m in list) Mission.fromJson(m)]);
          _dayKey = day;
          _allBonusPaid = json['allBonusPaid'] as bool? ?? false;
        }
      }
    } catch (e) {
      debugPrint('Missions load failed: $e');
    }
    ensureToday();
  }

  /// Regenerates the missions if the day has changed since they were rolled.
  void ensureToday() {
    final today = dayKeyOf(_now());
    if (today == _dayKey && missions.isNotEmpty) return;
    _dayKey = today;
    _tracker = MissionTracker(MissionCatalog.forDay(today));
    _allBonusPaid = false;
    save();
    notifyListeners();
  }

  void onRunStarted() {
    ensureToday();
    _tracker.onRunStarted();
  }

  /// Applies a run snapshot; newly completed missions are appended to
  /// [completed]. Progress is persisted only on completion; call [save] at
  /// run end or pause to flush partial progress.
  void onRunProgress(RunStats stats, List<Mission> completed) {
    final before = completed.length;
    if (_tracker.onRunTick(stats, completed)) notifyListeners();
    if (completed.length > before) save();
  }

  /// Marks the all-missions bonus as paid. Returns true only the first time
  /// every mission of the day is complete.
  bool claimAllCompleteBonus() {
    if (_allBonusPaid || !allCompleted) return false;
    _allBonusPaid = true;
    save();
    return true;
  }

  void save() {
    _prefs?.setString(
      _key,
      jsonEncode({
        'day': _dayKey,
        'allBonusPaid': _allBonusPaid,
        'missions': [for (final m in missions) m.toJson()],
      }),
    );
  }
}
