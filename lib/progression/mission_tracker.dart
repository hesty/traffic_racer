import 'dart:math' as math;

import 'mission.dart';
import 'run_stats.dart';

/// Pure progress logic over the day's missions. Feed it run snapshots; it
/// ratchets each mission's progress and reports the ones that just completed.
class MissionTracker {
  MissionTracker(this.missions)
      : _baseline = List<int>.filled(missions.length, 0);

  final List<Mission> missions;

  /// Progress each mission had when the current run started. Cumulative
  /// kinds add the run's total on top of it.
  final List<int> _baseline;

  bool get allCompleted =>
      missions.isNotEmpty && missions.every((m) => m.completed);

  void onRunStarted() {
    for (var i = 0; i < missions.length; i++) {
      _baseline[i] = missions[i].progress;
    }
  }

  /// Updates progress from [stats]. Appends missions that completed during
  /// this call to [completed] (caller-owned, not cleared here). Returns true
  /// when any progress value changed.
  bool onRunTick(RunStats stats, List<Mission> completed) {
    var changed = false;
    for (var i = 0; i < missions.length; i++) {
      final m = missions[i];
      if (m.completed) continue;
      final run = stats.valueFor(m.kind);
      final value = m.kind.isCumulative ? _baseline[i] + run : run;
      final next = math.max(m.progress, value);
      if (next != m.progress) {
        m.progress = next;
        changed = true;
      }
      if (m.progress >= m.target) {
        m.completed = true;
        completed.add(m);
      }
    }
    return changed;
  }
}
