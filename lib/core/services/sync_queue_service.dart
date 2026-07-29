import 'dart:convert';
import 'package:aether/core/database/database.dart';
import 'package:aether/core/services/academics_service.dart';
import 'package:aether/features/habits/services/habits_service.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

enum SyncOperation { insert, update, delete, upsert } // Added upsert
enum SyncEntityType { course, lecture, assignment, habit, habitLog }

class SyncQueueService {
  final AppDatabase _db;
  final AcademicsService Function() _academicsServiceProvider; // Lazy provider
  final HabitsService Function() _habitsServiceProvider; // Lazy provider

  SyncQueueService(
    this._db,
    this._academicsServiceProvider,
    this._habitsServiceProvider,
  );

  // Lazy getters for services
  AcademicsService get _academicsService => _academicsServiceProvider();
  HabitsService get _habitsService => _habitsServiceProvider();

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
      } catch (e, st) {
        errorMessage = e.toString();
        // Log the error and stack trace for debugging
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

  // --- Academics Retry Operations ---
  Future<bool> _retryCourseOperation(SyncOperation operation, String entityId, Map<String, dynamic>? payload) async {
    if (payload == null) return false;
    final course = Course.fromJson(payload); // fromJson now exists
    switch (operation) {
      case SyncOperation.insert:
      case SyncOperation.upsert:
      case SyncOperation.update:
        await _academicsService._directUpsertCourseToRemote(course);
        return true;
      case SyncOperation.delete:
        await _academicsService._directDeleteCourseToRemote(entityId);
        return true;
    }
  }

  Future<bool> _retryLectureOperation(SyncOperation operation, String entityId, Map<String, dynamic>? payload) async {
    if (payload == null) return false;
    final lecture = Lecture.fromJson(payload); // fromJson now exists
    switch (operation) {
      case SyncOperation.insert:
      case SyncOperation.upsert:
      case SyncOperation.update:
        await _academicsService._directUpsertLectureToRemote(lecture);
        return true;
      case SyncOperation.delete:
        await _academicsService._directDeleteLectureToRemote(entityId);
        return true;
    }
  }

  Future<bool> _retryAssignmentOperation(SyncOperation operation, String entityId, Map<String, dynamic>? payload) async {
    if (payload == null) return false;
    final assignment = Assignment.fromJson(payload); // fromJson now exists
    switch (operation) {
      case SyncOperation.insert:
      case SyncOperation.upsert:
      case SyncOperation.update:
        await _academicsService._directUpsertAssignmentToRemote(assignment);
        return true;
      case SyncOperation.delete:
        await _academicsService._directDeleteAssignmentToRemote(entityId);
        return true;
    }
  }

  // --- Habits Retry Operations ---
  Future<bool> _retryHabitOperation(SyncOperation operation, String entityId, Map<String, dynamic>? payload) async {
    if (payload == null) return false;
    // HabitEntry.fromJson needs to be added (from database.g.dart)
    final habitEntry = HabitEntry.fromJson(payload);
    switch (operation) {
      case SyncOperation.insert:
      case SyncOperation.upsert:
      case SyncOperation.update:
        await _habitsService.createHabit(
          id: habitEntry.id, // Ensure ID is passed for upsert
          name: habitEntry.name,
          category: habitEntry.category,
          icon: habitEntry.icon,
          color: habitEntry.color,
          reminderTime: habitEntry.reminderTime,
          reminderDays: habitEntry.reminderDays,
        );
        return true;
      case SyncOperation.delete:
        await _habitsService.deleteHabit(entityId);
        return true;
    }
  }

  Future<bool> _retryHabitLogOperation(SyncOperation operation, String entityId, Map<String, dynamic>? payload) async {
    if (payload == null) return false;
    // HabitLog.fromJson needs to be added (from database.g.dart)
    final habitLog = HabitLog.fromJson(payload);
    switch (operation) {
      case SyncOperation.insert:
      case SyncOperation.upsert:
      case SyncOperation.update:
        // toggleCompletion handles both insert and update based on existence
        await _habitsService.toggleCompletion(habitLog.habitId, habitLog.isCompleted);
        return true;
      case SyncOperation.delete:
        // There's no direct deleteHabitLog method, usually deleted with habit
        return false; // Not supported directly via queue currently
    }
  }
}
