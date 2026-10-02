import 'package:aether/core/database/database.dart';
import 'package:aether/core/providers.dart';
import 'package:aether/features/past_papers/services/past_papers_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final pastPapersServiceProvider = Provider<PastPapersService>((ref) {
  final db = ref.watch(databaseProvider);
  return PastPapersService(db);
});

final papersProvider = StreamProvider<List<PastPaper>>((ref) {
  final service = ref.watch(pastPapersServiceProvider);
  return service.watchPapers();
});

final papersForCourseProvider =
    StreamProvider.family<List<PastPaper>, String>((ref, courseId) {
  final service = ref.watch(pastPapersServiceProvider);
  return service.watchPapersForCourse(courseId);
});