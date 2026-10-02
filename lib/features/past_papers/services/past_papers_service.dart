import 'dart:typed_data';
import 'package:aether/core/database/database.dart';
import 'package:aether/core/services/supabase_service.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

/// Offline-first past papers data layer.
class PastPapersService {
  final AppDatabase _db;
  final _supabase = SupabaseService.instance.client;

  PastPapersService(this._db);

  String? get _userId => _supabase.auth.currentUser?.id;

  // ── Reads ──────────────────────────────────────────

  Stream<List<PastPaper>> watchPapers() {
    final userId = _userId;
    if (userId == null) return Stream.value(const []);
    return (_db.select(_db.pastPapers)
          ..where((p) => p.userId.equals(userId))
          ..orderBy([(p) => OrderingTerm.desc(p.createdAt)]))
        .watch();
  }

  Stream<List<PastPaper>> watchPapersForCourse(String courseId) {
    final userId = _userId;
    if (userId == null) return Stream.value(const []);
    return (_db.select(_db.pastPapers)
          ..where((p) => p.userId.equals(userId) & p.courseId.equals(courseId))
          ..orderBy([(p) => OrderingTerm.desc(p.createdAt)]))
        .watch();
  }

  Future<void> syncPapers() async {
    final userId = _userId;
    if (userId == null) return;
    final remote =
        await _supabase.from('past_papers').select().eq('user_id', userId);
    for (final row in remote) {
      await _db.into(_db.pastPapers).insertOnConflictUpdate(_paperFromRow(row, userId));
    }
  }

  // ── File upload ────────────────────────────────────

  /// Uploads [bytes] to the `past-papers` Supabase Storage bucket, returns
  /// the public path of the uploaded file.
  Future<String> uploadFile({
    required String fileName,
    required Uint8List bytes,
  }) async {
    final userId = _userId;
    if (userId == null) throw Exception('Not authenticated');

    final path = '$userId/${const Uuid().v4()}-$fileName';
    await _supabase.storage.from('past-papers').uploadBinary(path, bytes);
    return path;
  }

  // ── Writes ─────────────────────────────────────────

  Future<PastPaper> createPaper({
    required String title,
    String? courseId,
    String? year,
    String? examType,
    String? fileUrl,
    String? fileName,
    String? tags,
  }) async {
    final userId = _userId;
    if (userId == null) throw Exception('Not authenticated');

    final now = DateTime.now();
    final paper = PastPaper(
      id: const Uuid().v4(),
      userId: userId,
      courseId: courseId,
      title: title,
      year: year,
      examType: examType,
      fileUrl: fileUrl,
      fileName: fileName,
      tags: tags,
      createdAt: now,
      updatedAt: now,
    );

    await _db.into(_db.pastPapers).insert(paper);
    await _push(() => _supabase.from('past_papers').insert(_paperToRow(paper)));
    return paper;
  }

  Future<void> updatePaper(PastPaper paper) async {
    final updated = paper.copyWith(updatedAt: DateTime.now());
    await (_db.update(_db.pastPapers)..where((p) => p.id.equals(paper.id)))
        .replace(updated);
    await _push(() => _supabase
        .from('past_papers')
        .update(_paperToRow(updated))
        .eq('id', updated.id));
  }

  Future<void> deletePaper(String paperId) async {
    final paper = await (_db.select(_db.pastPapers)
          ..where((p) => p.id.equals(paperId)))
        .getSingleOrNull();
    if (paper?.fileUrl != null) {
      try {
        await _supabase.storage.from('past-papers').remove([paper!.fileUrl!]);
      } catch (_) {
        // File may already be gone.
      }
    }
    await (_db.delete(_db.pastPapers)..where((p) => p.id.equals(paperId))).go();
    await _push(() => _supabase.from('past_papers').delete().eq('id', paperId));
  }

  // ── Helpers ──────────────────────────────────────────

  Future<void> _push(Future<void> Function() op) async {
    try {
      await op();
    } catch (_) {
      // Offline-first: ignore transient errors.
    }
  }

  PastPaper _paperFromRow(Map<String, dynamic> r, String userId) => PastPaper(
        id: r['id'] as String,
        userId: r['user_id'] as String? ?? userId,
        courseId: r['course_id'] as String?,
        title: r['title'] as String? ?? '',
        year: r['year'] as String?,
        examType: r['exam_type'] as String?,
        fileUrl: r['file_url'] as String?,
        fileName: r['file_name'] as String?,
        tags: r['tags'] as String?,
        createdAt: _parseDate(r['created_at']),
        updatedAt: _parseDate(r['updated_at']),
      );

  Map<String, dynamic> _paperToRow(PastPaper p) => {
        'id': p.id,
        'user_id': p.userId,
        'course_id': p.courseId,
        'title': p.title,
        'year': p.year,
        'exam_type': p.examType,
        'file_url': p.fileUrl,
        'file_name': p.fileName,
        'tags': p.tags,
        'created_at': p.createdAt.toIso8601String(),
        'updated_at': p.updatedAt.toIso8601String(),
      };

  DateTime _parseDate(dynamic v) =>
      v is String ? DateTime.parse(v) : DateTime.now();
}
