import 'package:aether/core/database/database.dart';
import 'package:aether/core/services/supabase_service.dart';
import 'package:aether/core/services/sync_queue_service.dart';
import 'package:aether/core/services/notification_service.dart';
import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:aether/features/habits/models/habit.dart'; // Import for the Habit model and HabitCategory

/// Offline-first habits data layer.
///
/// The UI always reads from the local Drift database via the `watch*`
/// streams, so it updates instantly. Mutations write to Drift first
/// (immediate UI reaction) then push to Supabase in the background.
/// `sync*` methods pull remote data into the local DB.
///
/// After each local mutation, [NotificationService.scheduleHabitReminder]
/// or [NotificationService.cancelHabitReminders] is called so that
/// reminder notifications stay in sync with the user's habits.
class HabitsService {
  final AppDatabase _db;
  final SyncQueueService _syncQueueService;
  final NotificationService _notificationService;
  final _supabase = SupabaseService.instance.client;

  HabitsService(this._db, this._syncQueueService, this._notificationService);

  String? get _userId => _supabase.auth.currentUser?.id;

  // ── Habits ──────────────────────────────────────────

  Stream<List<HabitEntry>> watchHabits() =>
      (_db.select(_db.habits)..where((h) => h.userId.equals(_userId!))).watch();

  Stream<List<HabitLog>> watchLogsForHabit(String habitId) =>
      (_db.select(_db.habitLogs)..where((l) => l.habitId.equals(habitId))).watch();

  /// Read all habit entries (non-streaming). Used by reschedule-all flows
  /// and by the settings controller when the user toggles notifications.
  Future<List<HabitEntry>> getAllHabitEntries() =>
      _db.select(_db.habits).get();

  Future<void> syncHabits() async {
    final userId = _userId;
    if (userId == null) return;

    final remote = await _supabase.from('habits').select().eq('user_id', userId);
    for (final row in remote) {
      await _db.into(_db.habits).insertOnConflictUpdate(_habitFromRow(row, userId));
    }
  }

  Future<void> syncHabitLogs() async {
    final userId = _userId;
    if (userId == null) return;

    // Fetch logs for all habits belonging to this user
    final habitIds = await (_db.select(_db.habits)
          ..where((h) => h.userId.equals(userId)))
        .map((h) => h.id)
        .get();

    if (habitIds.isEmpty) return;

    // Fetch remote logs for each habit individually to avoid using .in_()
    for (final habitId in habitIds) {
      final remote = await _supabase
          .from('habit_logs')
          .select()
          .eq('habit_id', habitId);
      for (final row in remote) {
        await _db.into(_db.habitLogs).insertOnConflictUpdate(_habitLogFromRow(row));
      }
    }
  }

  Future<void> createHabit({
    required String name,
    required String category,
    required String icon,
    required String color,
    String? reminderTime,
    String? reminderDays,
  }) async {
    final userId = _userId;
    if (userId == null) throw Exception('Not authenticated');

    final now = DateTime.now();
    final id = const Uuid().v4();

    final entry = HabitEntry(
      id: id,
      userId: userId,
      name: name,
      category: category,
      icon: icon,
      color: color,
      longestStreak: 0,
      createdAt: now,
      updatedAt: now,
      reminderTime: reminderTime,
      reminderDays: reminderDays,
    );

    await _db.into(_db.habits).insert(entry);
    await _notificationService.scheduleHabitReminder(entry);
    await _push(
      op: () => _supabase.from('habits').insert(_habitToRow(entry)),
      entityType: SyncEntityType.habit,
      operation: SyncOperation.insert,
      entityId: entry.id,
      payload: _habitToRow(entry),
    );
  }

  Future<void> updateHabit(HabitEntry habit) async {
    final userId = _userId;
    if (userId == null) throw Exception('Not authenticated');

    final updated = habit.copyWith(updatedAt: DateTime.now());
    await (_db.update(_db.habits)..where((h) => h.id.equals(habit.id) & h.userId.equals(userId))).replace(updated);
    await _notificationService.scheduleHabitReminder(updated);
    await _push(
      op: () => _supabase.from('habits').update(_habitToRow(updated)).eq('id', updated.id),
      entityType: SyncEntityType.habit,
      operation: SyncOperation.update,
      entityId: updated.id,
      payload: _habitToRow(updated),
    );
  }

