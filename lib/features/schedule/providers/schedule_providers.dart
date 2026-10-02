import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aether/core/database/database.dart';
import 'package:aether/features/schedule/services/schedule_service.dart';
// import 'package:aether/features/academics/providers/academics_providers.dart'
import 'package:aether/core/providers.dart' show databaseProvider;
    // show databaseProvider;

final scheduleServiceProvider = Provider<ScheduleService>((ref) {
  final db = ref.watch(databaseProvider);
  return ScheduleService(db);
});

/// All of the current user's templates — pure, no side effects. Sync is
/// triggered from the widget lifecycle (initState), same pattern as
/// AcademicsService / TaskService.
final templatesProvider = StreamProvider<List<ScheduleTemplate>>((ref) {
  final service = ref.watch(scheduleServiceProvider);
  return service.watchTemplates();
});

/// Blocks belonging to a single template, in chronological order.
final scheduleBlocksProvider =
    StreamProvider.family<List<ScheduleBlock>, String>((ref, templateId) {
  final service = ref.watch(scheduleServiceProvider);
  return service.watchBlocks(templateId);
});

/// Manual template override for the day being viewed. `null` means "auto":
/// the screen resolves whichever template's repeatDays includes today's
/// weekday. Reset to `null` whenever the viewed date changes so the
/// weekday-matched template loads automatically again.
final selectedTemplateProvider = StateProvider<String?>((ref) => null);