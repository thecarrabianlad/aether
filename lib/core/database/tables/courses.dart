import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

@DataClassName('Course')
class Courses extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get userId => text()();
  TextColumn get name => text()();
  TextColumn get code => text().nullable()();
  TextColumn get professor => text().nullable()();
  TextColumn get color => text().withDefault(const Constant('#8B5CF6'))();
  TextColumn get icon => text().nullable()();
  TextColumn get semester => text().nullable()();
  TextColumn get location => text().nullable()();
  IntColumn get credits => integer().nullable()();
  // Drift doesn't have a native array type for strings, so we'll store it as a comma-separated string.
  TextColumn get scheduleDays => text().nullable()();
  TextColumn get scheduleStart => text().nullable()(); // Storing time as text "HH:mm"
  TextColumn get scheduleEnd => text().nullable()();   // Storing time as text "HH:mm"
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
