import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aether/core/database/database.dart';
import 'package:aether/core/services/academics_service.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final academicsServiceProvider = Provider<AcademicsService>((ref) {
  final db = ref.watch(databaseProvider);
  return AcademicsService(db);
});

/// Courses stream from local DB. Triggers a background sync on first listen.
final coursesProvider = StreamProvider<List<Course>>((ref) {
  final service = ref.watch(academicsServiceProvider);
  service.syncCourses();
  return service.watchCourses();
});

final selectedCourseProvider = StateProvider<Course?>((ref) => null);

/// Lectures stream for a course. Triggers a background sync on first listen.
final lecturesProvider =
    StreamProvider.family<List<Lecture>, String>((ref, courseId) {
  final service = ref.watch(academicsServiceProvider);
  service.syncLectures(courseId);
  return service.watchLectures(courseId);
});

/// Assignments stream for a course. Triggers a background sync on first listen.
final assignmentsProvider =
    StreamProvider.family<List<Assignment>, String>((ref, courseId) {
  final service = ref.watch(academicsServiceProvider);
  service.syncAssignments(courseId);
  return service.watchAssignments(courseId);
});

/// Live progress (0..1) for a course = completed / total items.
final courseProgressProvider =
    StreamProvider.family<double, String>((ref, courseId) {
  final lecturesAsync = ref.watch(lecturesProvider(courseId));
  final assignmentsAsync = ref.watch(assignmentsProvider(courseId));

  final lectures = lecturesAsync.valueOrNull ?? [];
  final assignments = assignmentsAsync.valueOrNull ?? [];

  final total = lectures.length + assignments.length;
  if (total == 0) return Stream.value(0.0);

  final done = lectures.where((l) => l.isCompleted).length +
      assignments.where((a) => a.isCompleted).length;
  return Stream.value(done / total);
});
