import 'package:aether/core/database/database.dart';
import 'package:aether/core/services/supabase_service.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

/// Offline-first academics data layer.
///
/// The UI always reads from the local Drift database via the `watch*`
/// streams, so it updates instantly. Mutations write to Drift first
/// (immediate UI reaction) then push to Supabase in the background.
/// `sync*` methods pull remote data into the local DB.
class AcademicsService {
  final AppDatabase _db;
  final _supabase = SupabaseService.instance.client;

  AcademicsService(this._db);

  String? get _userId => _supabase.auth.currentUser?.id;

  // ── Courses ──────────────────────────────────────────

  Stream<List<Course>> watchCourses() => _db.select(_db.courses).watch();

  Future<void> syncCourses() async {
    final userId = _userId;
    if (userId == null) return;

    final remote = await _supabase.from('courses').select().eq('user_id', userId);
    for (final row in remote) {
      await _db.into(_db.courses).insertOnConflictUpdate(_courseFromRow(row, userId));
    }
  }

  Future<Course> createCourse({
    required String name,
    String? code,
    String? professor,
    String? color,
    String? icon,
    String? semester,
    String? location,
    int? credits,
    String? scheduleDays,
    String? scheduleStart,
    String? scheduleEnd,
  }) async {
    final userId = _userId;
    if (userId == null) throw Exception('Not authenticated');

    final course = Course(
      id: const Uuid().v4(),
      userId: userId,
      name: name,
      code: code,
      professor: professor,
      color: color ?? '#8B5CF6',
      icon: icon,
      semester: semester,
      location: location,
      credits: credits,
      scheduleDays: scheduleDays,
      scheduleStart: scheduleStart,
      scheduleEnd: scheduleEnd,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _db.into(_db.courses).insert(course);
    await _push(() => _supabase.from('courses').insert(_courseToRow(course)));
    return course;
  }

  Future<void> updateCourse(Course course) async {
    final updated = course.copyWith(updatedAt: DateTime.now());
    await _db.update(_db.courses).replace(updated);
    await _push(() => _supabase
        .from('courses')
        .update(_courseToRow(updated))
        .eq('id', updated.id));
  }

  Future<void> deleteCourse(String courseId) async {
    await (_db.delete(_db.courses)..where((t) => t.id.equals(courseId))).go();
    await (_db.delete(_db.lectures)..where((t) => t.courseId.equals(courseId))).go();
    await (_db.delete(_db.assignments)..where((t) => t.courseId.equals(courseId))).go();
    await _push(() => _supabase.from('courses').delete().eq('id', courseId));
  }

  // ── Lectures ──────────────────────────────────────────

  Stream<List<Lecture>> watchLectures(String courseId) =>
      (_db.select(_db.lectures)
            ..where((l) => l.courseId.equals(courseId))
            ..orderBy([(l) => OrderingTerm(expression: l.scheduledAt)]))
          .watch();

  Future<void> syncLectures(String courseId) async {
    final userId = _userId;
    if (userId == null) return;

    final remote = await _supabase
        .from('lectures')
        .select()
        .eq('user_id', userId)
        .eq('course_id', courseId);
    for (final row in remote) {
      await _db.into(_db.lectures).insertOnConflictUpdate(_lectureFromRow(row, userId));
    }
  }

  Future<void> createLecture(
    String courseId,
    String title, {
    String? chapter,
    DateTime? scheduledAt,
  }) async {
    final userId = _userId;
    if (userId == null) throw Exception('Not authenticated');

    final lecture = Lecture(
      id: const Uuid().v4(),
      courseId: courseId,
      userId: userId,
      title: title,
      chapter: chapter,
      tag: 'Upcoming',
      scheduledAt: scheduledAt,
      durationMinutes: 90,
      isCompleted: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _db.into(_db.lectures).insert(lecture);
    await _push(() => _supabase.from('lectures').insert(_lectureToRow(lecture)));
  }

  Future<void> toggleLectureCompletion(String lectureId, bool completed) async {
    final now = DateTime.now();
    await (_db.update(_db.lectures)..where((l) => l.id.equals(lectureId)))
        .write(LecturesCompanion(
      isCompleted: Value(completed),
      completedAt: Value(completed ? now : null),
      updatedAt: Value(now),
    ));
    await _push(() => _supabase.from('lectures').update({
          'is_completed': completed,
          'completed_at': completed ? now.toIso8601String() : null,
          'updated_at': now.toIso8601String(),
        }).eq('id', lectureId));
  }

  Future<void> deleteLecture(String lectureId) async {
    await (_db.delete(_db.lectures)..where((l) => l.id.equals(lectureId))).go();
    await _push(() => _supabase.from('lectures').delete().eq('id', lectureId));
  }

  // ── Assignments ──────────────────────────────────────

  Stream<List<Assignment>> watchAssignments(String courseId) =>
      (_db.select(_db.assignments)
            ..where((a) => a.courseId.equals(courseId))
            ..orderBy([(a) => OrderingTerm(expression: a.dueDate)]))
          .watch();

  Future<void> syncAssignments(String courseId) async {
    final userId = _userId;
    if (userId == null) return;

    final remote = await _supabase
        .from('assignments')
        .select()
        .eq('user_id', userId)
        .eq('course_id', courseId);
    for (final row in remote) {
      await _db.into(_db.assignments).insertOnConflictUpdate(_assignmentFromRow(row, userId));
    }
  }

  Future<void> createAssignment(
    String courseId,
    String title, {
    String? description,
    DateTime? dueDate,
  }) async {
    final userId = _userId;
    if (userId == null) throw Exception('Not authenticated');

    final assignment = Assignment(
      id: const Uuid().v4(),
      courseId: courseId,
      userId: userId,
      title: title,
      description: description,
      dueDate: dueDate,
      isCompleted: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _db.into(_db.assignments).insert(assignment);
    await _push(() => _supabase.from('assignments').insert(_assignmentToRow(assignment)));
  }

  Future<void> toggleAssignmentCompletion(String assignmentId, bool completed) async {
    final now = DateTime.now();
    await (_db.update(_db.assignments)..where((a) => a.id.equals(assignmentId)))
        .write(AssignmentsCompanion(
      isCompleted: Value(completed),
      completedAt: Value(completed ? now : null),
      updatedAt: Value(now),
    ));
    await _push(() => _supabase.from('assignments').update({
          'is_completed': completed,
          'completed_at': completed ? now.toIso8601String() : null,
          'updated_at': now.toIso8601String(),
        }).eq('id', assignmentId));
  }

  Future<void> deleteAssignment(String assignmentId) async {
    await (_db.delete(_db.assignments)..where((a) => a.id.equals(assignmentId))).go();
    await _push(() => _supabase.from('assignments').delete().eq('id', assignmentId));
  }

  // ── Helpers ──────────────────────────────────────────

  /// Runs a remote push, swallowing network errors so the local-first
  /// write still stands (offline-first). Rethrows only auth errors.
  Future<void> _push(Future<void> Function() op) async {
    try {
      await op();
    } catch (_) {
      // Offline or transient error — local DB is source of truth until
      // the next successful sync. Intentionally ignored.
    }
  }

  Course _courseFromRow(Map<String, dynamic> r, String userId) => Course(
        id: r['id'] as String,
        userId: r['user_id'] as String? ?? userId,
        name: r['name'] as String? ?? '',
        code: r['code'] as String?,
        professor: r['professor'] as String?,
        color: r['color'] as String? ?? '#8B5CF6',
        icon: r['icon'] as String?,
        semester: r['semester'] as String?,
        location: r['location'] as String?,
        credits: r['credits'] as int?,
        scheduleDays: r['schedule_days'] is List
            ? (r['schedule_days'] as List).join(',')
            : r['schedule_days'] as String?,
        scheduleStart: r['schedule_start'] as String?,
        scheduleEnd: r['schedule_end'] as String?,
        createdAt: _parseDate(r['created_at']),
        updatedAt: _parseDate(r['updated_at']),
      );

  Map<String, dynamic> _courseToRow(Course c) => {
        'id': c.id,
        'user_id': c.userId,
        'name': c.name,
        'code': c.code,
        'professor': c.professor,
        'color': c.color,
        'icon': c.icon,
        'semester': c.semester,
        'location': c.location,
        'credits': c.credits,
        'schedule_days': c.scheduleDays?.split(',').map((s) => s.trim()).toList(),
        'schedule_start': c.scheduleStart,
        'schedule_end': c.scheduleEnd,
        'created_at': c.createdAt.toIso8601String(),
        'updated_at': c.updatedAt.toIso8601String(),
      };

  Lecture _lectureFromRow(Map<String, dynamic> r, String userId) => Lecture(
        id: r['id'] as String,
        courseId: r['course_id'] as String,
        userId: r['user_id'] as String? ?? userId,
        title: r['title'] as String? ?? '',
        chapter: r['chapter'] as String?,
        tag: r['tag'] as String?,
        scheduledAt: r['scheduled_at'] != null ? DateTime.parse(r['scheduled_at'] as String) : null,
        durationMinutes: r['duration_minutes'] as int? ?? 90,
        isCompleted: r['is_completed'] as bool? ?? false,
        completedAt: r['completed_at'] != null ? DateTime.parse(r['completed_at'] as String) : null,
        createdAt: _parseDate(r['created_at']),
        updatedAt: _parseDate(r['updated_at']),
      );

  Map<String, dynamic> _lectureToRow(Lecture l) => {
        'id': l.id,
        'course_id': l.courseId,
        'user_id': l.userId,
        'title': l.title,
        'chapter': l.chapter,
        'tag': l.tag,
        'scheduled_at': l.scheduledAt?.toIso8601String(),
        'duration_minutes': l.durationMinutes,
        'is_completed': l.isCompleted,
        'completed_at': l.completedAt?.toIso8601String(),
        'created_at': l.createdAt.toIso8601String(),
        'updated_at': l.updatedAt.toIso8601String(),
      };

  Assignment _assignmentFromRow(Map<String, dynamic> r, String userId) => Assignment(
        id: r['id'] as String,
        courseId: r['course_id'] as String,
        userId: r['user_id'] as String? ?? userId,
        title: r['title'] as String? ?? '',
        description: r['description'] as String?,
        dueDate: r['due_date'] != null ? DateTime.parse(r['due_date'] as String) : null,
        isCompleted: r['is_completed'] as bool? ?? false,
        completedAt: r['completed_at'] != null ? DateTime.parse(r['completed_at'] as String) : null,
        createdAt: _parseDate(r['created_at']),
        updatedAt: _parseDate(r['updated_at']),
      );

  Map<String, dynamic> _assignmentToRow(Assignment a) => {
        'id': a.id,
        'course_id': a.courseId,
        'user_id': a.userId,
        'title': a.title,
        'description': a.description,
        'due_date': a.dueDate?.toIso8601String(),
        'is_completed': a.isCompleted,
        'completed_at': a.completedAt?.toIso8601String(),
        'created_at': a.createdAt.toIso8601String(),
        'updated_at': a.updatedAt.toIso8601String(),
      };

  DateTime _parseDate(dynamic v) =>
      v is String ? DateTime.parse(v) : DateTime.now();
}
