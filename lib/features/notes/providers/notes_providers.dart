import 'package:aether/core/database/database.dart';
import 'package:aether/core/providers.dart';
import 'package:aether/features/notes/services/notes_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final notesServiceProvider = Provider<NotesService>((ref) {
  final db = ref.watch(databaseProvider);
  return NotesService(db);
});

final notesProvider = StreamProvider<List<Note>>((ref) {
  final service = ref.watch(notesServiceProvider);
  return service.watchNotes();
});

final notesForCourseProvider =
    StreamProvider.family<List<Note>, String>((ref, courseId) {
  final service = ref.watch(notesServiceProvider);
  return service.watchNotesForCourse(courseId);
});