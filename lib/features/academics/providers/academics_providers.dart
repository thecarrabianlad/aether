import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aether/core/database/database.dart';
import 'package:aether/core/providers.dart';

// academicsServiceProvider lives in core/providers.dart — it is wired there with
// the sync queue so offline writes can be replayed. Re-exported here so existing
// imports of this file keep working.
export 'package:aether/core/providers.dart' show academicsServiceProvider;

/// Courses stream from local DB — pure, no side effects.
/// Sync is triggered from the widget lifecycle (initState → addPostFrameCallback).
final coursesProvider = StreamProvider<List<Course>>((ref) {
  final service = ref.watch(academicsServiceProvider);
  return service.watchCourses();
});

final selectedCourseProvider = StateProvider<Course?>((ref) => null);

/// Lectures stream for a course — pure, no side effects.
final lecturesProvider =
    StreamProvider.family<List<Lecture>, String>((ref, courseId) {
  final service = ref.watch(academicsServiceProvider);
  return service.watchLectures(courseId);
});

/// Assignments stream for a course — pure, no side effects.
final assignmentsProvider =
    StreamProvider.family<List<Assignment>, String>((ref, courseId) {
  final service = ref.watch(academicsServiceProvider);
  return service.watchAssignments(courseId);
});

/// Live progress (0..1) for a course = completed / total items.
final courseProgressProvider =
    StreamProvider.family<double, String>((ref, courseId) {
  final lecturesAsync = ref.watch(lecturesProvider(courseId));
  final assignmentsAsync = ref.watch(assignmentsProvider(courseId));

  final lectures = lecturesAsync.value ?? [];
  final assignments = assignmentsAsync.value ?? [];

  final total = lectures.length + assignments.length;
  if (total == 0) return Stream.value(0.0);

  final done = lectures.where((l) => l.isCompleted).length +
      assignments.where((a) => a.isCompleted).length;
  return Stream.value(done / total);
});

/// Count of lectures (across all courses) scheduled on [date] — powers the
/// dashboard's "Classes today" glance card. Lives here (not in a separate
/// provider) since it composes coursesProvider + lecturesProvider, both of
/// which already live in this file.
final classesOnDateProvider = Provider.family<int, DateTime>((ref, date) {
  final coursesAsync = ref.watch(coursesProvider);
  final courses = coursesAsync.value ?? const <Course>[];

  int count = 0;
  for (final course in courses) {
    final lecturesAsync = ref.watch(lecturesProvider(course.id));
    final lectures = lecturesAsync.value ?? const <Lecture>[];
    count += lectures.where((l) {
      final scheduled = l.scheduledAt;
      if (scheduled == null) return false;
      return scheduled.year == date.year &&
          scheduled.month == date.month &&
          scheduled.day == date.day;
    }).length;
  }
  return count;
});

/// Grades stream for a course — pure, no side effects.
final gradesProvider = StreamProvider.family<List<Grade>, String>((ref, courseId) {
  final service = ref.watch(academicsServiceProvider);
  return service.watchGrades(courseId);
});
