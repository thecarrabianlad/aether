import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

/// A named, reusable daily layout (e.g. "Study Day"). `repeatDays` stores
/// the weekdays it auto-applies to as a comma-separated list of indices
/// (0 = Monday ... 6 = Sunday), same comma-separated-string convention
/// Courses uses for `scheduleDays`.
@DataClassName('ScheduleTemplate')
class ScheduleTemplates extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get userId => text()();
  TextColumn get title => text()();

  /// Key into the shared icon lookup (see schedule_options.dart) — Drift
  /// can't store IconData directly.
  TextColumn get icon => text()();

  /// Comma-separated weekday indices, e.g. '0,1,2' for Mon–Wed. Empty
  /// string means the template doesn't auto-apply to any day.
  TextColumn get repeatDays => text().withDefault(const Constant(''))();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}