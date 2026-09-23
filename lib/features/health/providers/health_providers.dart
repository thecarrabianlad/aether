import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aether/core/providers.dart';
import 'package:aether/features/health/models/exercise.dart';

// healthServiceProvider lives in core/providers.dart — it is wired there with
// the sync queue so offline writes can be replayed. Re-exported here so
// screen code only needs to import this file.
export 'package:aether/core/providers.dart' show healthServiceProvider;

final selectedWeekdayProvider = StateProvider<Weekday>(
    (ref) => Weekday.fromDateTime(DateTime.now()));

/// The full week's workout plan, transformed from Drift rows into UI models
/// and grouped by weekday. The UI always reads from here so it updates
/// instantly on any local write; [HealthService.syncExercises] pulls in
/// remote changes in the background.
final weeklyPlanProvider =
    StreamProvider<Map<Weekday, List<Exercise>>>((ref) {
  final service = ref.watch(healthServiceProvider);

  // Fire-and-forget pull of remote changes (exercises added on another
  // device, or restored after reinstall). The watch() stream below
  // re-emits automatically once these writes land locally.
  service.syncExercises();

  return service.watchAllExercises().map((rows) {
    final plan = {for (final d in Weekday.values) d: <Exercise>[]};
    for (final row in rows) {
      final day = Weekday.fromDb(row.weekday);
      plan[day]!.add(Exercise.fromRow(row));
    }
    return plan;
  });
});
