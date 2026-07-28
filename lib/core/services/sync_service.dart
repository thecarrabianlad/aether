import 'package:aether/core/services/academics_service.dart';
import 'package:aether/features/habits/services/habits_service.dart';

/// Orchestrates data synchronization between local Drift database and Supabase.
class SyncService {
  final AcademicsService _academicsService;
  final HabitsService _habitsService;

  SyncService(this._academicsService, this._habitsService);

  /// Performs an initial sync of all data on app startup/login.
  Future<void> performInitialSync() async {
    // Perform sync operations in parallel
    await Future.wait([
      _academicsService.syncCourses(),
      _academicsService.syncLectures(), // Now optional
      _academicsService.syncAssignments(), // Now optional
      _habitsService.syncHabits(),
      _habitsService.syncHabitLogs(),
    ]);
    // print('Initial sync completed for all services.');
  }

  /// Syncs all data (pull from remote, push local changes).
  Future<void> syncAllData() async {
    // This will evolve into a more sophisticated sync logic in later tasks
    // involving change tracking and conflict resolution.
    await performInitialSync(); // For now, simple re-pull
    // print('Full data sync initiated.');
  }
}
