import 'dart:convert';
import 'package:aether/core/database/database.dart';
import 'package:aether/core/database/model_extensions.dart'; // Import model extensions
import 'package:aether/core/errors/retry.dart';
import 'package:aether/core/services/supabase_service.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum SyncOperation { insert, update, delete, upsert }
enum SyncEntityType { course, lecture, assignment, habit, habitLog, grade }

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

  /// Rows that have failed [poisonedRowThreshold]+ times. These are skipped
  /// by [processQueue] and surfaced in Settings for a Keep-mine / Discard
  /// decision.
  Future<List<SyncQueueEntry>> poisonedRows() async {
    return (_db.select(_db.syncQueue)
          ..where((t) => t.retryCount.isBiggerOrEqualValue(poisonedRowThreshold)))
        .get();
  }

  /// "Keep mine": reset a poisoned row's attempt counter so the processor
  /// retries pushing the local version.
  Future<void> retryPoisonedRow(int id) async {
    await (_db.update(_db.syncQueue)..where((t) => t.id.equals(id))).write(
      const SyncQueueCompanion(retryCount: Value(0), lastError: Value(null)),
    );
  }

  /// "Discard": drop the queued local change entirely (the server version
  /// wins on the next pull).
  Future<void> discardRow(int id) async {
    await (_db.delete(_db.syncQueue)..where((t) => t.id.equals(id))).go();
  }

  /// Processes the sync queue, retrying operations.
  ///
  /// Poisoned rows (>= [poisonedRowThreshold] failures) are skipped —
  /// they never block the rest of the queue and wait for an explicit user
  /// decision in Settings.
  Future<void> processQueue() async {
    final items = await (_db.select(_db.syncQueue)
          ..where((t) => t.retryCount.isSmallerThanValue(poisonedRowThreshold))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();

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
          case SyncEntityType.grade:
            success = await _retryGradeOperation(operation, item.entityId, payload);
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
        await _supabase.from('courses').upsert(course.toSupabaseJson());
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
        await _supabase.from('lectures').upsert(lecture.toSupabaseJson());
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
        await _supabase.from('assignments').upsert(assignment.toSupabaseJson());
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
        await _supabase.from('habits').upsert(habitEntry.toSupabaseJson());
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
        await _supabase.from('habit_logs').upsert(habitLog.toSupabaseJson());
        return true;
      case SyncOperation.delete:
        await _supabase.from('habit_logs').delete().eq('id', entityId);
        return true;
    }
  }

  // --- Grade Retry Operations ---
  Future<bool> _retryGradeOperation(SyncOperation operation, String entityId, Map<String, dynamic>? payload) async {
    if (payload == null) return false;
    final grade = GradeExtension.fromJson(payload);
    switch (operation) {
      case SyncOperation.insert:
      case SyncOperation.upsert:
      case SyncOperation.update:
        await _supabase.from('grades').upsert(grade.toSupabaseJson());
        return true;
      case SyncOperation.delete:
        await _supabase.from('grades').delete().eq('id', entityId);
        return true;
    }
  }
}
