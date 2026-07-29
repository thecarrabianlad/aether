import 'package:aether/core/database/database.dart';
import 'package:aether/core/services/supabase_service.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

/// Offline-first pomodoro session data layer.
class PomodoroService {
  final AppDatabase _db;
  final _supabase = SupabaseService.instance.client;

  PomodoroService(this._db);

  String? get _userId => _supabase.auth.currentUser?.id;

  // ── Reads ──────────────────────────────────────────

  Stream<List<PomodoroSession>> watchTodaySessions() {
    final userId = _userId;
    if (userId == null) return Stream.value(const []);
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return (_db.select(_db.pomodoroSessions)
          ..where((s) =>
              s.userId.equals(userId) &
              s.startedAt.isBiggerOrEqualValue(startOfDay) &
              s.startedAt.isSmallerThanValue(endOfDay))
          ..orderBy([(s) => OrderingTerm.desc(s.startedAt)]))
        .watch();
  }

  Stream<List<PomodoroSession>> watchRecentSessions({int limit = 20}) {
    final userId = _userId;
    if (userId == null) return Stream.value(const []);
    return (_db.select(_db.pomodoroSessions)
          ..where((s) => s.userId.equals(userId))
          ..orderBy([(s) => OrderingTerm.desc(s.startedAt)])
          ..limit(limit))
        .watch();
  }

  Future<void> syncSessions() async {
    final userId = _userId;
    if (userId == null) return;
    final remote =
        await _supabase.from('pomodoro_sessions').select().eq('user_id', userId);
    for (final row in remote) {
      await _db
          .into(_db.pomodoroSessions)
          .insertOnConflictUpdate(_sessionFromRow(row, userId));
    }
  }

  // ── Writes ─────────────────────────────────────────

  Future<PomodoroSession> startSession({
    required int plannedMinutes,
    String? taskId,
  }) async {
    final userId = _userId;
    if (userId == null) throw Exception('Not authenticated');

    final session = PomodoroSession(
      id: const Uuid().v4(),
      userId: userId,
      taskId: taskId,
      startedAt: DateTime.now(),
      plannedMinutes: plannedMinutes,
      completed: false,
    );

    await _db.into(_db.pomodoroSessions).insert(session);
    await _push(() => _supabase.from('pomodoro_sessions').insert(_sessionToRow(session)));
    return session;
  }

  Future<void> finishSession(String sessionId, {required bool completed}) async {
    final now = DateTime.now();
    final session = await (_db.select(_db.pomodoroSessions)
          ..where((s) => s.id.equals(sessionId)))
        .getSingleOrNull();
    if (session == null) return;
    final actualMinutes = now.difference(session.startedAt).inMinutes;

    final updated = session.copyWith(
      endedAt: Value(now), // uses Value<DateTime?> — correct for copyWith
      actualMinutes: Value(actualMinutes),
      completed: completed,
    );

    await (_db.update(_db.pomodoroSessions)..where((s) => s.id.equals(sessionId)))
        .replace(updated);
    await _push(() => _supabase.from('pomodoro_sessions').update({
          ..._sessionToRow(updated),
          'ended_at': now.toIso8601String(),
          'actual_minutes': actualMinutes,
          'completed': completed,
        }).eq('id', sessionId));
  }

  Future<void> deleteSession(String sessionId) async {
    await (_db.delete(_db.pomodoroSessions)..where((s) => s.id.equals(sessionId))).go();
    await _push(() => _supabase.from('pomodoro_sessions').delete().eq('id', sessionId));
  }

  // ── Helpers ──────────────────────────────────────────

  Future<void> _push(Future<void> Function() op) async {
    try {
      await op();
    } catch (_) {
      // Offline-first: ignore transient errors.
    }
  }

  PomodoroSession _sessionFromRow(Map<String, dynamic> r, String userId) =>
      PomodoroSession(
        id: r['id'] as String,
        userId: r['user_id'] as String? ?? userId,
        taskId: r['task_id'] as String?,
        startedAt: _parseDate(r['started_at']),
        endedAt: r['ended_at'] != null ? DateTime.parse(r['ended_at'] as String) : null,
        plannedMinutes: r['planned_minutes'] as int? ?? 25,
        actualMinutes: r['actual_minutes'] as int?,
        completed: r['completed'] as bool? ?? false,
      );

  Map<String, dynamic> _sessionToRow(PomodoroSession s) => {
        'id': s.id,
        'user_id': s.userId,
        'task_id': s.taskId,
        'started_at': s.startedAt.toIso8601String(),
        'ended_at': s.endedAt?.toIso8601String(),
        'planned_minutes': s.plannedMinutes,
        'actual_minutes': s.actualMinutes,
        'completed': s.completed,
      };

  DateTime _parseDate(dynamic v) =>
      v is String ? DateTime.parse(v) : DateTime.now();
}
