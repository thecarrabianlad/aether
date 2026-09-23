import 'package:aether/core/database/database.dart';
import 'package:aether/core/services/supabase_service.dart';
import 'package:aether/core/services/sync_queue_service.dart';
import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Offline-first health (workout plan) data layer.
///
/// The UI always reads from the local Drift database via [watchExercises] /
/// [watchAllExercises], so it updates instantly. Mutations write to Drift
/// first (immediate UI reaction) then push to Supabase in the background.
/// [syncExercises] pulls remote data into the local DB. This mirrors
/// [AcademicsService] / [HabitsService].
class HealthService {
  final AppDatabase _db;
  final SyncQueueService _syncQueueService;
  final _supabase = SupabaseService.instance.client;

  HealthService(this._db, this._syncQueueService);

  String? get _userId => _supabase.auth.currentUser?.id;

  // ── Exercises ──────────────────────────────────────────

  /// All exercises for a single weekday (1 = Monday .. 7 = Sunday).
  Stream<List<WorkoutExercise>> watchExercises(int weekday) =>
      (_db.select(_db.workoutExercises)
            ..where((e) => e.userId.equals(_userId!) & e.weekday.equals(weekday)))
          .watch();

  /// Every exercise across the whole week — used for the weekly summary strip.
  Stream<List<WorkoutExercise>> watchAllExercises() =>
      (_db.select(_db.workoutExercises)..where((e) => e.userId.equals(_userId!)))
          .watch();

  Future<void> syncExercises() async {
    final userId = _userId;
    if (userId == null) return;

    final remote = await _supabase.from('workout_exercises').select().eq('user_id', userId);
    for (final row in remote) {
      await _db.into(_db.workoutExercises).insertOnConflictUpdate(_exerciseFromRow(row, userId));
    }
  }

  Future<WorkoutExercise> createExercise({
    String? id,
    required int weekday,
    required String name,
    required String type, // 'reps' | 'timed'
    required String setsJson,
    bool isCompleted = false,
  }) async {
    final userId = _userId;
    if (userId == null) throw Exception('Not authenticated');

    final exercise = WorkoutExercise(
      id: id ?? const Uuid().v4(),
      userId: userId,
      weekday: weekday,
      name: name,
      type: type,
      setsJson: setsJson,
      isCompleted: isCompleted,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _db.into(_db.workoutExercises).insert(exercise);
    await _push(
      op: () => _supabase.from('workout_exercises').upsert(_exerciseToRow(exercise)),
      entityType: SyncEntityType.workoutExercise,
      operation: SyncOperation.insert,
      entityId: exercise.id,
      payload: _exerciseToRow(exercise),
    );
    return exercise;
  }

  /// Updates an existing exercise's editable fields. Only the columns the
  /// UI can actually change are touched (a partial write via Companion),
  /// so userId/createdAt on the stored row are never clobbered.
  Future<void> updateExercise({
    required String id,
    required int weekday,
    required String name,
    required String type,
    required String setsJson,
    bool? isCompleted,
  }) async {
    await (_db.update(_db.workoutExercises)..where((e) => e.id.equals(id))).write(
      WorkoutExercisesCompanion(
        weekday: Value(weekday),
        name: Value(name),
        type: Value(type),
        setsJson: Value(setsJson),
        isCompleted: isCompleted != null ? Value(isCompleted) : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      ),
    );

    final row = await (_db.select(_db.workoutExercises)..where((e) => e.id.equals(id))).getSingleOrNull();
    if (row == null) return;
    await _push(
      op: () => _supabase.from('workout_exercises').update(_exerciseToRow(row)).eq('id', row.id),
      entityType: SyncEntityType.workoutExercise,
      operation: SyncOperation.update,
      entityId: row.id,
      payload: _exerciseToRow(row),
    );
  }

  Future<void> deleteExercise(String exerciseId) async {
    await (_db.delete(_db.workoutExercises)..where((e) => e.id.equals(exerciseId))).go();
    await _push(
      op: () => _supabase.from('workout_exercises').delete().eq('id', exerciseId),
      entityType: SyncEntityType.workoutExercise,
      operation: SyncOperation.delete,
      entityId: exerciseId,
    );
  }

  Future<void> toggleCompletion(String exerciseId, bool completed) async {
    await (_db.update(_db.workoutExercises)..where((e) => e.id.equals(exerciseId))).write(
      WorkoutExercisesCompanion(
        isCompleted: Value(completed),
        updatedAt: Value(DateTime.now()),
      ),
    );

    final row = await (_db.select(_db.workoutExercises)..where((e) => e.id.equals(exerciseId))).getSingleOrNull();
    if (row == null) return;
    await _push(
      op: () => _supabase.from('workout_exercises').update(_exerciseToRow(row)).eq('id', row.id),
      entityType: SyncEntityType.workoutExercise,
      operation: SyncOperation.update,
      entityId: row.id,
      payload: _exerciseToRow(row),
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

  WorkoutExercise _exerciseFromRow(Map<String, dynamic> r, String userId) => WorkoutExercise(
        id: r['id'] as String,
        userId: r['user_id'] as String? ?? userId,
        weekday: r['weekday'] as int,
        name: r['name'] as String? ?? '',
        type: r['type'] as String? ?? 'reps',
        setsJson: r['sets_json'] as String? ?? '[]',
        isCompleted: r['is_completed'] as bool? ?? false,
        createdAt: _parseDate(r['created_at']),
        updatedAt: _parseDate(r['updated_at']),
      );

  Map<String, dynamic> _exerciseToRow(WorkoutExercise e) => {
        'id': e.id,
        'user_id': e.userId,
        'weekday': e.weekday,
        'name': e.name,
        'type': e.type,
        'sets_json': e.setsJson,
        'is_completed': e.isCompleted,
        'created_at': e.createdAt.toIso8601String(),
        'updated_at': e.updatedAt.toIso8601String(),
      };

  DateTime _parseDate(dynamic v) {
    if (v == null) return DateTime.now();
    return v is String ? DateTime.parse(v) : DateTime.now();
  }
}
