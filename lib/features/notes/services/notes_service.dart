import 'package:aether/core/database/database.dart';
import 'package:aether/core/services/supabase_service.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

/// Offline-first notes data layer.
class NotesService {
  final AppDatabase _db;
  final _supabase = SupabaseService.instance.client;

  NotesService(this._db);

  String? get _userId => _supabase.auth.currentUser?.id;

  // ── Reads ──────────────────────────────────────────

  Stream<List<Note>> watchNotes() {
    final userId = _userId;
    if (userId == null) return Stream.value(const []);
    return (_db.select(_db.notes)
          ..where((n) => n.userId.equals(userId))
          ..orderBy([(n) => OrderingTerm.desc(n.updatedAt)]))
        .watch();
  }

  Stream<List<Note>> watchNotesForCourse(String courseId) {
    final userId = _userId;
    if (userId == null) return Stream.value(const []);
    return (_db.select(_db.notes)
          ..where((n) => n.userId.equals(userId) & n.courseId.equals(courseId))
          ..orderBy([(n) => OrderingTerm.desc(n.updatedAt)]))
        .watch();
  }

  Future<void> syncNotes() async {
    final userId = _userId;
    if (userId == null) return;
    final remote = await _supabase.from('notes').select().eq('user_id', userId);
    for (final row in remote) {
      await _db.into(_db.notes).insertOnConflictUpdate(_noteFromRow(row, userId));
    }
  }

  // ── Writes ─────────────────────────────────────────

  Future<Note> createNote({
    required String title,
    String content = '',
    String? courseId,
    String? tags,
  }) async {
    final userId = _userId;
    if (userId == null) throw Exception('Not authenticated');

    final now = DateTime.now();
    final note = Note(
      id: const Uuid().v4(),
      userId: userId,
      courseId: courseId,
      title: title,
      content: content,
      tags: tags,
      createdAt: now,
      updatedAt: now,
    );

    await _db.into(_db.notes).insert(note);
    await _push(() => _supabase.from('notes').insert(_noteToRow(note)));
    return note;
  }

  Future<void> updateNote(Note note) async {
    final updated = note.copyWith(updatedAt: DateTime.now());
    await (_db.update(_db.notes)..where((n) => n.id.equals(note.id))).replace(updated);
    await _push(() => _supabase
        .from('notes')
        .update(_noteToRow(updated))
        .eq('id', updated.id));
  }

  Future<void> deleteNote(String noteId) async {
    await (_db.delete(_db.notes)..where((n) => n.id.equals(noteId))).go();
    await _push(() => _supabase.from('notes').delete().eq('id', noteId));
  }

  // ── Helpers ──────────────────────────────────────────

  Future<void> _push(Future<void> Function() op) async {
    try {
      await op();
    } catch (_) {
      // Offline-first: ignore transient errors.
    }
  }

  Note _noteFromRow(Map<String, dynamic> r, String userId) => Note(
        id: r['id'] as String,
        userId: r['user_id'] as String? ?? userId,
        courseId: r['course_id'] as String?,
        title: r['title'] as String? ?? '',
        content: r['content'] as String? ?? '',
        tags: r['tags'] as String?,
        createdAt: _parseDate(r['created_at']),
        updatedAt: _parseDate(r['updated_at']),
      );

  Map<String, dynamic> _noteToRow(Note n) => {
        'id': n.id,
        'user_id': n.userId,
        'course_id': n.courseId,
        'title': n.title,
        'content': n.content,
        'tags': n.tags,
        'created_at': n.createdAt.toIso8601String(),
        'updated_at': n.updatedAt.toIso8601String(),
      };

  DateTime _parseDate(dynamic v) =>
      v is String ? DateTime.parse(v) : DateTime.now();
}
