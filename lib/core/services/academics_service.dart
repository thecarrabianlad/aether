import 'package:aether/core/database/database.dart';
import 'package:aether/core/services/supabase_service.dart';
import 'package:aether/core/services/sync_queue_service.dart';
import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Unified Supabase import
import 'package:uuid/uuid.dart';


/// Offline-first academics data layer.
///
/// The UI always reads from the local Drift database via the `watch*`
/// streams, so it updates instantly. Mutations write to Drift first
/// (immediate UI reaction) then push to Supabase in the background.
/// `sync*` methods pull remote data into the local DB.
class AcademicsService {
  final AppDatabase _db;
  final SyncQueueService _syncQueueService;
  final _supabase = SupabaseService.instance.client;

  AcademicsService(this._db, this._syncQueueService);

  String? get _userId => _supabase.auth.currentUser?.id;

  // ── Courses ──────────────────────────────────────────

  Stream<List<Course>> watchCourses() =>
      (_db.select(_db.courses)..where((c) => c.userId.equals(_userId!))).watch();

  Future<void> syncCourses() async {
    final userId = _userId;
    if (userId == null) return;

    final remote = await _supabase.from('courses').select().eq('user_id', userId);
    for (final row in remote) {
      await _db.into(_db.courses).insertOnConflictUpdate(_courseFromRow(row, userId));
    }
  }


