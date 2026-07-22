import 'package:aether/core/database/database.dart';
import 'package:aether/core/database/tables/courses.dart';
import 'package:aether/core/database/tables/lectures.dart';
import 'package:aether/core/database/tables/assignments.dart';
import 'package:aether/core/services/supabase_service.dart';
import 'package:uuid/uuid.dart';

class AcademicsService {
  final AppDatabase _db;
  final _supabase = SupabaseService.instance.client;

  AcademicsService(this._db);

  // ── Courses ──────────────────────────────────────────

  Future<List<Course>> getCourses() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    // Sync from Supabase to local
    final remote = await _supabase
        .from('courses')
        .select()
        .eq('user_id', userId);

    for (final row in remote) {
      final exists = await (_db.select(_db.courses)
            ..where((t) => t.id.equals(row['id'])))
          .getSingleOrNull();
      if (exists != null) {
        await _db.update(_db.courses).replace(Course(
          id: row['id'],
          userId: row['userId'],
          name: row['name'],
          code: row['code'],
          professor: row['professor'],
          color: row['color'],
          icon: row['icon'],
          semester: row['semester'],
          location: row['location'],
          credits: row['credits'],
          scheduleDays: row['scheduleDays'] is List
              ? (row['scheduleDays'] as List).join(',')
              : row['scheduleDays'],
          scheduleStart: row['scheduleStart'],
          scheduleEnd: row['scheduleEnd'],
          createdAt: DateTime.parse(row['createdAt']),
          updatedAt: DateTime.parse(row['updatedAt']),
        ));
      } else {
        await _db.into(_db.courses).insert(Course(
          id: row['id'],
          userId: row['userId'],
          name: row['name'],
          code: row['code'],
          professor: row['professor'],
          color: row['color'],
          icon: row['icon'],
          semester: row['semester'],
          location: row['location'],
          credits: row['credits'],
          scheduleDays: row['scheduleDays'] is List
              ? (row['scheduleDays'] as List).join(',')
              : row['scheduleDays'],
          scheduleStart: row['scheduleStart'],
          scheduleEnd: row['scheduleEnd'],
          createdAt: DateTime.parse(row['createdAt']),
          updatedAt: DateTime.parse(row['updatedAt']),
        ));
      }
    }

