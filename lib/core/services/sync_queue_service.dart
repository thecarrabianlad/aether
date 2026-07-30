import 'dart:convert';
import 'package:aether/core/database/database.dart';
import 'package:aether/core/database/model_extensions.dart';
import 'package:aether/core/services/supabase_service.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum SyncOperation { insert, update, delete, upsert }
enum SyncEntityType { course, lecture, assignment, habit, habitLog }

class SyncQueueService {
  final AppDatabase _db;
  final _supabase = SupabaseService.instance.client;

  SyncQueueService(this._db);

  /// Enqueues an operation to be synced later.
  Future<void> enqueue({
    required SyncEntityType entityType,
    required SyncOperation operation,
    required String entityId,
    Map<String, dynamic>? payload,
  }) async {
    final payloadJson = payload != null ? jsonEncode(payload) : null;
    await _db.into(_db.syncQueue).insert(SyncQueueCompanion.insert(
          entityType: entityType.toString().split('.').last,
          operation: operation.toString().split('.').last,
          entityId: entityId,
          payload: Value(payloadJson),
          createdAt: Value(DateTime.now()),
        ));
  }

  /// Processes the sync queue, retrying operations.
  Future<void> processQueue() async {
    final items = await _db.select(_db.syncQueue).get();

    for (final item in items) {
      bool success = false;
      String? errorMessage;
      try {
        final entityType = SyncEntityType.values.firstWhere(
            (e) => e.toString().split('.').last == item.entityType);
        final operation = SyncOperation.values.firstWhere(
            (o) => o.toString().split('.').last == item.operation);
        final payload = item.payload != null
            ? jsonDecode(item.payload!) as Map<String, dynamic>
            : null;

        switch (entityType) {
          case SyncEntityType.course:
            success = await _retryCourseOperation(operation, item.entityId, payload);
            break;
          case SyncEntityType.lecture:
            success = await _retryLectureOperation(operation, item.entityId, payload);
            break;
          case SyncEntityType.assignment:
            success = await _retryAssignmentOperation(operation, item.entityId, payload);
            break;
          case SyncEntityType.habit:
            success = await _retryHabitOperation(operation, item.entityId, payload);
            break;
          case SyncEntityType.habitLog:
            success = await _retryHabitLogOperation(operation, item.entityId, payload);
            break;
        }
      } on PostgrestException catch (e) {
        errorMessage = e.message;
        debugPrint('PostgrestException processing sync queue item ${item.id}: $e');
      } on AuthException catch (e) {
        errorMessage = e.message;
        debugPrint('AuthException processing sync queue item ${item.id}: $e');
      } catch (e, st) {
        errorMessage = e.toString();
        debugPrint('Error processing sync queue item ${item.id}: $e\n$st');
      }

      if (success) {
        await (_db.delete(_db.syncQueue)..where((t) => t.id.equals(item.id))).go();
      } else {
        await _db.customUpdate(
          'UPDATE sync_queue SET retry_count = ?, last_attempt_at = ?, last_error = ? WHERE id = ?',
          variables: [
            Variable.withInt(item.retryCount + 1),
            Variable.withDateTime(DateTime.now()),
            Variable.withString(errorMessage ?? 'Unknown error'),
            Variable.withInt(item.id),
          ],
        );
      }
    }
  }

  // --- Course Retry Operations ---
  Future<bool> _retryCourseOperation(SyncOperation operation, String entityId, Map<String, dynamic>? payload) async {
    if (payload == null) return false;
    final course = CourseExtension.fromJson(payload);
    switch (operation) {
      case SyncOperation.insert:
      case SyncOperation.upsert:
      case SyncOperation.update:
        await _supabase.from('courses').upsert(_courseToRow(course));
        return true;
      case SyncOperation.delete:
        await _supabase.from('courses').delete().eq('id', entityId);
        return true;
    }
  }

  // --- Lecture Retry Operations ---
  Future<bool> _retryLectureOperation(SyncOperation operation, String entityId, Map<String, dynamic>? payload) async {
    if (payload == null) return false;
    final lecture = LectureExtension.fromJson(payload);
    switch (operation) {
      case SyncOperation.insert:
      case SyncOperation.upsert:
      case SyncOperation.update:
        await _supabase.from('lectures').upsert(_lectureToRow(lecture));
        return true;
      case SyncOperation.delete:
        await _supabase.from('lectures').delete().eq('id', entityId);
        return true;
    }
  }

  // --- Assignment Retry Operations ---
  Future<bool> _retryAssignmentOperation(SyncOperation operation, String entityId, Map<String, dynamic>? payload) async {
    if (payload == null) return false;
    final assignment = AssignmentExtension.fromJson(payload);
    switch (operation) {
      case SyncOperation.insert:
      case SyncOperation.upsert:
      case SyncOperation.update:
        await _supabase.from('assignments').upsert(_assignmentToRow(assignment));
        return true;
      case SyncOperation.delete:
        await _supabase.from('assignments').delete().eq('id', entityId);
        return true;
    }
  }

  // --- Habit Retry Operations ---
  Future<bool> _retryHabitOperation(SyncOperation operation, String entityId, Map<String, dynamic>? payload) async {
    if (payload == null) return false;
    final habitEntry = HabitEntryExtension.fromJson(payload);
    switch (operation) {
      case SyncOperation.insert:
      case SyncOperation.upsert:
      case SyncOperation.update:
        await _supabase.from('habits').upsert(_habitToRow(habitEntry));
        return true;
      case SyncOperation.delete:
        await _supabase.from('habits').delete().eq('id', entityId);
        return true;
    }
  }

  // --- HabitLog Retry Operations ---
  Future<bool> _retryHabitLogOperation(SyncOperation operation, String entityId, Map<String, dynamic>? payload) async {
    if (payload == null) return false;
    final habitLog = HabitLogExtension.fromJson(payload);
    switch (operation) {
      case SyncOperation.insert:
      case SyncOperation.upsert:
      case SyncOperation.update:
        await _supabase.from('habit_logs').upsert(_habitLogToRow(habitLog));
        return true;
      case SyncOperation.delete:
        await _supabase.from('habit_logs').delete().eq('id', entityId);
        return true;
    }
  }

  // ── Data Mappers ────────────────────────────────────

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

  Map<String, dynamic> _habitToRow(HabitEntry h) => {
        'id': h.id,
        'user_id': h.userId,
        'name': h.name,
        'category': h.category,
        'icon': h.icon,
        'color': h.color,
        'longest_streak': h.longestStreak,
        'created_at': h.createdAt.toIso8601String(),
        'updated_at': h.updatedAt.toIso8601String(),
        'reminder_time': h.reminderTime,
        'reminder_days': h.reminderDays,
      };

  Map<String, dynamic> _habitLogToRow(HabitLog l) => {
        'id': l.id,
        'habit_id': l.habitId,
        'date': l.date.toIso8601String().split('T').first,
        'is_completed': l.isCompleted,
      };
}
