import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aether/core/database/database.dart';
import 'package:aether/core/services/academics_service.dart';
import 'package:aether/core/database/tables/courses.dart';
import 'package:aether/core/database/tables/lectures.dart';
import 'package:aether/core/database/tables/assignments.dart';

final databaseProvider = Provider<AppDatabase>((ref) => AppDatabase());

final academicsServiceProvider = Provider<AcademicsService>((ref) {
  final db = ref.watch(databaseProvider);
  return AcademicsService(db);
});

final coursesProvider = StreamProvider<List<Course>>((ref) {
  final service = ref.watch(academicsServiceProvider);
  return service.watchCourses();
});

final selectedCourseProvider = StateProvider<Course?>((ref) => null);

final lecturesProvider = FutureProvider.family<List<Lecture>, String>((ref, courseId) async {
  final service = ref.watch(academicsServiceProvider);
  return service.getLectures(courseId: courseId);
});

final assignmentsProvider = FutureProvider.family<List<Assignment>, String>((ref, courseId) async {
  final service = ref.watch(academicsServiceProvider);
  return service.watchAssignments(courseId: courseId);
});