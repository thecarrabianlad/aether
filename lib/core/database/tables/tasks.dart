import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

/// One row per task, per day. No CSV blobs — every task is its own record
/// so a day can hold an unlimited number of tasks and can be filtered
/// efficiently by user, date, category, priority, or status.
class Tasks extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get userId => text()();

  /// Stored as 'YYYY-MM-DD' so a day's tasks can be queried directly
  /// without datetime range comparisons.
  TextColumn get date => text()();

  TextColumn get title => text()();

  /// 'High' | 'Medium' | 'Low'
  TextColumn get priority => text().withDefault(const Constant('Low'))();

  /// 'Study' | 'Personal' | 'Other'
  TextColumn get category => text().withDefault(const Constant('Other'))();

  /// 'Pending' | 'InProgress' | 'Completed'
  TextColumn get status => text().withDefault(const Constant('Pending'))();

  IntColumn get durationMinutes => integer().nullable()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}