import 'package:drift/drift.dart';

@DataClassName('SyncQueueEntry')
class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entityType => text()(); // e.g., 'habit', 'course'
  TextColumn get entityId => text()(); // ID of the entity in its table
  TextColumn get operation => text()(); // e.g., 'insert', 'update', 'delete'
  TextColumn get payload => text().nullable()(); // JSON string of the data
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();
  TextColumn get lastError => text().nullable()();

}