    return _db.select(_db.courses).get();
  }

  Stream<List<Course>> watchCourses() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return Stream.value([]);
    return (_db.select(_db.courses).watch());
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
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final id = const Uuid().v4();
    final now = DateTime.now();

    // Insert into Supabase
    await _supabase.from('courses').insert({
      'id': id,
      'userId': userId,
      'name': name,
      'code': code,
      'professor': professor,
      'color': color ?? '#8B5CF6',
      'icon': icon,
      'semester': semester,
      'location': location,
      'credits': credits,
      'scheduleDays': scheduleDays?.split(',').map((s) => s.trim()).toList(),
      'scheduleStart': scheduleStart,
      'scheduleEnd': scheduleEnd,
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
    });

    // Insert locally
    return _db.into(_db.courses).insertReturning(Course(
      id: id,
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
      createdAt: now,
      updatedAt: now,
    ));
  }

  Future<void> deleteCourse(String courseId) async {
    await _supabase.from('courses').delete().eq('id', courseId);
    await (_db.delete(_db.courses)..where((t) => t.id.equals(courseId))).go();
  }

  Future<void> updateCourse(Course course) async {
    final now = DateTime.now();
    await _supabase.from('courses').update({
      'name': course.name,
      'code': course.code,
      'professor': course.professor,
      'color': course.color,
      'icon': course.icon,
      'semester': course.semester,
      'location': course.location,
      'credits': course.credits,
      'scheduleDays': course.scheduleDays?.split(',').map((s) => s.trim()).toList(),
      'scheduleStart': course.scheduleStart,
      'scheduleEnd': course.scheduleEnd,
      'updatedAt': now.toIso8601String(),
    }).eq('id', course.id);

    await _db.update(_db.courses).replace(course.copyWith(updatedAt: now));
  }

  // ── Lectures ---------
  Future<List<Lecture>> getLectures({
    String? courseId,
    bool? today,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    var query = _supabase.from('lectures').select().eq('userId', userId);
    if (courseId != null) query = query.eq('courseId', courseId);
    if (today == true) {
      final start = DateTime.now().toUtc().copyWith(hour: 0, minute: 0);
      final end = start.add(const Duration(days: 1));
      query = query.gte('scheduledAt', start.toIso8601String()).lt('scheduledAt', end.toIso8601String());
    }

    final remote = await query.order('scheduledAt', ascending: true);
    final lectures = remote.map<Lecture>((row) => Lecture(
      id: row['id'],
      courseId: row['courseId'],
      userId: row['userId'],
      title: row['title'],
      chapter: row['chapter'],
      tag: row['tag'],
      scheduledAt: row['scheduledAt'] != null ? DateTime.parse(row['scheduledAt']) : null,
      durationMinutes: row['durationMinutes'],
      isCompleted: row['isCompleted'],
      completedAt: row['completedAt'] != null ? DateTime.parse(row['completedAt']) : null,
      createdAt: DateTime.parse(row['createdAt']),
      updatedAt: DateTime.parse(row['updatedAt']),
    )).toList();

    // Sync to local
    for (final lec in lectures) {
      final exists = await _db.select(_db.lectures).getSingleOrNull();
      if (exists != null) {
        await _db.update(_db.lectures).replace(lec);
      } else {
        await _db.into(_db.lectures).insert(lec);
      }
    }

    return lectures;
  }

  Future<void> toggleLectureCompletion(String lectureId, bool completed) async {
    final now = DateTime.now();
    await _supabase.from('lectures').update({
      'isCompleted': completed,
      'completedAt': completed ? now.toIso8601String() : null,
      'updatedAt': now.toIso8601String(),
    }).eq('id', lectureId);

    await (_db.update(_db.lectures)
      ..where((l) => l.id.equals(lectureId)))
      .write(LecturesCompanion(
        isCompleted: Value(completed),
        completedAt: Value(completed ? now : null),
        updatedAt: Value(now),
      ));
  }

  // ── Assignments ──
  Future<List<Assignment>> watchAssignments({
    String? courseId,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    var query = _supabase.from('assignments').select().eq('userId', userId);
    if (courseId != null) query = query.eq('courseId', courseId);

    final remote = await query.from_list(/* ... */) as List<Map<String, dynamic>>;

    final assignments = remote.map((row) => Assignment(
      id: row['id'],
      courseId: row['courseId'],
      userId: row['userId'],
      title: row['title'],
      description: row['description'],
      dueDate: row['dueDate'] != null ? DateTime.parse(row['dueDate']) : null,
      isCompleted: row['isCompleted'],
      completedAt: row['completedAt'] != null ? DateTime.parse(row['completedAt']) : null,
      createdAt: DateTime.parse(row['createdAt']),
      updatedAt: DateTime.parse(row['updatedAt']),
    )).toList();

    // Sync to local
    for (final a in assignments) {
      final exists = await _db.select(_db.assignments).where((a) => a.id).getSingleOrNull();
      if (exists != null) {
        await _db.update(_db.assignments).replace(a);
      } else {
        await _db.into(_db.assignments).insert(a);
      }
    }

    return assignments;
  }

  Future<void> toggleAssignmentCompletion(String assignmentId, bool completed) async {
    final now = DateTime.now();
    await _supabase.from('assignments').update({
      'isCompleted': completed,
      'completedAt': completed ? now.toIso8601String() : null,
      'updatedAt': now.toIso8601String(),
    }).eq('id', assignmentId);

    await (_db.update(_db.assignments)
      ..where((a) => a.id.equals(assignmentId)))
      .write(AssignmentsCompanion(
        isCompleted: Value(completed),
        completedAt: Value(completed ? now : null),
        updatedAt: Value(now),
      ));
  }
}