  Future<Course> createCourse({
    String? id,
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
      id: id ?? const Uuid().v4(),
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
    await _push(
      op: () => _directUpsertCourseToRemote(course), // Use direct upsert
      entityType: SyncEntityType.course,
      operation: SyncOperation.insert,
      entityId: course.id,
      payload: _courseToRow(course),
    );
    return course;
  }

  Future<void> updateCourse(Course course) async {
    final updated = course.copyWith(updatedAt: DateTime.now());
    await _db.update(_db.courses).replace(updated);
    await _push(
      op: () => _directUpsertCourseToRemote(updated), // Use direct upsert
      entityType: SyncEntityType.course,
      operation: SyncOperation.update,
      entityId: updated.id,
      payload: _courseToRow(updated),
    );
  }

  Future<void> deleteCourse(String courseId) async {
    await (_db.delete(_db.courses)..where((c) => c.id.equals(courseId))).go();
    await (_db.delete(_db.lectures)..where((l) => l.courseId.equals(courseId))).go();
    await (_db.delete(_db.assignments)..where((a) => a.courseId.equals(courseId))).go();
    await _push(
      op: () => _directDeleteCourseRemote(courseId), // Use direct delete
      entityType: SyncEntityType.course,
      operation: SyncOperation.delete,
      entityId: courseId,
    );
  }

  // ── Lectures ──────────────────────────────────────────

  Stream<List<Lecture>> watchLectures(String courseId) =>
      (_db.select(_db.lectures)
            ..where((l) => l.courseId.equals(courseId))
            ..orderBy([(l) => OrderingTerm(expression: l.scheduledAt)]))
          .watch();

  Future<void> syncLectures({String? courseId}) async {
    final userId = _userId;
    if (userId == null) return;

    PostgrestFilterBuilder query = _supabase.from('lectures').select();
    if (courseId != null) {
      query = query.eq('course_id', courseId);
    } else {
      query = query.eq('user_id', userId);
    }
    final remote = await query;
    for (final row in remote) {
      await _db.into(_db.lectures).insertOnConflictUpdate(_lectureFromRow(row, userId));
    }
  }

  Future<Lecture> createLecture({
    String? id,
    required String courseId,
    required String title,
    String? chapter,
    String? tag,
    DateTime? scheduledAt,
    int? durationMinutes,
    bool? isCompleted,
    DateTime? completedAt,
  }) async {
    final userId = _userId;
    if (userId == null) throw Exception('Not authenticated');

    final lecture = Lecture(
      id: id ?? const Uuid().v4(),
      courseId: courseId,
      userId: userId,
      title: title,
      chapter: chapter,
      tag: tag,
      scheduledAt: scheduledAt,
      durationMinutes: durationMinutes,
      isCompleted: isCompleted ?? false,
      completedAt: completedAt,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _db.into(_db.lectures).insert(lecture);
    await _push(
      op: () => _directUpsertLectureToRemote(lecture), // Use direct upsert
      entityType: SyncEntityType.lecture,
      operation: SyncOperation.insert,
      entityId: lecture.id,
      payload: _lectureToRow(lecture),
    );
    return lecture;
  }

  Future<void> updateLecture(Lecture lecture) async {
    final updated = lecture.copyWith(updatedAt: DateTime.now());
    await _db.update(_db.lectures).replace(updated);
    await _push(
      op: () => _directUpsertLectureToRemote(updated), // Use direct upsert
      entityType: SyncEntityType.lecture,
      operation: SyncOperation.update,
      entityId: updated.id,
      payload: _lectureToRow(updated),
    );
  }

  Future<void> deleteLecture(String lectureId) async {
    await (_db.delete(_db.lectures)..where((l) => l.id.equals(lectureId))).go();
    await _push(
      op: () => _directDeleteLectureRemote(lectureId), // Use direct delete
      entityType: SyncEntityType.lecture,
      operation: SyncOperation.delete,
      entityId: lectureId,
    );
  }

  // ── Assignments ──────────────────────────────────────

  Stream<List<Assignment>> watchAssignments(String courseId) =>
      (_db.select(_db.assignments)
            ..where((a) => a.courseId.equals(courseId))
            ..orderBy([(a) => OrderingTerm(expression: a.dueDate)]))
          .watch();

  Future<void> syncAssignments({String? courseId}) async {
    final userId = _userId;
    if (userId == null) return;

    PostgrestFilterBuilder query = _supabase.from('assignments').select();
    if (courseId != null) {
      query = query.eq('course_id', courseId);
    } else {
      query = query.eq('user_id', userId);
    }
    final remote = await query;
    for (final row in remote) {
      await _db.into(_db.assignments).insertOnConflictUpdate(_assignmentFromRow(row, userId));
    }
  }

  Future<Assignment> createAssignment({
    String? id,
    required String courseId,
    required String title,
    String? description,
    DateTime? dueDate,
    bool? isCompleted,
    DateTime? completedAt,
  }) async {
    final userId = _userId;
    if (userId == null) throw Exception('Not authenticated');

    final assignment = Assignment(
      id: id ?? const Uuid().v4(),
      courseId: courseId,
      userId: userId,
      title: title,
      description: description,
      dueDate: dueDate,
      isCompleted: isCompleted ?? false,
      completedAt: completedAt,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _db.into(_db.assignments).insert(assignment);
    await _push(
      op: () => _directUpsertAssignmentToRemote(assignment), // Use direct upsert
      entityType: SyncEntityType.assignment,
      operation: SyncOperation.insert,
      entityId: assignment.id,
      payload: _assignmentToRow(assignment),
    );
    return assignment;
  }

  Future<void> updateAssignment(Assignment assignment) async {
    final updated = assignment.copyWith(updatedAt: DateTime.now());
    await _db.update(_db.assignments).replace(updated);
    await _push(
      op: () => _directUpsertAssignmentToRemote(updated), // Use direct upsert
      entityType: SyncEntityType.assignment,
      operation: SyncOperation.update,
      entityId: updated.id,
      payload: _assignmentToRow(updated),
    );
  }

  Future<void> deleteAssignment(String assignmentId) async {
    await (_db.delete(_db.assignments)..where((a) => a.id.equals(assignmentId))).go();
    await _push(
      op: () => _directDeleteAssignmentRemote(assignmentId), // Use direct delete
      entityType: SyncEntityType.assignment,
      operation: SyncOperation.delete,
      entityId: assignmentId,
    );
  }

  // ── Helpers ──────────────────────────────────────────

  /// Runs a remote push. If successful, returns true. If network/transient error,
  /// enqueues for retry and returns false. Rethrows only AuthExceptions.
  Future<void> _push({
    required Future<void> Function() op,
    required SyncEntityType entityType,
    required SyncOperation operation,
    required String entityId,
    Map<String, dynamic>? payload,
  }) async {
    try {
      await op();
    } on PostgrestException catch (e) {
      if (e.code == '401' || e.code == 'JWT expired') {
        rethrow; // Re-throw auth errors
      }
      await _syncQueueService.enqueue(
        entityType: entityType,
        operation: operation,
        entityId: entityId,
        payload: payload,
      );
    } on AuthException catch (_) {
      rethrow; // Re-throw auth errors
    } catch (e) {
      // Catch all other errors (e.g., network, transient) and enqueue
      await _syncQueueService.enqueue(
        entityType: entityType,
        operation: operation,
        entityId: entityId,
        payload: payload,
      );
    }
  }

  // ── Data Mappers ────────────────────────────────────

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
        scheduleDays: (r['schedule_days'] as List?)?.map((e) => e as String).toList(),
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
        'schedule_days': c.scheduleDays,
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
        scheduledAt: _parseDate(r['scheduled_at']),
        durationMinutes: r['duration_minutes'] as int?,
        isCompleted: r['is_completed'] as bool? ?? false,
        completedAt: _parseDate(r['completed_at']),
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
        dueDate: _parseDate(r['due_date']),
        isCompleted: r['is_completed'] as bool? ?? false,
        completedAt: _parseDate(r['completed_at']),
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

  DateTime _parseDate(dynamic v) {
    if (v == null) return DateTime.now();
    return v is String ? DateTime.parse(v) : DateTime.now();
  }

  // ── Direct Supabase interaction (for SyncQueue retry) ────────────────────

  Future<void> _directUpsertCourseToRemote(Course course) async {
    await _supabase.from('courses').upsert(_courseToRow(course));
  }

  Future<void> _directDeleteCourseRemote(String courseId) async {
    await _supabase.from('courses').delete().eq('id', courseId);
  }

  Future<void> _directUpsertLectureToRemote(Lecture lecture) async {
    await _supabase.from('lectures').upsert(_lectureToRow(lecture));
  }

  Future<void> _directDeleteLectureToRemote(String lectureId) async {
    await _supabase.from('lectures').delete().eq('id', lectureId);
  }

  Future<void> _directUpsertAssignmentToRemote(Assignment assignment) async {
    await _supabase.from('assignments').upsert(_assignmentToRow(assignment));
  }

  Future<void> _directDeleteAssignmentToRemote(String assignmentId) async {
    await _supabase.from('assignments').delete().eq('id', assignmentId);
  }
}
