import 'package:aether/core/database/database.dart';
import 'package:aether/core/services/supabase_service.dart';
import 'package:aether/core/services/sync_queue_service.dart';
import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:aether/core/database/model_extensions.dart'; // Import model extensions

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
      await _db.into(_db.courses).insertOnConflictUpdate(CourseExtension.fromJson(row));
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
      op: () => _supabase.from('courses').upsert(course.toSupabaseJson()),
      entityType: SyncEntityType.course,
      operation: SyncOperation.insert,
      entityId: course.id,
      payload: course.toSupabaseJson(),
    );
    return course;
  }

  /// Immediately pushes an operation to Supabase, or enqueues it if it fails.
  Future<void> _push({
    required Future<void> Function() op,
    required SyncEntityType entityType,
    required SyncOperation operation,
    required String entityId,
    Map<String, dynamic>? payload,
  }) async {
    try {
      await op();
    } catch (e) {
      // If the direct push fails (e.g., network error), enqueue it for later.
      await _syncQueueService.enqueue(
        entityType: entityType,
        operation: operation,
        entityId: entityId,
        payload: payload,
      );
    }
  }

  Future<void> updateCourse(Course course) async {
    final updated = course.copyWith(updatedAt: DateTime.now());
    await _db.update(_db.courses).replace(updated);
    await _push(
      op: () => _supabase.from('courses').update(updated.toSupabaseJson()).eq('id', updated.id),
      entityType: SyncEntityType.course,
      operation: SyncOperation.update,
      entityId: updated.id,
      payload: updated.toSupabaseJson(),
    );
  }

  Future<void> deleteCourse(String courseId) async {
    await (_db.delete(_db.courses)..where((c) => c.id.equals(courseId))).go();
    await (_db.delete(_db.lectures)..where((l) => l.courseId.equals(courseId))).go();
    await (_db.delete(_db.assignments)..where((a) => a.courseId.equals(courseId))).go();
    await (_db.delete(_db.grades)..where((g) => g.courseId.equals(courseId))).go(); // Also delete grades for the course
    await _push(
      op: () => _supabase.from('courses').delete().eq('id', courseId),
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
      await _db.into(_db.lectures).insertOnConflictUpdate(LectureExtension.fromJson(row));
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
      durationMinutes: durationMinutes ?? 90,
      isCompleted: isCompleted ?? false,
      completedAt: completedAt,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _db.into(_db.lectures).insert(lecture);
    await _push(
      op: () => _supabase.from('lectures').upsert(lecture.toSupabaseJson()),
      entityType: SyncEntityType.lecture,
      operation: SyncOperation.insert,
      entityId: lecture.id,
      payload: lecture.toSupabaseJson(),
    );
    return lecture;
  }

  Future<void> updateLecture(Lecture lecture) async {
    final updated = lecture.copyWith(updatedAt: DateTime.now());
    await _db.update(_db.lectures).replace(updated);
    await _push(
      op: () => _supabase.from('lectures').update(updated.toSupabaseJson()).eq('id', updated.id),
      entityType: SyncEntityType.lecture,
      operation: SyncOperation.update,
      entityId: updated.id,
      payload: updated.toSupabaseJson(),
    );
  }

  Future<void> deleteLecture(String lectureId) async {
    await (_db.delete(_db.lectures)..where((l) => l.id.equals(lectureId))).go();
    await _push(
      op: () => _supabase.from('lectures').delete().eq('id', lectureId),
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
      await _db.into(_db.assignments).insertOnConflictUpdate(AssignmentExtension.fromJson(row));
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
      op: () => _supabase.from('assignments').upsert(assignment.toSupabaseJson()),
      entityType: SyncEntityType.assignment,
      operation: SyncOperation.insert,
      entityId: assignment.id,
      payload: assignment.toSupabaseJson(),
    );
    return assignment;
  }

  Future<void> updateAssignment(Assignment assignment) async {
    final updated = assignment.copyWith(updatedAt: DateTime.now());
    await _db.update(_db.assignments).replace(updated);
    await _push(
      op: () => _supabase.from('assignments').update(updated.toSupabaseJson()).eq('id', updated.id),
      entityType: SyncEntityType.assignment,
      operation: SyncOperation.update,
      entityId: updated.id,
      payload: updated.toSupabaseJson(),
    );
  }

  Future<void> deleteAssignment(String assignmentId) async {
    await (_db.delete(_db.assignments)..where((a) => a.id.equals(assignmentId))).go();
    await _push(
      op: () => _supabase.from('assignments').delete().eq('id', assignmentId),
      entityType: SyncEntityType.assignment,
      operation: SyncOperation.delete,
      entityId: assignmentId,
    );
  }

  // ── Grades ──────────────────────────────────────────

  Stream<List<Grade>> watchGrades(String courseId) =>
      (_db.select(_db.grades)..where((g) => g.courseId.equals(courseId)))
          .watch();

  Future<void> syncGrades({String? courseId}) async {
    final userId = _userId;
    if (userId == null) return;

    PostgrestFilterBuilder query = _supabase.from('grades').select();
    if (courseId != null) {
      query = query.eq('course_id', courseId);
    } else {
      query = query.eq('user_id', userId);
    }
    final remote = await query;
    for (final row in remote) {
      await _db.into(_db.grades).insertOnConflictUpdate(GradeExtension.fromJson(row));
    }
  }

  Future<Grade> createGrade({
    String? id,
    required String courseId,
    required String title,
    double? gradeValue,
    double? totalPoints,
    double? weight,
    String? feedback,
    DateTime? gradedAt,
  }) async {
    final userId = _userId;
    if (userId == null) throw Exception('Not authenticated');

    final grade = Grade(
      id: id ?? const Uuid().v4(),
      courseId: courseId,
      userId: userId,
      title: title,
      gradeValue: gradeValue,
      totalPoints: totalPoints,
      weight: weight ?? 1.0,
      feedback: feedback,
      gradedAt: gradedAt,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _db.into(_db.grades).insert(grade);
    await _push(
      op: () => _supabase.from('grades').upsert(grade.toSupabaseJson()),
      entityType: SyncEntityType.grade,
      operation: SyncOperation.insert,
      entityId: grade.id,
      payload: grade.toSupabaseJson(),
    );
    return grade;
  }

  Future<void> updateGrade(Grade grade) async {
    final updated = grade.copyWith(updatedAt: DateTime.now());
    await _db.update(_db.grades).replace(updated);
    await _push(
      op: () => _supabase.from('grades').update(updated.toSupabaseJson()).eq('id', updated.id),
      entityType: SyncEntityType.grade,
      operation: SyncOperation.update,
      entityId: updated.id,
      payload: updated.toSupabaseJson(),
    );
  }

  Future<void> deleteGrade(String gradeId) async {
    await (_db.delete(_db.grades)..where((g) => g.id.equals(gradeId))).go();
    await _push(
      op: () => _supabase.from('grades').delete().eq('id', gradeId),
      entityType: SyncEntityType.grade,
      operation: SyncOperation.delete,
      entityId: gradeId,
    );
  }

  // ── Completion Toggles ─────────────────────────────────

  Future<void> toggleLectureCompletion(String lectureId, bool completed) async {
    final lecture = await (_db.select(_db.lectures)..where((l) => l.id.equals(lectureId))).getSingle();
    await (_db.update(_db.lectures)..where((l) => l.id.equals(lectureId))).write(
      LecturesCompanion(
        isCompleted: Value(completed),
        completedAt: Value(completed ? DateTime.now() : null),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> toggleAssignmentCompletion(String assignmentId, bool completed) async {
    await (_db.update(_db.assignments)..where((a) => a.id.equals(assignmentId))).write(
      AssignmentsCompanion(
        isCompleted: Value(completed),
        completedAt: Value(completed ? DateTime.now() : null),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
