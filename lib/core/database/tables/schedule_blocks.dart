import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:aether/core/database/tables/schedule_templates.dart';

/// One row per timeline entry within a template (e.g. "Morning Run",
/// 5:15–6:00). Times are stored as 'HH:mm' 24-hour text, same convention
/// Courses uses for scheduleStart/scheduleEnd, so a day's blocks can be
/// sorted chronologically with a plain text ORDER BY.
@DataClassName('ScheduleBlock')
class ScheduleBlocks extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get userId => text()();
  TextColumn get templateId => text().references(ScheduleTemplates, #id)();
  TextColumn get title => text()();

  /// 'HH:mm', 24-hour.
  TextColumn get startTime => text()();
  TextColumn get endTime => text()();

  /// Hex string, e.g. '#FF3B30'.
  TextColumn get color => text()();

  /// Key into the shared icon lookup (see schedule_options.dart).
  TextColumn get icon => text()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}