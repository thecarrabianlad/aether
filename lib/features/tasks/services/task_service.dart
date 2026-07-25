import 'package:aether/core/database/database.dart';
import 'package:aether/core/services/supabase_service.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

/// Offline-first tasks data layer.
///
/// The UI always reads from the local Drift database via [watchTasksForDate],
/// so it updates instantly. Mutations write to Drift first (immediate UI
/// reaction) then push to Supabase in the background. [syncTasksForDate]
/// pulls remote data into the local DB for a given day.
class TaskService {
  final AppDatabase _db;
  final _supabase = SupabaseService.instance.client;

  TaskService(this._db);

  String? get _userId => _supabase.auth.currentUser?.id;

  // ── Reads ──────────────────────────────────────────

  /// Tasks for [dateKey] ('YYYY-MM-DD'), scoped to the current user.
  /// Pure stream, no side effects — safe to watch directly from a provider.
  Stream<List<Task>> watchTasksForDate(String dateKey) {
    final userId = _userId;
    if (userId == null) return Stream.value(const []);

    return (_db.select(_db.tasks)
          ..where((t) => t.date.equals(dateKey) & t.userId.equals(userId))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]))
        .watch();
  }

  /// Pulls this user's tasks for [dateKey] from Supabase into Drift.
  /// Call from the widget lifecycle (initState / date change), not from
  /// inside a provider — same pattern as AcademicsService.syncCourses.
  Future<void> syncTasksForDate(String dateKey) async {
    final userId = _userId;
    if (userId == null) return;

    final remote = await _supabase
        .from('tasks')
        .select()
        .eq('user_id', userId)
        .eq('date', dateKey);

    for (final row in remote) {
      await _db.into(_db.tasks).insertOnConflictUpdate(_taskFromRow(row, userId));
    }
  }

  // ── Writes ─────────────────────────────────────────

  Future<Task> createTask({
    required String dateKey,
    required String title,
    required String priority,
    required String category,
    int? durationMinutes,
  }) async {
    final userId = _userId;
    if (userId == null) throw Exception('Not authenticated');

    final now = DateTime.now();
    final task = Task(
      id: const Uuid().v4(),
      userId: userId,
      date: dateKey,
      title: title,
      priority: priority,
      category: category,
      status: 'Pending',
      durationMinutes: durationMinutes,
      createdAt: now,
      updatedAt: now,
    );

    await _db.into(_db.tasks).insert(task);
    await _push(() => _supabase.from('tasks').insert(_taskToRow(task)));
    return task;
  }

  Future<void> updateTaskPriority(String taskId, String priority) =>
      _patch(taskId, TasksCompanion(priority: Value(priority)), {'priority': priority});

  Future<void> updateTaskCategory(String taskId, String category) =>
      _patch(taskId, TasksCompanion(category: Value(category)), {'category': category});

  Future<void> updateTaskStatus(String taskId, String status) =>
      _patch(taskId, TasksCompanion(status: Value(status)), {'status': status});

  Future<void> _patch(
    String taskId,
    TasksCompanion localFields,
    Map<String, dynamic> remoteFields,
  ) async {
    final now = DateTime.now();
    await (_db.update(_db.tasks)..where((t) => t.id.equals(taskId))).write(
      localFields.copyWith(updatedAt: Value(now)),
    );
    await _push(() => _supabase.from('tasks').update({
          ...remoteFields,
          'updated_at': now.toIso8601String(),
        }).eq('id', taskId));
  }

  Future<void> deleteTask(String taskId) async {
    await (_db.delete(_db.tasks)..where((t) => t.id.equals(taskId))).go();
    await _push(() => _supabase.from('tasks').delete().eq('id', taskId));
  }

  // ── Helpers ──────────────────────────────────────────

  /// Runs a remote push, swallowing network errors so the local-first
  /// write still stands (offline-first). Intentionally ignored on failure —
  /// Drift remains source of truth until the next successful sync.
  Future<void> _push(Future<void> Function() op) async {
    try {
      await op();
    } catch (_) {
      // Offline or transient error — ignored, same as AcademicsService.
    }
  }

  Task _taskFromRow(Map<String, dynamic> r, String userId) => Task(
        id: r['id'] as String,
        userId: r['user_id'] as String? ?? userId,
        date: r['date'] as String,
        title: r['title'] as String? ?? '',
        priority: r['priority'] as String? ?? 'Low',
        category: r['category'] as String? ?? 'Other',
        status: r['status'] as String? ?? 'Pending',
        durationMinutes: r['duration_minutes'] as int?,
        createdAt: _parseDate(r['created_at']),
        updatedAt: _parseDate(r['updated_at']),
      );

  Map<String, dynamic> _taskToRow(Task t) => {
        'id': t.id,
        'user_id': t.userId,
        'date': t.date,
        'title': t.title,
        'priority': t.priority,
        'category': t.category,
        'status': t.status,
        'duration_minutes': t.durationMinutes,
        'created_at': t.createdAt.toIso8601String(),
        'updated_at': t.updatedAt.toIso8601String(),
      };

  DateTime _parseDate(dynamic v) =>
      v is String ? DateTime.parse(v) : DateTime.now();
}