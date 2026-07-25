import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aether/core/database/database.dart';
import 'package:aether/features/tasks/services/task_service.dart';
import 'package:aether/features/academics/providers/academics_providers.dart'
    show databaseProvider;

final taskServiceProvider = Provider<TaskService>((ref) {
  final db = ref.watch(databaseProvider);
  return TaskService(db);
});

/// Tasks stream for a given date key ('YYYY-MM-DD') — pure, no side effects.
/// Sync is triggered from the widget lifecycle (initState / date change),
/// same pattern as AcademicsService.
final tasksForDateProvider =
    StreamProvider.family<List<Task>, String>((ref, dateKey) {
  final service = ref.watch(taskServiceProvider);
  return service.watchTasksForDate(dateKey);
});