  Future<void> deleteHabit(String habitId) async {
    final userId = _userId;
    if (userId == null) throw Exception('Not authenticated');

    await (_db.delete(_db.habits)..where((h) => h.id.equals(habitId) & h.userId.equals(userId))).go();
    await (_db.delete(_db.habitLogs)..where((l) => l.habitId.equals(habitId))).go(); // Delete associated logs
    await _notificationService.cancelHabitReminders(habitId);
    await _push(
      op: () => _supabase.from('habits').delete().eq('id', habitId),
      entityType: SyncEntityType.habit,
      operation: SyncOperation.delete,
      entityId: habitId,
    );
  }

  // ── Habit Logs ──────────────────────────────────────

  Future<void> toggleCompletion(String habitId, bool completed, {DateTime? date}) async {
    final userId = _userId;
    if (userId == null) throw Exception('Not authenticated');

    final targetDate = _normalizeDate(date ?? DateTime.now());

    // Check for existing log for the target date
    final existingLogs = await (_db.select(_db.habitLogs)
          ..where((l) =>
              l.habitId.equals(habitId) & l.date.equals(targetDate)))
        .get();

    if (existingLogs.isNotEmpty) {
      final existingLog = existingLogs.first;
      await (_db.update(_db.habitLogs)
            ..where((l) => l.id.equals(existingLog.id)))
          .write(HabitLogsCompanion(
        isCompleted: Value(completed),
      ));
    } else {
      final logId = const Uuid().v4();
      await _db.into(_db.habitLogs).insert(HabitLog(
        id: logId,
        habitId: habitId,
        date: targetDate,
        isCompleted: completed,
      ));
    }

    // Update habit's updated_at field
    await (_db.update(_db.habits)..where((h) => h.id.equals(habitId))).write(HabitsCompanion(updatedAt: Value(DateTime.now())));
    // Push log to Supabase
    // Get the log from the local DB after insert/update so it has all fields
    final logRows = await (_db.select(_db.habitLogs)
          ..where((l) =>
              l.habitId.equals(habitId) & l.date.equals(targetDate)))
        .get();

    if (logRows.isNotEmpty) {
      final log = logRows.first;
      await _push(
        op: () => _supabase.from('habit_logs').upsert(_habitLogToRow(log)),
        entityType: SyncEntityType.habitLog,
        operation: SyncOperation.upsert,
        entityId: log.id,
        payload: _habitLogToRow(log),
      );
    }
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

  HabitEntry _habitFromRow(Map<String, dynamic> r, String userId) => HabitEntry(
        id: r['id'] as String,
        userId: r['user_id'] as String? ?? userId,
        name: r['name'] as String? ?? '',
        category: r['category'] as String? ?? HabitCategory.study.name,
        icon: r['icon'] as String? ?? 'menu_book_outlined',
        color: r['color'] as String? ?? '#E8443F',
        longestStreak: r['longest_streak'] as int? ?? 0,
        createdAt: _parseDate(r['created_at']),
        updatedAt: _parseDate(r['updated_at']),
        reminderTime: r['reminder_time'] as String?,
        reminderDays: r['reminder_days'] as String?,
      );

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

  HabitLog _habitLogFromRow(Map<String, dynamic> r) => HabitLog(
        id: r['id'] as String,
        habitId: r['habit_id'] as String,
        date: _parseDate(r['date']),
        isCompleted: r['is_completed'] as bool? ?? false,
      );

  Map<String, dynamic> _habitLogToRow(HabitLog l) => {
        'id': l.id,
        'habit_id': l.habitId,
        'date': l.date.toIso8601String().split('T').first,
        'is_completed': l.isCompleted,
      };

  DateTime _parseDate(dynamic v) => v is String ? DateTime.parse(v) : DateTime.now();

  DateTime _normalizeDate(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  // ── Direct Supabase interaction (for SyncQueue retry) ────────────────────

}
