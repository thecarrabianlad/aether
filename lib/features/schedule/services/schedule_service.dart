import 'package:aether/core/database/database.dart';
import 'package:aether/core/services/supabase_service.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

/// Offline-first schedule data layer (templates + their time blocks).
///
/// The UI always reads from Drift via the `watch*` streams, so it updates
/// instantly. Mutations write to Drift first (immediate UI reaction) then
/// push to Supabase in the background. `sync*` methods pull remote data
/// into the local DB. Same pattern as AcademicsService / TaskService.
class ScheduleService {
  final AppDatabase _db;
  final _supabase = SupabaseService.instance.client;

  ScheduleService(this._db);

  String? get _userId => _supabase.auth.currentUser?.id;

  // ── Templates ──────────────────────────────────────

  Stream<List<ScheduleTemplate>> watchTemplates() {
    final userId = _userId;
    if (userId == null) return Stream.value(const []);

    return (_db.select(_db.scheduleTemplates)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]))
        .watch();
  }

  Future<void> syncTemplates() async {
    final userId = _userId;
    if (userId == null) return;

    final remote = await _supabase
        .from('schedule_templates')
        .select()
        .eq('user_id', userId);

    for (final row in remote) {
      await _db
          .into(_db.scheduleTemplates)
          .insertOnConflictUpdate(_templateFromRow(row, userId));
    }
  }

  Future<ScheduleTemplate> createTemplate({
    required String title,
    required String icon,
    List<int> repeatDays = const [],
  }) async {
    final userId = _userId;
    if (userId == null) throw Exception('Not authenticated');

    final now = DateTime.now();
    final template = ScheduleTemplate(
      id: const Uuid().v4(),
      userId: userId,
      title: title,
      icon: icon,
      repeatDays: repeatDays.join(','),
      createdAt: now,
      updatedAt: now,
    );

    await _db.into(_db.scheduleTemplates).insert(template);
    await _push(() => _supabase
        .from('schedule_templates')
        .insert(_templateToRow(template)));
    return template;
  }

  Future<void> updateTemplateRepeatDays(
    String templateId,
    List<int> repeatDays,
  ) async {
    final now = DateTime.now();
    final value = repeatDays.join(',');
    await (_db.update(_db.scheduleTemplates)
          ..where((t) => t.id.equals(templateId)))
        .write(ScheduleTemplatesCompanion(
      repeatDays: Value(value),
      updatedAt: Value(now),
    ));
    await _push(() => _supabase.from('schedule_templates').update({
          'repeat_days': value,
          'updated_at': now.toIso8601String(),
        }).eq('id', templateId));
  }

  // ── Blocks ─────────────────────────────────────────

  Stream<List<ScheduleBlock>> watchBlocks(String templateId) {
    final userId = _userId;
    if (userId == null || templateId.isEmpty) return Stream.value(const []);

    return (_db.select(_db.scheduleBlocks)
          ..where(
            (b) => b.templateId.equals(templateId) & b.userId.equals(userId),
          )
          ..orderBy([(b) => OrderingTerm(expression: b.startTime)]))
        .watch();
  }

  Future<void> syncBlocks(String templateId) async {
    final userId = _userId;
    if (userId == null || templateId.isEmpty) return;

    final remote = await _supabase
        .from('schedule_blocks')
        .select()
        .eq('user_id', userId)
        .eq('template_id', templateId);

    for (final row in remote) {
      await _db
          .into(_db.scheduleBlocks)
          .insertOnConflictUpdate(_blockFromRow(row, userId));
    }
  }

  Future<ScheduleBlock> createBlock({
    required String templateId,
    required String title,
    required String startTime,
    required String endTime,
    required String color,
    required String icon,
  }) async {
    final userId = _userId;
    if (userId == null) throw Exception('Not authenticated');

    final now = DateTime.now();
    final block = ScheduleBlock(
      id: const Uuid().v4(),
      userId: userId,
      templateId: templateId,
      title: title,
      startTime: startTime,
      endTime: endTime,
      color: color,
      icon: icon,
      createdAt: now,
      updatedAt: now,
    );

    await _db.into(_db.scheduleBlocks).insert(block);
    await _push(
      () => _supabase.from('schedule_blocks').insert(_blockToRow(block)),
    );
    return block;
  }

  Future<void> updateBlock(
    String blockId, {
    required String title,
    required String startTime,
    required String endTime,
    required String color,
    required String icon,
  }) async {
    final now = DateTime.now();
    await (_db.update(_db.scheduleBlocks)..where((b) => b.id.equals(blockId)))
        .write(ScheduleBlocksCompanion(
      title: Value(title),
      startTime: Value(startTime),
      endTime: Value(endTime),
      color: Value(color),
      icon: Value(icon),
      updatedAt: Value(now),
    ));
    await _push(() => _supabase.from('schedule_blocks').update({
          'title': title,
          'start_time': startTime,
          'end_time': endTime,
          'color': color,
          'icon': icon,
          'updated_at': now.toIso8601String(),
        }).eq('id', blockId));
  }

  Future<void> deleteBlock(String blockId) async {
    await (_db.delete(_db.scheduleBlocks)..where((b) => b.id.equals(blockId)))
        .go();
    await _push(
      () => _supabase.from('schedule_blocks').delete().eq('id', blockId),
    );
  }

  // ── Helpers ──────────────────────────────────────────

  /// Runs a remote push, swallowing network errors so the local-first
  /// write still stands (offline-first). Drift remains source of truth
  /// until the next successful sync — same as AcademicsService/TaskService.
  Future<void> _push(Future<void> Function() op) async {
    try {
      await op();
    } catch (_) {
      // Offline or transient error — intentionally ignored.
    }
  }

  ScheduleTemplate _templateFromRow(Map<String, dynamic> r, String userId) =>
      ScheduleTemplate(
        id: r['id'] as String,
        userId: r['user_id'] as String? ?? userId,
        title: r['title'] as String? ?? '',
        icon: r['icon'] as String? ?? 'other',
        repeatDays: r['repeat_days'] as String? ?? '',
        createdAt: _parseDate(r['created_at']),
        updatedAt: _parseDate(r['updated_at']),
      );

  Map<String, dynamic> _templateToRow(ScheduleTemplate t) => {
        'id': t.id,
        'user_id': t.userId,
        'title': t.title,
        'icon': t.icon,
        'repeat_days': t.repeatDays,
        'created_at': t.createdAt.toIso8601String(),
        'updated_at': t.updatedAt.toIso8601String(),
      };

  ScheduleBlock _blockFromRow(Map<String, dynamic> r, String userId) =>
      ScheduleBlock(
        id: r['id'] as String,
        userId: r['user_id'] as String? ?? userId,
        templateId: r['template_id'] as String,
        title: r['title'] as String? ?? '',
        startTime: r['start_time'] as String? ?? '00:00',
        endTime: r['end_time'] as String? ?? '00:00',
        color: r['color'] as String? ?? '#9A9A9E',
        icon: r['icon'] as String? ?? 'other',
        createdAt: _parseDate(r['created_at']),
        updatedAt: _parseDate(r['updated_at']),
      );

  Map<String, dynamic> _blockToRow(ScheduleBlock b) => {
        'id': b.id,
        'user_id': b.userId,
        'template_id': b.templateId,
        'title': b.title,
        'start_time': b.startTime,
        'end_time': b.endTime,
        'color': b.color,
        'icon': b.icon,
        'created_at': b.createdAt.toIso8601String(),
        'updated_at': b.updatedAt.toIso8601String(),
      };

  DateTime _parseDate(dynamic v) =>
      v is String ? DateTime.parse(v) : DateTime.now();
}