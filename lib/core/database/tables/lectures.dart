import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:aether/core/database/tables/courses.dart';

@DataClassName('Lecture')
class Lectures extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get courseId => text().references(Courses, #id)();
  TextColumn get userId => text()();
  TextColumn get title => text()();
  TextColumn get chapter => text().nullable()();
  TextColumn get tag => text().nullable()();
  DateTimeColumn get scheduledAt => dateTime().nullable()();
  IntColumn get durationMinutes => integer().withDefault(const Constant(90))();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
